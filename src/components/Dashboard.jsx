import React from "react";

function Dashboard({ totalSavings, goalsAchieved, goalsPending }) {
  return (
    <div className="bg-white shadow-md rounded-lg p-4 flex justify-between mb-6">
      <p className="font-semibold text-gray-700">
        Total Savings: <span className="text-green-600">Ksh {totalSavings}</span>
      </p>
      <p className="font-semibold text-gray-700">Goals Achieved: {goalsAchieved}</p>
      <p className="font-semibold text-gray-700">Goals Pending: {goalsPending}</p>
    </div>
  );
}

export default Dashboard;
