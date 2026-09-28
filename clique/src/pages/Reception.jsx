
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
