#!/bin/bash
set -e

echo "=========================================="
echo "Database Setup - PostgreSQL with Prisma"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Docker is not running${NC}"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

echo -e "${CYAN}Step 1: Starting PostgreSQL container...${NC}"
cd ..
docker-compose up -d postgres

echo ""
echo -e "${CYAN}Step 2: Waiting for PostgreSQL to be ready...${NC}"
sleep 5

# Check if PostgreSQL is ready
for i in {1..30}; do
    if docker exec ragbot_postgres pg_isready -U ragbot > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PostgreSQL is ready${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""
echo -e "${CYAN}Step 3: Setting up Python environment...${NC}"
cd backend
source venv/bin/activate

echo ""
echo -e "${CYAN}Step 4: Installing Prisma dependencies...${NC}"
pip install -q prisma asyncpg bcrypt passlib

echo ""
echo -e "${CYAN}Step 5: Generating Prisma client...${NC}"
prisma generate

echo ""
echo -e "${CYAN}Step 6: Running database migrations...${NC}"
prisma db push

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Database setup complete!${NC}"
echo "=========================================="
echo ""
echo "Database connection:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: ragbot_db"
echo "  User: ragbot"
echo "  Password: ragbot123"
echo ""
echo "Connection string:"
echo "  postgresql://ragbot:ragbot123@localhost:5432/ragbot_db"
echo ""
echo "Manage database:"
echo "  View logs:  docker logs ragbot_postgres"
echo "  Stop:       docker-compose stop postgres"
echo "  Start:      docker-compose start postgres"
echo "  Remove:     docker-compose down -v"
echo ""
