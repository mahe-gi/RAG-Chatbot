"""Database connection using SQLAlchemy"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from datetime import datetime
from dotenv import load_dotenv
import os

# Load environment variables first
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "").replace("postgresql://", "postgresql+asyncpg://")

# Create async engine
engine = create_async_engine(DATABASE_URL, echo=False) if DATABASE_URL else None
async_session_maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False) if engine else None

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(String, primary_key=True)
    email = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    name = Column(String, nullable=True)
    is_active = Column("isActive", Boolean, default=True)
    created_at = Column("createdAt", DateTime, default=datetime.utcnow)
    updated_at = Column("updatedAt", DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Session(Base):
    __tablename__ = "sessions"
    
    id = Column(String, primary_key=True)
    user_id = Column("userId", String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token = Column(String, unique=True, nullable=False)
    expires_at = Column("expiresAt", DateTime, nullable=False)
    created_at = Column("createdAt", DateTime, default=datetime.utcnow)

async def init_db():
    """Initialize database tables"""
    if engine:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print("✓ Database tables created")

async def get_db():
    """Get database session"""
    if not async_session_maker:
        yield None
        return
    
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
