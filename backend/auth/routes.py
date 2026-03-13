"""Authentication routes"""
from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from .auth import (
    Token,
    UserCreate,
    UserLogin,
    UserResponse,
    create_user,
    authenticate_user,
    create_access_token,
    get_current_user,
    ACCESS_TOKEN_EXPIRE_MINUTES
)

router = APIRouter(prefix="/auth", tags=["authentication"])

@router.post("/register", response_model=UserResponse)
async def register(user_data: UserCreate):
    """Register a new user"""
    user = await create_user(user_data)
    return UserResponse(
        id=user.id,
        email=user.email,
        name=user.name,
        isActive=user.isActive,
        createdAt=user.createdAt
    )

@router.post("/login", response_model=Token)
async def login(user_data: UserLogin):
    """Login and get access token"""
    user = await authenticate_user(user_data.email, user_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return Token(access_token=access_token, token_type="bearer")

@router.get("/me", response_model=UserResponse)
async def get_me(current_user = Depends(get_current_user)):
    """Get current user info"""
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        name=current_user.name,
        isActive=current_user.isActive,
        createdAt=current_user.createdAt
    )
