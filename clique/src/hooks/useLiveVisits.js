
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
