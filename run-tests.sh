#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

run_tests() {
  local service=$1
  local path="services/$service"

  echo -e "\n${YELLOW}[$service] Running tests...${NC}"
  cd "$path"
  if bundle exec rspec --format documentation; then
    echo -e "${GREEN}[$service] All tests passed${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}[$service] Some tests failed${NC}"
    FAILED=$((FAILED + 1))
  fi
  cd ../..
}

echo -e "${GREEN}Running all tests...${NC}"

run_tests "order_service"
run_tests "customer_service"

echo ""
echo "================================"
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All services passed${NC}"
else
  echo -e "${RED}$FAILED service(s) with failures${NC}"
fi
echo "================================"

exit $FAILED
