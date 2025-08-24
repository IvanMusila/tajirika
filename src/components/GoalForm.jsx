import React from "react";

function GoalForm({ formData, setFormData, addGoal }) {
  return (
    <form onSubmit={addGoal} className="bg-white shadow-md rounded-lg p-6 mb-6">
      <input
        type="text"
        placeholder="Goal Name"
        value={formData.goalName}
        onChange={(e) => setFormData({ ...formData, goalName: e.target.value })}
        className="w-full border rounded px-3 py-2 mb-3"
        required
      />
      <input
        type="number"
        placeholder="Target Amount"
        value={formData.targetAmount}
        onChange={(e) => setFormData({ ...formData, targetAmount: e.target.value })}
        className="w-full border rounded px-3 py-2 mb-3"
        required
      />
      <input
        type="date"
        value={formData.deadline}
        onChange={(e) => setFormData({ ...formData, deadline: e.target.value })}
        className="w-full border rounded px-3 py-2 mb-3"
        required
      />
      <button
        type="submit"
        className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
      >
        Add Goal
      </button>
    </form>
  );
}

export default GoalForm;
