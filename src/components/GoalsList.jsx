import React from "react";
import GoalCard from "./GoalCard";

function GoalsList({ goals, updateSavings, deleteGoal }) {
  return (
    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      {goals.map((goal) => (
        <GoalCard
          key={goal.id}
          goal={goal}
          updateSavings={updateSavings}
          deleteGoal={deleteGoal}
        />
      ))}
    </div>
  );
}

export default GoalsList;
