import React, { useState, useEffect } from "react";

const endpoint = "https://savings-goals-api.onrender.com/savingsGoals";

function App() {
  const [goals, setGoals] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    goalName: "",
    targetAmount: "",
    deadline: "",
  });

  // Fetch goals when app loads
  useEffect(() => {
    fetchGoals();
  }, []);

  // Fetch from API
  const fetchGoals = async () => {
    const res = await fetch(endpoint);
    const data = await res.json();
    setGoals(data);
  };

  // Add new goal
  const addGoal = async (e) => {
    e.preventDefault();
    const newGoal = {
      goalName: formData.goalName,
      targetAmount: Number(formData.targetAmount),
      savedAmount: 0,
      deadline: formData.deadline,
    };

    await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(newGoal),
    });

    setShowForm(false);
    setFormData({ goalName: "", targetAmount: "", deadline: "" });
    fetchGoals();
  };

  // Update savings
  const updateSavings = async (id, deposit) => {
    const res = await fetch(`${endpoint}/${id}`);
    const goal = await res.json();
    goal.savedAmount += deposit;

    await fetch(`${endpoint}/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ savedAmount: goal.savedAmount }),
    });

    fetchGoals();
  };

  // Delete goal
  const deleteGoal = async (id) => {
    await fetch(`${endpoint}/${id}`, { method: "DELETE" });
    fetchGoals();
  };

  // Dashboard calculations
  const totalSavings = goals.reduce((sum, g) => sum + g.savedAmount, 0);
  const goalsAchieved = goals.filter((g) => g.savedAmount >= g.targetAmount).length;
  const goalsPending = goals.length - goalsAchieved;

  return (
    <div className="app">
      <h1>Savings Goals</h1>

      {/* Dashboard */}
      <div className="dashboard">
        <p>Total Savings: Ksh {totalSavings}</p>
        <p>Goals Achieved: {goalsAchieved}</p>
        <p>Goals Pending: {goalsPending}</p>
      </div>

      {/* Toggle Form */}
      <button onClick={() => setShowForm(!showForm)}>
        {showForm ? "Close Form" : "Add Goal"}
      </button>

      {showForm && (
        <form onSubmit={addGoal} className="goal-form">
          <input
            type="text"
            placeholder="Goal Name"
            value={formData.goalName}
            onChange={(e) => setFormData({ ...formData, goalName: e.target.value })}
            required
          />
          <input
            type="number"
            placeholder="Target Amount"
            value={formData.targetAmount}
            onChange={(e) =>
              setFormData({ ...formData, targetAmount: e.target.value })
            }
            required
          />
          <input
            type="date"
            value={formData.deadline}
            onChange={(e) => setFormData({ ...formData, deadline: e.target.value })}
            required
          />
          <button type="submit">Add Goal</button>
        </form>
      )}

      {/* Goals List */}
      <div className="goals-container">
        {goals.map((goal) => {
          const progress = (goal.savedAmount / goal.targetAmount) * 100;
          const radius = 40;
          const circumference = 2 * Math.PI * radius;
          const offset = circumference - (progress / 100) * circumference;

          return (
            <div key={goal.id} className="goal">
              <h3>{goal.goalName}</h3>
              <svg width="100" height="100" viewBox="0 0 100 100">
                <circle
                  cx="50"
                  cy="50"
                  r="40"
                  strokeWidth="10"
                  stroke="#e0e0e0"
                  fill="transparent"
                />
                <circle
                  cx="50"
                  cy="50"
                  r="40"
                  strokeWidth="10"
                  stroke="#4caf50"
                  fill="transparent"
                  strokeDasharray={circumference}
                  strokeDashoffset={offset}
                  transform="rotate(-90 50 50)"
                />
                <text x="50" y="55" textAnchor="middle" fontSize="12">
                  {progress.toFixed(1)}%
                </text>
              </svg>
              <p>
                Target: Ksh {goal.targetAmount} <br />
                Saved: Ksh {goal.savedAmount}
              </p>

              {/* Deposit */}
              <input
                type="number"
                placeholder="Deposit"
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    updateSavings(goal.id, Number(e.target.value));
                    e.target.value = "";
                  }
                }}
              />
              <button onClick={() => deleteGoal(goal.id)}>Delete</button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default App;
