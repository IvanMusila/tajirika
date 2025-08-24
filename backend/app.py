from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os

app = Flask(__name__)
CORS(app)  # allow frontend to call backend

# Database config (SQLite)
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{os.path.join(BASE_DIR, 'savings.db')}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

# Model
class SavingGoal(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    goalName = db.Column(db.String(100), nullable=False)
    targetAmount = db.Column(db.Float, nullable=False)
    savedAmount = db.Column(db.Float, default=0)
    deadline = db.Column(db.String(20), nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "goalName": self.goalName,
            "targetAmount": self.targetAmount,
            "savedAmount": self.savedAmount,
            "deadline": self.deadline,
        }

# Routes
@app.route("/savingsGoals", methods=["GET"])
def get_goals():
    goals = SavingGoal.query.all()
    return jsonify([g.to_dict() for g in goals])

@app.route("/savingsGoals", methods=["POST"])
def add_goal():
    data = request.json
    goal = SavingGoal(
        goalName=data["goalName"],
        targetAmount=data["targetAmount"],
        savedAmount=data.get("savedAmount", 0),
        deadline=data["deadline"],
    )
    db.session.add(goal)
    db.session.commit()
    return jsonify(goal.to_dict()), 201

@app.route("/savingsGoals/<int:id>", methods=["GET"])
def get_goal(id):
    goal = SavingGoal.query.get_or_404(id)
    return jsonify(goal.to_dict())

@app.route("/savingsGoals/<int:id>", methods=["PATCH"])
def update_goal(id):
    goal = SavingGoal.query.get_or_404(id)
    data = request.json
    if "savedAmount" in data:
        goal.savedAmount = data["savedAmount"]
    db.session.commit()
    return jsonify(goal.to_dict())

@app.route("/savingsGoals/<int:id>", methods=["DELETE"])
def delete_goal(id):
    goal = SavingGoal.query.get_or_404(id)
    db.session.delete(goal)
    db.session.commit()
    return jsonify({"message": "Goal deleted"})

if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(debug=True)
