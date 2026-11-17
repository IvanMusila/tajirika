from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import RegisterRequest, RegisterResponse

router = APIRouter()


@router.post("/register", response_model=RegisterResponse)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    """
    Called once when the app is first installed.
    If the device_token already exists, returns the existing user.
    """
    user = db.query(User).filter(User.device_token == req.device_token).first()
    if not user:
        user = User(device_token=req.device_token)
        db.add(user)
        db.commit()
        db.refresh(user)
    return RegisterResponse(
        user_id=user.id,
        device_token=user.device_token,
        created_at=user.created_at,
    )


def get_user_or_404(device_token: str, db: Session) -> User:
    """Helper used by all other routers."""
    user = db.query(User).filter(User.device_token == device_token).first()
    if not user:
        raise HTTPException(status_code=404, detail="Device not registered. Call /users/register first.")
    return user