# CareQueue hospital update - run from the project folder (the one with package.json)

@'
import { supabase } from "../supabaseClient";

export async function getDoctors() {
  const { data, error } = await supabase.from("doctors").select("*").order("id");
  if (error) throw error;
  return data;
}

export async function getHospitals() {
  const { data, error } = await supabase.from("hospitals").select("*").order("id");
  if (error) throw error;
  return data;
}
'@ | Set-Content src\api\doctors.js -Encoding utf8

@'
import { useEffect, useState, useCallback } from "react";
import { supabase } from "../supabaseClient";
import { getTodayVisits, getLatestNotice } from "../api/visits";
import { getDoctors, getHospitals } from "../api/doctors";

// A4: loads data, then re-loads whenever Supabase Realtime reports a change
export function useLiveVisits() {
  const [visits, setVisits] = useState([]);
  const [doctors, setDoctors] = useState([]);
  const [hospitals, setHospitals] = useState([]);
  const [notice, setNotice] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      const [v, n] = await Promise.all([getTodayVisits(), getLatestNotice()]);
      setVisits(v);
      setNotice(n);
      setError("");
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    getDoctors().then(setDoctors).catch((e) => setError(e.message));
    getHospitals().then(setHospitals).catch((e) => setError(e.message));
    load();
    const channel = supabase
      .channel("live-" + Math.random().toString(36).slice(2))
      .on("postgres_changes", { event: "*", schema: "public", table: "visits" }, load)
      .on("postgres_changes", { event: "*", schema: "public", table: "notices" }, load)
      .subscribe();
    return () => supabase.removeChannel(channel);
  }, [load]);

  return { visits, doctors, hospitals, notice, error, loading };
}
'@ | Set-Content src\hooks\useLiveVisits.js -Encoding utf8

@'
import { useState } from "react";
import { registerVisit, setStatus, byQueueOrder } from "../api/visits";
import { OPEN, LABEL, tokenLabel, avgMinutes, estWait, waitingCount, aheadOf } from "../lib/queue";

const ICON = {
  Cardiology: "\u2764\uFE0F", Pediatrics: "\uD83E\uDDD2", "General Medicine": "\uD83E\uDE7A",
  Orthopedics: "\uD83E\uDDB4", Neurology: "\uD83E\uDDE0", Dermatology: "\uD83E\uDDF4", Gynecology: "\uD83C\uDF38",
};
const load = (k, d) => { try { return JSON.parse(localStorage.getItem(k)) ?? d; } catch { return d; } };
const save = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch { /* ignore */ } };
const STEPS = ["Joined", "Waiting", "With doctor", "Completed"];

export default function Patient({ visits, doctors, hospitals, notice, go }) {
  const [tab, setTab] = useState("home");
  const [spec, setSpec] = useState(null);
  const [hosp, setHosp] = useState(null);
  const [doc, setDoc] = useState(null);
  const [profile, setProfile] = useState(() => load("cq_profile", { name: "", phone: "" }));
  const [ticket, setTicket] = useState(() => load("cq_ticket", null));
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const hdocs = hosp ? doctors.filter((d) => d.hospital_id === hosp.id) : [];
  const specialties = [...new Set(hdocs.map((d) => d.specialty).filter(Boolean))];
  const hospOf = (d) => hospitals.find((h) => h.id === d?.hospital_id);
  const hospDocs = (h) => doctors.filter((d) => d.hospital_id === h.id);
  const hospWaiting = (h) => visits.filter((v) => v.status === "waiting" && hospDocs(h).some((d) => d.id === v.doctor_id)).length;
  const mine = ticket && visits.find((v) => v.doctor_id === ticket.doctorId && v.token_no === ticket.token);
  const mineDoc = doctors.find((d) => d.id === ticket?.doctorId);
  const ahead = mine ? aheadOf(mine, visits) : 0;
  const avg = mineDoc ? avgMinutes(mineDoc, visits) : 10;
  const active = mine && OPEN.includes(mine.status);

  async function join() {
    if (!profile.name.trim()) return setErr("Enter your name.");
    setBusy(true);
    try {
      const v = await registerVisit({ name: profile.name.trim(), phone: profile.phone, doctorId: doc.id, priority: false });
      const t = { doctorId: doc.id, token: v.token_no };
      save("cq_profile", profile); save("cq_ticket", t);
      setTicket(t); setDoc(null); setSpec(null); setHosp(null); setErr(""); setTab("live");
    } catch (e) { setErr(e.message); }
    setBusy(false);
  }
  const leave = () => { save("cq_ticket", null); setTicket(null); setTab("home"); };
  const change = (s) => setStatus(mine.id, s).catch((e) => setErr(e.message));

  const step = !mine ? 0 : mine.status === "done" ? 3 : ["called", "in_consultation"].includes(mine.status) ? 2 : 1;

  const alerts = [];
  if (mine) {
    alerts.push(`You joined the queue as ${tokenLabel(mineDoc, mine)}.`);
    if (mine.status === "waiting") alerts.push(`${ahead} ${ahead === 1 ? "person is" : "people are"} ahead of you. Estimated wait: about ${ahead * avg} min.`);
    if (mine.status === "waiting" && ahead <= 2) alerts.push("Your turn is approaching. Please stay nearby.");
    if (mine.status === "called") alerts.push(`We're calling you now. Please go to ${mineDoc?.room}.`);
    if (mine.status === "done") alerts.push("Your consultation is complete.");
  }
  if (notice) alerts.push(notice.message);

  return (
    <div className="phone">
      <header className="p-head">
        <div><b className="brand sm">CareQueue</b><p className="muted">Hello{profile.name ? `, ${profile.name}` : ""}</p></div>
        <button className="link" onClick={() => go("")}>Switch view</button>
      </header>

      <main className="p-body">
        {err && <p className="error">{err}</p>}

        {active && tab === "home" && !doc && <button className="banner go wide" onClick={() => setTab("live")}>You're in a queue: {tokenLabel(mineDoc, mine)}. View live status</button>}

        {tab === "home" && !hosp && (
          <>
            <h2>Choose a hospital</h2>
            {hospitals.map((h) => (
              <button key={h.id} className="card hosp" onClick={() => setHosp(h)}>
                <b>{h.name}</b>
                <span className="muted">{h.area} | {hospDocs(h).length} doctors | {hospWaiting(h)} waiting now</span>
              </button>
            ))}
          </>
        )}

        {tab === "home" && hosp && !spec && (
          <>
            <button className="link" onClick={() => setHosp(null)}>Change hospital</button>
            <h2>{hosp.name}</h2>
            <p className="muted">Find a specialist</p>
            <div className="spec-grid">
              {specialties.map((s) => (
                <button key={s} className="spec" onClick={() => setSpec(s)}>
                  <span className="ico">{ICON[s] || "\uD83E\uDE7A"}</span>{s}
                </button>
              ))}
            </div>
          </>
        )}

        {tab === "home" && spec && !doc && (
          <>
            <button className="link" onClick={() => setSpec(null)}>Back</button>
            <h2>{spec} doctors</h2>
            {hdocs.filter((d) => d.specialty === spec).map((d) => (
              <div key={d.id} className="card doc">
                <div><b>{d.name}</b><p className="muted">{d.specialty} | {d.room}</p>
                  <p>{waitingCount(d, visits)} waiting | about {estWait(d, visits)} min</p></div>
                <button className="primary" onClick={() => setDoc(d)}>Join queue</button>
              </div>
            ))}
          </>
        )}

        {tab === "home" && doc && (
          <>
            <button className="link" onClick={() => setDoc(null)}>Back</button>
            <h2>Confirm your details</h2>
            <div className="card">
              <p><b>{doc.name}</b></p>
              <p className="muted">{hosp?.name} | {doc.specialty} | {doc.room}</p>
              <p>About {estWait(doc, visits)} min wait right now</p>
            </div>
            <div className="stack">
              <label>Your name<input value={profile.name} onChange={(e) => setProfile({ ...profile, name: e.target.value })} /></label>
              <label>Phone (optional)<input inputMode="tel" value={profile.phone} onChange={(e) => setProfile({ ...profile, phone: e.target.value })} /></label>
              <button className="primary" disabled={busy} onClick={join}>Join live queue</button>
            </div>
          </>
        )}

        {tab === "live" && !mine && (
          <div className="empty-state">
            <h2>You're not in a queue</h2>
            <p className="muted">Choose a specialist and join from home.</p>
            <button className="primary" onClick={() => setTab("home")}>Find a specialist</button>
          </div>
        )}

        {tab === "live" && mine && (
          <>
            <h2>Live queue</h2>
            <div className="card center">
              <p className="muted">{hospOf(mineDoc)?.name} | {mineDoc?.name} | {mineDoc?.room}</p>
              <p className="muted">Your token</p>
              <div className="token">{tokenLabel(mineDoc, mine)}</div>
              {mine.status === "waiting" && (<><p><b>{ahead}</b> {ahead === 1 ? "person" : "people"} ahead</p><p className="wait">About {ahead * avg} min</p></>)}
              {ahead === 0 && mine.status === "waiting" && <p className="banner go">You're next. Please stay close.</p>}
              {mine.status === "called" && <p className="banner go">Your turn. Please go to {mineDoc?.room}.</p>}
              {mine.status === "in_consultation" && <p className="banner go">You are with the doctor now.</p>}
              {mine.status === "stepped_out" && <p className="banner warn">You stepped out. Tap "I'm back" to be called again.</p>}
              {["skipped", "cancelled"].includes(mine.status) && <p className="banner warn">This token is {LABEL[mine.status].toLowerCase()}.</p>}
              <ol className="steps">
                {STEPS.map((s, i) => <li key={s} className={i <= step ? "on" : ""}>{s}</li>)}
              </ol>
              <div className="row">
                {mine.status === "waiting" && <button onClick={() => change("stepped_out")}>I'm stepping out</button>}
                {mine.status === "stepped_out" && <button className="primary" onClick={() => change("waiting")}>I'm back</button>}
                {["waiting", "stepped_out"].includes(mine.status) && <button className="ghost" onClick={() => change("cancelled")}>Cancel token</button>}
                {!active && <button className="primary" onClick={leave}>Done</button>}
              </div>
            </div>
            <h3>Queue for {mineDoc?.name}</h3>
            <ul className="mini">
              {visits.filter((v) => v.doctor_id === mine.doctor_id && OPEN.includes(v.status)).sort(byQueueOrder).map((v) => (
                <li key={v.id} className={v.id === mine.id ? "me" : ""}>
                  <b>{tokenLabel(mineDoc, v)}</b><span>{v.id === mine.id ? "You" : LABEL[v.status]}</span>
                </li>
              ))}
            </ul>
          </>
        )}

        {tab === "alerts" && (
          <>
            <h2>Live updates</h2>
            {alerts.length === 0 && <p className="muted">No updates yet. Join a queue to get live alerts.</p>}
            {alerts.map((a, i) => <p key={i} className="card">{a}</p>)}
          </>
        )}
      </main>

      <nav className="p-nav">
        {[["home", "Home"], ["live", "Live queue"], ["alerts", "Alerts"]].map(([k, l]) => (
          <button key={k} className={tab === k ? "on" : ""} onClick={() => { setTab(k); if (k === "home") { setSpec(null); setDoc(null); setHosp(null); } }}>{l}</button>
        ))}
      </nav>
    </div>
  );
}
'@ | Set-Content src\pages\Patient.jsx -Encoding utf8

@'
import { useState } from "react";
import { registerVisit, callNext, setStatus, byQueueOrder } from "../api/visits";
import { OPEN, LABEL, tokenLabel, avgMinutes, estWait, waitingCount } from "../lib/queue";

export default function Reception({ visits, doctors, hospitals, go }) {
  const [sel, setSel] = useState(null);
  const [hid, setHid] = useState(() => { try { return Number(localStorage.getItem("cq_hosp")) || null; } catch { return null; } });
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [priority, setPriority] = useState(false);
  const [reason, setReason] = useState("");
  const [msg, setMsg] = useState("");

  const hosp = hospitals.find((h) => h.id === hid) || hospitals[0];
  const hdocs = doctors.filter((d) => d.hospital_id === hosp?.id);
  const hv = visits.filter((v) => hdocs.some((d) => d.id === v.doctor_id));
  const doc = hdocs.find((d) => d.id === sel) || hdocs[0];
  const count = (f) => hv.filter(f).length;
  const stats = [
    ["Total today", hv.length],
    ["Waiting", count((v) => v.status === "waiting")],
    ["With doctor", count((v) => ["called", "in_consultation"].includes(v.status))],
    ["Completed", count((v) => v.status === "done")],
  ];
  const busy = hdocs.filter((d) => estWait(d, visits) >= 40);
  const queue = doc ? visits.filter((v) => v.doctor_id === doc.id && OPEN.includes(v.status)).sort(byQueueOrder) : [];

  const run = async (fn, ok = "") => { try { await fn(); setMsg(ok); } catch (e) { setMsg(e.message); } };
  const add = (e) => {
    e.preventDefault();
    if (!name.trim()) return setMsg("Enter the patient's name.");
    run(async () => {
      const v = await registerVisit({ name: name.trim(), phone, doctorId: doc.id, priority, reason });
      setMsg(`Token ${tokenLabel(doc, v)} issued to ${v.patient_name}`);
      setName(""); setPhone(""); setPriority(false); setReason("");
    });
  };

  return (
    <div className="desk">
      <header className="d-head">
        <span className="hsel">
          <b className="brand sm">CareQueue</b>
          <select value={hosp?.id || ""} onChange={(e) => { const v = Number(e.target.value); setHid(v); setSel(null); try { localStorage.setItem("cq_hosp", v); } catch { /* ignore */ } }}>
            {hospitals.map((h) => <option key={h.id} value={h.id}>{h.name}</option>)}
          </select>
        </span>
        <button className="link light" onClick={() => go("")}>Switch view</button>
      </header>
      <main className="d-body">
        <div className="stats">
          {stats.map(([l, n]) => <div key={l} className="stat"><b>{n}</b><span>{l}</span></div>)}
        </div>
        {busy.length > 0 && (
          <div className="banner warn">
            {busy.map((d) => <p key={d.id}>High wait time: {d.name} ({d.specialty}), about {estWait(d, visits)} min</p>)}
          </div>
        )}

        <div className="pills">
          {hdocs.map((d) => (
            <button key={d.id} className={d.id === doc?.id ? "on" : ""} onClick={() => setSel(d.id)}>
              {d.specialty}<small>{waitingCount(d, visits)} waiting</small>
            </button>
          ))}
        </div>

        {doc && (
          <div className="grid">
            <section className="card">
              <h3>Walk-in registration</h3>
              <p className="muted">{doc.name} | {doc.room}</p>
              <form className="stack" onSubmit={add}>
                <label>Patient name<input value={name} onChange={(e) => setName(e.target.value)} /></label>
                <label>Phone (optional)<input inputMode="tel" value={phone} onChange={(e) => setPhone(e.target.value)} /></label>
                <label className="check"><input type="checkbox" checked={priority} onChange={(e) => setPriority(e.target.checked)} />Priority (elderly, child, urgent)</label>
                {priority && <input placeholder="Reason, e.g. elderly" value={reason} onChange={(e) => setReason(e.target.value)} />}
                <button className="primary">Issue token</button>
              </form>
              {msg && <p className="note" role="status">{msg}</p>}
            </section>

            <section className="card">
              <div className="row">
                <h3>Queue ({queue.length}) | avg {avgMinutes(doc, visits)} min</h3>
                <button className="primary" onClick={() => run(async () => { const v = await callNext(doc.id); if (!v?.id) throw new Error("Nobody is waiting."); }, "Next patient called.")}>Call next</button>
              </div>
              {queue.length === 0 && <p className="empty">No one in the queue.</p>}
              <ul className="list">
                {queue.map((v) => (
                  <li key={v.id} className={v.priority ? "prio" : ""}>
                    <span className="tok">{tokenLabel(doc, v)}</span>
                    <span>{v.patient_name}{v.priority && <b className="badge">Priority{v.priority_reason ? `: ${v.priority_reason}` : ""}</b>}</span>
                    <span className={`status s-${v.status}`}>{LABEL[v.status]}</span>
                    <span className="actions">
                      {v.status === "called" && <button onClick={() => run(() => setStatus(v.id, "in_consultation"))}>Start</button>}
                      {["called", "in_consultation"].includes(v.status) && <button onClick={() => run(() => setStatus(v.id, "done"))}>Complete</button>}
                      {["waiting", "called", "stepped_out"].includes(v.status) && <button className="ghost" onClick={() => run(() => setStatus(v.id, "skipped"))}>No-show</button>}
                    </span>
                  </li>
                ))}
              </ul>
            </section>
          </div>
        )}

        <section className="card">
          <h3>All doctors</h3>
          <div className="scroll">
            <table>
              <thead><tr><th>Specialty</th><th>Doctor</th><th>Waiting</th><th>Avg min</th><th>Est. wait</th></tr></thead>
              <tbody>
                {hdocs.map((d) => (
                  <tr key={d.id}><td>{d.specialty}</td><td>{d.name}</td><td>{waitingCount(d, visits)}</td><td>{avgMinutes(d, visits)}</td><td>{estWait(d, visits)} min</td></tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </div>
  );
}
'@ | Set-Content src\pages\Reception.jsx -Encoding utf8

@'
import { useEffect, useRef, useState } from "react";
import { byQueueOrder } from "../api/visits";
import { tokenLabel } from "../lib/queue";

export default function DisplayBoard({ visits, doctors, hospitals, notice, go }) {
  const [voice, setVoice] = useState(false);
  const [hid, setHid] = useState(() => { try { return Number(localStorage.getItem("cq_hosp")) || null; } catch { return null; } });
  const spoken = useRef(new Set());
  const hosp = hospitals.find((h) => h.id === hid) || hospitals[0];
  const hdocs = doctors.filter((d) => d.hospital_id === hosp?.id);

  // C2: announce each newly called token once (only for this hospital)
  useEffect(() => {
    visits.filter((v) => v.status === "called").forEach((v) => {
      const key = v.id + "-" + v.called_at;
      if (spoken.current.has(key)) return;
      spoken.current.add(key);
      const d = doctors.find((x) => x.id === v.doctor_id);
      if (!voice || d?.hospital_id !== hosp?.id) return;
      window.speechSynthesis.speak(new SpeechSynthesisUtterance(`Token ${d?.prefix || ""} ${v.token_no}, please proceed to ${d?.room || "the consultation room"}.`));
    });
  }, [visits, voice, doctors, hosp?.id]);

  return (
    <div className="tv">
      <div className="row">
        <span className="hsel">
          <b className="brand sm light">CareQueue</b>
          <select value={hosp?.id || ""} onChange={(e) => { const v = Number(e.target.value); setHid(v); try { localStorage.setItem("cq_hosp", v); } catch { /* ignore */ } }}>
            {hospitals.map((h) => <option key={h.id} value={h.id}>{h.name}</option>)}
          </select>
        </span>
        <span>
          <button className="tvbtn" onClick={() => setVoice(!voice)}>{voice ? "Voice on" : "Turn voice on"}</button>
          <button className="tvbtn" onClick={() => go("")}>Exit</button>
        </span>
      </div>
      {notice && <p className="tv-notice">{notice.message}</p>}
      <div className="tv-grid">
        {hdocs.map((d) => {
          const q = visits.filter((v) => v.doctor_id === d.id).sort(byQueueOrder);
          const serving = q.find((v) => v.status === "called") || q.find((v) => v.status === "in_consultation");
          const next = q.find((v) => v.status === "waiting");
          return (
            <section key={d.id} className="tv-card">
              <h3>{d.specialty}</h3>
              <p className="tv-room">{d.room}</p>
              <p className="tv-label">Now consulting</p>
              <div className="tv-num">{serving ? tokenLabel(d, serving) : "-"}</div>
              <p className="tv-label">Next patient</p>
              <div className="tv-next">{next ? tokenLabel(d, next) : "-"}</div>
            </section>
          );
        })}
      </div>
      <p className="tv-foot">Please be ready when your token is next. Thank you for your patience.</p>
    </div>
  );
}
'@ | Set-Content src\pages\DisplayBoard.jsx -Encoding utf8

if (-not (Select-String -Path src\App.css -Pattern 'HOSPITAL-STYLES' -Quiet)) {
@'
/* HOSPITAL-STYLES */
.hosp{display:grid;gap:.2rem;width:100%;text-align:left;color:var(--ink);border-color:var(--line);font-weight:400}
.hosp b{font-size:1.1rem;color:var(--blue)}
.hsel{display:flex;align-items:center;gap:.8rem;flex-wrap:wrap}
.hsel select{width:auto;max-width:100%}
'@ | Add-Content src\App.css -Encoding utf8
}
Write-Host "Hospital update installed. Run the SQL, then refresh the browser." -ForegroundColor Green
