
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
