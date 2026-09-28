
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
