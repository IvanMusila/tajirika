import React, { useState, useEffect } from "react";
import Dashboard from "./components/Dashboard";
import GoalForm from "./components/GoalForm";
import GoalsList from "./components/GoalsList";
import "./assets/index.css"; 

const endpoint = "http://127.0.0.1:5000/savingsGoals";


function App() {
  const [goals, setGoals] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ goalName: "", targetAmount: "", deadline: "" });

  useEffect(() => {
    fetchGoals();
  }, []);

  const fetchGoals = async () => {
    const res = await fetch(endpoint);
    const data = await res.json();
    setGoals(data);
  };

  const addGoal = async (e) => {
    e.preventDefault();
    const newGoal = { goalName: formData.goalName, targetAmount: Number(formData.targetAmount), savedAmount: 0, deadline: formData.deadline };
    await fetch(endpoint, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(newGoal) });
    setShowForm(false);
    setFormData({ goalName: "", targetAmount: "", deadline: "" });
    fetchGoals();
  };

  const updateSavings = async (id, deposit) => {
    const res = await fetch(`${endpoint}/${id}`);
    const goal = await res.json();
    goal.savedAmount += deposit;
    await fetch(`${endpoint}/${id}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ savedAmount: goal.savedAmount }) });
    fetchGoals();
  };

  const deleteGoal = async (id) => {
    await fetch(`${endpoint}/${id}`, { method: "DELETE" });
    fetchGoals();
  };

  const totalSavings = goals.reduce((sum, g) => sum + g.savedAmount, 0);
  const goalsAchieved = goals.filter((g) => g.savedAmount >= g.targetAmount).length;
  const goalsPending = goals.length - goalsAchieved;

  return (
    <div className="max-w-5xl mx-auto p-6">
      <h1 className="text-3xl font-bold text-center mb-6">💰 Savings Goals</h1>

      <Dashboard totalSavings={totalSavings} goalsAchieved={goalsAchieved} goalsPending={goalsPending} />

      <button
        onClick={() => setShowForm(!showForm)}
        className="bg-blue-600 text-white px-4 py-2 rounded mb-6 hover:bg-blue-700"
      >
        {showForm ? "Close Form" : "Add Goal"}
      </button>

      {showForm && <GoalForm formData={formData} setFormData={setFormData} addGoal={addGoal} />}

      <GoalsList goals={goals} updateSavings={updateSavings} deleteGoal={deleteGoal} />
    </div>
  );
}

export default App;
