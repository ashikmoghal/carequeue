
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
