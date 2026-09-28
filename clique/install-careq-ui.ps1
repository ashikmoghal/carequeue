# CareQueue UI installer - run from the project folder (the one with package.json)
New-Item -ItemType Directory -Force src\lib, src\pages | Out-Null

@'
import { useEffect, useState } from "react";
import { useLiveVisits } from "./hooks/useLiveVisits";
import Welcome from "./pages/Welcome";
import Patient from "./pages/Patient";
import Reception from "./pages/Reception";
import DisplayBoard from "./pages/DisplayBoard";

const VIEWS = ["patient", "reception", "board"];
const read = () => (VIEWS.includes(location.hash.slice(1)) ? location.hash.slice(1) : "");

export default function App() {
  const [view, setView] = useState(read());
  const live = useLiveVisits();

  useEffect(() => {
    const f = () => setView(read());
    addEventListener("hashchange", f);
    return () => removeEventListener("hashchange", f);
  }, []);

  const go = (v) => { location.hash = v; };
  if (live.loading) return <p className="loading">Loading queue...</p>;

  return (
    <>
      {live.error && <p className="error top-error">{live.error}</p>}
      {!view && <Welcome go={go} />}
      {view === "patient" && <Patient {...live} go={go} />}
      {view === "reception" && <Reception {...live} go={go} />}
      {view === "board" && <DisplayBoard {...live} go={go} />}
    </>
  );
}
'@ | Set-Content src\App.jsx -Encoding utf8

@'
:root { --bg:#f2f6fc; --ink:#0f2447; --blue:#1d5fd8; --navy:#0b2a5b; --line:#d3def0; --muted:#5a6f92;
  --go:#0f7a5a; --go-bg:#dcf4ec; --amber:#a35a00; --amber-bg:#fff0d6; --err:#b42318; }
* { box-sizing:border-box; }
body { margin:0; background:var(--bg); color:var(--ink); font-family:"Atkinson Hyperlegible",system-ui,sans-serif; font-size:17px; line-height:1.45; }
h1,h2,h3 { margin:0 0 .5rem; line-height:1.15; } h2 { font-size:1.35rem; } h3 { font-size:1.05rem; }
p { margin:.25rem 0; }
button { font:inherit; font-weight:700; padding:.55rem 1rem; border-radius:10px; border:2px solid var(--blue); background:#fff; color:var(--blue); cursor:pointer; }
button.primary { background:var(--blue); color:#fff; }
button.ghost { border-color:var(--line); color:var(--muted); }
button.link { border:0; background:none; padding:.2rem 0; color:var(--blue); text-decoration:underline; }
button.light { color:#fff; }
button:disabled { opacity:.5; }
:focus-visible { outline:3px solid #f59e0b; outline-offset:2px; }
input,select { font:inherit; padding:.6rem .7rem; border:2px solid var(--line); border-radius:10px; background:#fff; color:var(--ink); width:100%; }
input[type=checkbox] { width:1.3rem; height:1.3rem; }
label { display:grid; gap:.25rem; font-weight:700; } label.check { display:flex; gap:.5rem; align-items:center; font-weight:400; }
.stack { display:grid; gap:.8rem; } .row { display:flex; justify-content:space-between; align-items:center; gap:.6rem; flex-wrap:wrap; }
.muted { color:var(--muted); } .center { text-align:center; } .empty { color:var(--muted); padding:1rem 0; }
.error { color:var(--err); font-weight:700; } .top-error { margin:0; padding:.5rem 1rem; background:#fde8e6; }
.note { color:var(--go); font-weight:700; } .loading { padding:2rem; }
.card { background:#fff; border:1px solid var(--line); border-radius:14px; padding:1rem; margin:.7rem 0; }
.banner { padding:.7rem 1rem; border-radius:10px; background:#e8effb; font-weight:700; border:0; text-align:left; }
.banner.go { background:var(--go-bg); color:var(--go); } .banner.warn { background:var(--amber-bg); color:var(--amber); }
.banner.wide { width:100%; margin-bottom:.8rem; }
.brand { font-size:2rem; font-weight:700; color:var(--blue); } .brand.sm { font-size:1.2rem; } .brand.light { color:#fff; }

.welcome { max-width:520px; margin:0 auto; padding:2.5rem 1.4rem; }
.welcome h1 { font-size:2.4rem; margin-top:2rem; color:var(--navy); } .lead { font-size:1.1rem; color:var(--muted); }
.choices { display:grid; gap:.7rem; margin-top:1.6rem; } .choices button { padding:.9rem; font-size:1.1rem; }

.phone { max-width:480px; margin:0 auto; min-height:100vh; background:var(--bg); display:flex; flex-direction:column; }
.p-head { display:flex; justify-content:space-between; align-items:center; padding:1rem 1.1rem .4rem; }
.p-body { flex:1; padding:.4rem 1.1rem 5rem; }
.p-nav { position:fixed; bottom:0; left:50%; transform:translateX(-50%); width:100%; max-width:480px; display:grid; grid-template-columns:repeat(3,1fr); background:#fff; border-top:1px solid var(--line); }
.p-nav button { border:0; border-radius:0; padding:.9rem .3rem; color:var(--muted); background:#fff; }
.p-nav button.on { color:var(--blue); box-shadow:inset 0 3px 0 var(--blue); }
.spec-grid { display:grid; grid-template-columns:repeat(2,1fr); gap:.7rem; }
.spec { display:grid; gap:.3rem; justify-items:center; padding:1rem .5rem; border-color:var(--line); color:var(--ink); }
.ico { font-size:1.9rem; }
.doc { display:flex; justify-content:space-between; align-items:center; gap:.7rem; }
.token { font-size:4.2rem; font-weight:700; color:var(--blue); line-height:1.1; }
.wait { font-size:1.3rem; font-weight:700; }
.steps { list-style:none; display:grid; grid-template-columns:repeat(4,1fr); gap:.3rem; padding:0; margin:1rem 0; font-size:.8rem; color:var(--muted); }
.steps li { border-top:5px solid var(--line); padding-top:.3rem; } .steps li.on { border-color:var(--blue); color:var(--ink); font-weight:700; }
.mini { list-style:none; padding:0; margin:0; display:grid; gap:.4rem; }
.mini li { display:flex; justify-content:space-between; background:#fff; border:1px solid var(--line); border-radius:10px; padding:.55rem .8rem; }
.mini li.me { border-color:var(--blue); background:#e8effb; }
.empty-state { text-align:center; padding:2rem 0; display:grid; gap:.6rem; justify-items:center; }

.desk { min-height:100vh; } .d-head { display:flex; justify-content:space-between; align-items:center; background:var(--navy); color:#fff; padding:.8rem 1.2rem; }
.d-head .brand { color:#fff; } .d-body { max-width:1100px; margin:0 auto; padding:1.2rem; }
.stats { display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr)); gap:.8rem; margin-bottom:1rem; }
.stat { background:#fff; border:1px solid var(--line); border-radius:14px; padding:1rem; display:grid; }
.stat b { font-size:2.2rem; color:var(--blue); } .stat span { color:var(--muted); }
.pills { display:flex; gap:.5rem; flex-wrap:wrap; margin:1rem 0; }
.pills button { display:grid; text-align:left; padding:.5rem .9rem; } .pills small { font-weight:400; color:var(--muted); }
.pills button.on { background:var(--blue); color:#fff; } .pills button.on small { color:#dbe7ff; }
.grid { display:grid; gap:1rem; grid-template-columns:1fr; } @media (min-width:850px) { .grid { grid-template-columns:340px 1fr; } }
.list { list-style:none; margin:.8rem 0; padding:0; display:grid; gap:.5rem; }
.list li { display:grid; grid-template-columns:4.5rem 1fr auto; gap:.4rem .8rem; align-items:center; padding:.6rem .7rem; border:1px solid var(--line); border-left:6px solid var(--line); border-radius:10px; }
.list li.prio { border-left-color:#e08a00; } .tok { font-size:1.4rem; font-weight:700; }
.actions { grid-column:1/-1; display:flex; gap:.4rem; flex-wrap:wrap; }
@media (min-width:700px) { .list li { grid-template-columns:4.5rem 1fr 8rem auto; } .actions { grid-column:auto; } }
.badge { margin-left:.5rem; font-size:.8rem; background:var(--amber-bg); color:var(--amber); padding:.1rem .5rem; border-radius:99px; }
.status { font-size:.9rem; font-weight:700; } .s-called,.s-in_consultation { color:var(--go); } .s-stepped_out { color:var(--amber); }
.scroll { overflow-x:auto; } table { width:100%; border-collapse:collapse; } th,td { text-align:left; padding:.5rem .6rem; border-bottom:1px solid var(--line); }

.tv { min-height:100vh; background:var(--navy); color:#fff; padding:1.2rem 1.6rem; }
.tvbtn { margin-left:.5rem; background:transparent; color:#fff; border-color:#5c7bb5; }
.tv-notice { background:var(--amber-bg); color:var(--amber); font-weight:700; padding:.7rem 1rem; border-radius:10px; font-size:1.2rem; }
.tv-grid { display:grid; gap:1rem; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); margin-top:1rem; }
.tv-card { background:#12397a; border-radius:16px; padding:1.2rem; text-align:center; }
.tv-room { color:#a9c2ee; } .tv-label { color:#a9c2ee; margin-top:.8rem; }
.tv-num { font-size:6rem; font-weight:700; line-height:1; } .tv-next { font-size:3rem; font-weight:700; color:#8fd0ff; }
.tv-foot { text-align:center; color:#a9c2ee; margin-top:1.4rem; }
'@ | Set-Content src\App.css -Encoding utf8

@'
import { byQueueOrder } from "../api/visits";

export const OPEN = ["waiting", "called", "in_consultation", "stepped_out"];
export const LABEL = {
  waiting: "Waiting", called: "Called", in_consultation: "With doctor",
  done: "Completed", skipped: "Skipped", stepped_out: "Stepped out", cancelled: "Cancelled",
};
export const tokenLabel = (doc, v) => `${doc?.prefix || "T"}-${v.token_no}`;

// D2 + D3: average from real consultations, ignoring outliers (<1 or >60 min)
export function avgMinutes(doc, visits) {
  const mins = visits
    .filter((v) => v.doctor_id === doc.id && v.status === "done" && v.called_at && v.completed_at)
    .map((v) => (new Date(v.completed_at) - new Date(v.called_at)) / 60000)
    .filter((m) => m >= 1 && m <= 60);
  return mins.length >= 3 ? Math.round(mins.reduce((a, b) => a + b, 0) / mins.length) : doc.avg_consult_minutes || 10;
}
export const waitingCount = (doc, visits) =>
  visits.filter((v) => v.doctor_id === doc.id && v.status === "waiting").length;
export const inProgress = (doc, visits) =>
  visits.filter((v) => v.doctor_id === doc.id && ["called", "in_consultation"].includes(v.status)).length;
export const estWait = (doc, visits) =>
  (waitingCount(doc, visits) + inProgress(doc, visits)) * avgMinutes(doc, visits);

// People ahead of one visit
export function aheadOf(v, visits) {
  const q = visits.filter((x) => x.doctor_id === v.doctor_id);
  return (
    q.filter((x) => x.status === "waiting" && byQueueOrder(x, v) < 0).length +
    q.filter((x) => ["called", "in_consultation"].includes(x.status)).length
  );
}
'@ | Set-Content src\lib\queue.js -Encoding utf8

@'
export default function Welcome({ go }) {
  return (
    <div className="welcome">
      <div className="brand">CareQueue</div>
      <p className="muted">Better queue. Healthier tomorrow.</p>
      <h1>Your health, our priority</h1>
      <p className="lead">Join the clinic queue from home, watch your turn move in real time, and skip the crowded waiting room.</p>
      <div className="choices">
        <button className="primary" onClick={() => go("patient")}>I'm a patient</button>
        <button onClick={() => go("reception")}>Reception dashboard</button>
        <button onClick={() => go("board")}>Waiting-room screen</button>
      </div>
    </div>
  );
}
'@ | Set-Content src\pages\Welcome.jsx -Encoding utf8

@'
import { useState } from "react";
import { registerVisit, setStatus, byQueueOrder } from "../api/visits";
import { OPEN, LABEL, tokenLabel, avgMinutes, estWait, waitingCount, aheadOf } from "../lib/queue";

const ICON = {
  Cardiology: "\u2764\uFE0F", Pediatrics: "\uD83E\uDDD2", "General Medicine": "\uD83E\uDE7A",
  Orthopedics: "\uD83E\uDDB4", Dermatology: "\uD83E\uDDF4", Gynecology: "\uD83C\uDF38",
};
const load = (k, d) => { try { return JSON.parse(localStorage.getItem(k)) ?? d; } catch { return d; } };
const save = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch { /* ignore */ } };
const STEPS = ["Joined", "Waiting", "With doctor", "Completed"];

export default function Patient({ visits, doctors, notice, go }) {
  const [tab, setTab] = useState("home");
  const [spec, setSpec] = useState(null);
  const [doc, setDoc] = useState(null);
  const [profile, setProfile] = useState(() => load("cq_profile", { name: "", phone: "" }));
  const [ticket, setTicket] = useState(() => load("cq_ticket", null));
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const specialties = [...new Set(doctors.map((d) => d.specialty).filter(Boolean))];
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
      setTicket(t); setDoc(null); setSpec(null); setErr(""); setTab("live");
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

        {tab === "home" && !spec && (
          <>
            {active && <button className="banner go wide" onClick={() => setTab("live")}>You're in a queue: {tokenLabel(mineDoc, mine)}. View live status</button>}
            <h2>Find a specialist</h2>
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
            {doctors.filter((d) => d.specialty === spec).map((d) => (
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
              <p className="muted">{doc.specialty} | {doc.room}</p>
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
              <p className="muted">{mineDoc?.name} | {mineDoc?.room}</p>
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
          <button key={k} className={tab === k ? "on" : ""} onClick={() => { setTab(k); if (k === "home") { setSpec(null); setDoc(null); } }}>{l}</button>
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

export default function Reception({ visits, doctors, go }) {
  const [sel, setSel] = useState(null);
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [priority, setPriority] = useState(false);
  const [reason, setReason] = useState("");
  const [msg, setMsg] = useState("");

  const doc = doctors.find((d) => d.id === sel) || doctors[0];
  const count = (f) => visits.filter(f).length;
  const stats = [
    ["Total today", visits.length],
    ["Waiting", count((v) => v.status === "waiting")],
    ["With doctor", count((v) => ["called", "in_consultation"].includes(v.status))],
    ["Completed", count((v) => v.status === "done")],
  ];
  const busy = doctors.filter((d) => estWait(d, visits) >= 40);
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
        <b className="brand sm">CareQueue | Reception</b>
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
          {doctors.map((d) => (
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
                {doctors.map((d) => (
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

export default function DisplayBoard({ visits, doctors, notice, go }) {
  const [voice, setVoice] = useState(false);
  const spoken = useRef(new Set());

  // C2: announce each newly called token once
  useEffect(() => {
    visits.filter((v) => v.status === "called").forEach((v) => {
      const key = v.id + "-" + v.called_at;
      if (spoken.current.has(key)) return;
      spoken.current.add(key);
      if (!voice) return;
      const d = doctors.find((x) => x.id === v.doctor_id);
      window.speechSynthesis.speak(new SpeechSynthesisUtterance(`Token ${d?.prefix || ""} ${v.token_no}, please proceed to ${d?.room || "the consultation room"}.`));
    });
  }, [visits, voice, doctors]);

  return (
    <div className="tv">
      <div className="row">
        <b className="brand sm light">CareQueue</b>
        <span>
          <button className="tvbtn" onClick={() => setVoice(!voice)}>{voice ? "Voice on" : "Turn voice on"}</button>
          <button className="tvbtn" onClick={() => go("")}>Exit</button>
        </span>
      </div>
      {notice && <p className="tv-notice">{notice.message}</p>}
      <div className="tv-grid">
        {doctors.map((d) => {
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

Remove-Item src\pages\StaffPanel.jsx, src\pages\PatientStatus.jsx -ErrorAction SilentlyContinue
Write-Host "CareQueue UI installed. Run the SQL migration, then: npm run dev" -ForegroundColor Green
