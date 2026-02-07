#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Ruby Challenge Services...${NC}"

# Start Docker containers
echo -e "${YELLOW}[1/4] Starting Docker (PostgreSQL + RabbitMQ)...${NC}"
docker compose up -d

# Wait for services to be ready
echo -e "${YELLOW}[2/4] Waiting for services to be ready...${NC}"
sleep 5

# Start Order Service (port 3001)
echo -e "${YELLOW}[3/4] Starting Order Service on port 3001...${NC}"
cd services/order_service
bundle exec rails server -p 3001 &
ORDER_PID=$!
cd ../..

# Start Customer Service (port 3002)
echo -e "${YELLOW}[4/4] Starting Customer Service on port 3002...${NC}"
cd services/customer_service
bundle exec rails server -p 3002 &
CUSTOMER_PID=$!

# Start Sneakers Consumer
echo -e "${YELLOW}[5/5] Starting Sneakers Consumer...${NC}"
OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES bundle exec rake consumers:start &
SNEAKERS_PID=$!
cd ../..

echo -e "${GREEN}All services started!${NC}"
echo ""
echo "Services running:"
echo "  - Order Service:    http://localhost:3001"
echo "  - Customer Service: http://localhost:3002"
echo "  - RabbitMQ Admin:   http://localhost:15672 (guest/guest)"
echo ""
echo "Press Ctrl+C to stop all services"

# Trap Ctrl+C to cleanup
cleanup() {
    echo -e "\n${YELLOW}Stopping services...${NC}"
    kill $ORDER_PID 2>/dev/null
    kill $CUSTOMER_PID 2>/dev/null
    kill $SNEAKERS_PID 2>/dev/null
    echo -e "${GREEN}All services stopped.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Wait for any process to exit
wait
