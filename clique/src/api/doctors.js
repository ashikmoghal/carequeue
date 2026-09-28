
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
