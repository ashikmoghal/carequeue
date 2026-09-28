import { useEffect, useState } from "react";
import { useLiveVisits } from "./hooks/useLiveVisits";
import Welcome from "./pages/Welcome";
import Login from "./pages/login";
import Patient from "./pages/Patient";
import Reception from "./pages/Reception";
import DisplayBoard from "./pages/DisplayBoard";

const VIEWS = ["login", "patient", "reception", "board"];
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
      {view === "login" && <Login go={go} />}
      {view === "patient" && <Patient {...live} go={go} />}
      {view === "reception" && <Reception {...live} go={go} />}
      {view === "board" && <DisplayBoard {...live} go={go} />}
    </>
  );
}