import { supabase } from "../supabaseClient";

// Today's date in IST (matches the SQL default)
export const today = () =>
  new Date().toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" });

export async function getTodayVisits() {
  const { data, error } = await supabase
    .from("visits").select("*").eq("visit_date", today());
  if (error) throw error;
  return data;
}

// B1: safe token generation (SQL function)
export async function registerVisit({ name, phone, doctorId, priority, reason }) {
  const { data, error } = await supabase.rpc("register_visit", {
    p_name: name, p_phone: phone || null, p_doctor: doctorId,
    p_priority: priority, p_reason: reason || null,
  });
  if (error) throw error;
  return data;
}

// B4: safe "Call next" (SQL function)
export async function callNext(doctorId) {
  const { data, error } = await supabase.rpc("call_next", { p_doctor: doctorId });
  if (error) throw error;
  return data;
}

// B2 / A7 / A8: change one visit's status
export async function setStatus(id, status) {
  const changes = { status };
  if (status === "called") changes.called_at = new Date().toISOString();
  if (status === "done") changes.completed_at = new Date().toISOString();
  const { error } = await supabase.from("visits").update(changes).eq("id", id);
  if (error) throw error;
}

export async function getLatestNotice() {
  const { data } = await supabase
    .from("notices").select("*").order("created_at", { ascending: false }).limit(1);
  return data?.[0] ?? null;
}

// Queue order: priority first, then arrival time
export const byQueueOrder = (a, b) =>
  Number(b.priority) - Number(a.priority) ||
  new Date(a.created_at) - new Date(b.created_at);
