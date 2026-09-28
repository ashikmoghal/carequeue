import { useState, useEffect } from "react";

export default function Login({ go }) {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");

  // Auto-fill if they already logged in previously
  useEffect(() => {
    try {
      const saved = JSON.parse(localStorage.getItem("cq_profile"));
      if (saved?.name) {
        setName(saved.name);
        setPhone(saved.phone || "");
      }
    } catch { /* ignore */ }
  }, []);

  const handleLogin = (e) => {
    e.preventDefault();
    if (!name.trim()) return;
    
    // Save credentials to local session
    localStorage.setItem("cq_profile", JSON.stringify({ 
      name: name.trim(), 
      phone: phone.trim() 
    }));
    
    // Proceed to hospital selection
    go("patient");
  };

  return (
    <div className="welcome">
      <div className="brand">CareQueue</div>
      <p className="muted">Patient Portal</p>
      <h2>Log in to your account</h2>
      <p className="lead">Access your live queues and hospital records.</p>
      
      <form className="stack" style={{ marginTop: "1.5rem" }} onSubmit={handleLogin}>
        <label>Full Name
          <input 
            required 
            value={name} 
            onChange={(e) => setName(e.target.value)} 
            placeholder="e.g. Rahul Sharma" 
          />
        </label>
        <label>Phone Number
          <input 
            required 
            inputMode="tel" 
            value={phone} 
            onChange={(e) => setPhone(e.target.value)} 
            placeholder="e.g. 9876543210" 
          />
        </label>
        <button className="primary" type="submit">Sign In & Continue</button>
      </form>
      
      <div style={{ marginTop: "1rem", textAlign: "center" }}>
        <button className="link" onClick={() => go("")}>Back to home</button>
      </div>
    </div>
  );
}