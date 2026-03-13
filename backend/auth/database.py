"""Database connection and Prisma client"""
from prisma import Prisma
from contextlib import asynccontextmanager

# Global Prisma client
prisma = Prisma()

async def connect_db():
    """Connect to database"""
    if not prisma.is_connected():
        await prisma.connect()
    print("✓ Database connected")

async def disconnect_db():
    """Disconnect from database"""
    if prisma.is_connected():
        await prisma.disconnect()
    print("✓ Database disconnected")

@asynccontextmanager
async def get_db():
    """Get database session"""
    try:
        yield prisma
    finally:
        pass
