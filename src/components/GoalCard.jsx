import React from "react";

function GoalCard({ goal, updateSavings, deleteGoal }) {
  const progress = (goal.savedAmount / goal.targetAmount) * 100;
  const radius = 40;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (progress / 100) * circumference;

  return (
    <div className="bg-white shadow-md rounded-lg p-4 flex flex-col items-center text-center">
      <h3 className="text-lg font-semibold">{goal.goalName}</h3>

      <svg width="100" height="100" viewBox="0 0 100 100">
        <circle cx="50" cy="50" r="40" strokeWidth="10" stroke="#e0e0e0" fill="transparent" />
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

      <p className="text-gray-600 mt-2">
        Target: Ksh {goal.targetAmount} <br />
        Saved: Ksh {goal.savedAmount}
      </p>

      {/* Deposit Input */}
      <input
        type="number"
        placeholder="Deposit"
        className="border rounded px-2 py-1 mt-2 w-3/4"
        onKeyDown={(e) => {
          if (e.key === "Enter") {
            updateSavings(goal.id, Number(e.target.value));
            e.target.value = "";
          }
        }}
      />

      <button
        onClick={() => deleteGoal(goal.id)}
        className="bg-red-500 text-white px-3 py-1 rounded mt-3 hover:bg-red-600"
      >
        Delete
      </button>
    </div>
  );
}

export default GoalCard;
