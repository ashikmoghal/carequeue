
export default function Welcome({ go }) {
  return (
    <div className="welcome">
      <div className="brand">CareQueue</div>
      <p className="muted">Better queue. Healthier tomorrow.</p>
      <h1>Your health, our priority</h1>
      <p className="lead">Join the clinic queue from home, watch your turn move in real time, and skip the crowded waiting room.</p>
      <div className="choices">
        <button className="primary" onClick={() => go("login")}>I'm a patient</button>
        <button onClick={() => go("reception")}>Reception dashboard</button>
        <button onClick={() => go("board")}>Waiting-room screen</button>
      </div>
    </div>
  );
}

