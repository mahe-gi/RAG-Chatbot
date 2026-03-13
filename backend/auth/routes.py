"""Authentication routes"""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from .auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    get_current_user
)
from .database import get_db, User

router = APIRouter(prefix="/auth", tags=["Authentication"])

class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    name: str = None

    @validator('password')
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters long')
        return v

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

from typing import Optional

class UserResponse(BaseModel):
    id: str
    email: str
    name: Optional[str] = None
    is_active: bool

    class Config:
        from_attributes = True

@router.post("/signup", response_model=TokenResponse)
async def signup(request: SignupRequest, db: AsyncSession = Depends(get_db)):
    """Register new user"""
    if db is None:
        raise HTTPException(
            status_code=503,
            detail="Database not configured. Please set DATABASE_URL in .env"
        )
    
    # Check if user exists
    result = await db.execute(select(User).where(User.email == request.email))
    existing_user = result.scalar_one_or_none()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    user = User(
        id=str(uuid.uuid4()),
        email=request.email,
        password=get_password_hash(request.password),
        name=request.name,
        is_active=True
    )
    
    db.add(user)
    await db.commit()
    await db.refresh(user)
    
    # Create access token
    access_token = create_access_token(data={"sub": user.id})
    
    return TokenResponse(access_token=access_token)

@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Login user"""
    if db is None:
        raise HTTPException(
            status_code=503,
            detail="Database not configured. Please set DATABASE_URL in .env"
        )
    
    # Check user in database
    result = await db.execute(select(User).where(User.email == request.email))
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(request.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    # Create access token
    access_token = create_access_token(data={"sub": user.id})
    
    return TokenResponse(access_token=access_token)

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current user info"""
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        name=current_user.name,
        is_active=current_user.is_active
    )
