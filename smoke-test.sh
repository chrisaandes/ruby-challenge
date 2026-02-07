#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ORDER_URL="http://localhost:3001"
CUSTOMER_URL="http://localhost:3002"
PASSED=0
FAILED=0

check() {
  local name=$1
  local method=$2
  local url=$3
  local expected_status=$4
  local body=$5
  local validate=$6

  if [ "$method" = "POST" ]; then
    response=$(curl -s -w "\n%{http_code}" -X POST "$url" -H "Content-Type: application/json" -d "$body" 2>/dev/null)
  else
    response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null)
  fi

  status=$(echo "$response" | tail -1)
  body_response=$(echo "$response" | sed '$d')

  if [ "$status" = "$expected_status" ]; then
    if [ -n "$validate" ]; then
      if echo "$body_response" | grep -q "$validate"; then
        echo -e "  ${GREEN}PASS${NC} $name (HTTP $status)"
        PASSED=$((PASSED + 1))
      else
        echo -e "  ${RED}FAIL${NC} $name - Expected '$validate' in response"
        echo -e "       Response: $body_response"
        FAILED=$((FAILED + 1))
      fi
    else
      echo -e "  ${GREEN}PASS${NC} $name (HTTP $status)"
      PASSED=$((PASSED + 1))
    fi
  else
    echo -e "  ${RED}FAIL${NC} $name - Expected HTTP $expected_status, got $status"
    echo -e "       Response: $body_response"
    FAILED=$((FAILED + 1))
  fi
}

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Smoke Test - Ruby Challenge Services  ${NC}"
echo -e "${CYAN}========================================${NC}"

# ---- 1. Health Checks ----
echo -e "\n${YELLOW}[1/5] Health Checks${NC}"
check "Order Service - Health" GET "$ORDER_URL/health" "200" "" "OK"
check "Customer Service - Health" GET "$CUSTOMER_URL/health" "200" "" "OK"
check "Order Service - RabbitMQ" GET "$ORDER_URL/health/rabbitmq" "200" "" "connected"

# ---- 2. Customer Service - Consultas ----
echo -e "\n${YELLOW}[2/5] Customer Service - Consultas${NC}"
check "Obtener Cliente 1 - María García" GET "$CUSTOMER_URL/api/v1/customers/1" "200" "" "María García"
check "Obtener Cliente 2 - Carlos López" GET "$CUSTOMER_URL/api/v1/customers/2" "200" "" "Carlos López"
check "Obtener Cliente 3 - Ana Martínez" GET "$CUSTOMER_URL/api/v1/customers/3" "200" "" "Ana Martínez"
check "Obtener Cliente 4 - Juan Hernández" GET "$CUSTOMER_URL/api/v1/customers/4" "200" "" "Juan Hernández"
check "Obtener Cliente 5 - Laura Sánchez" GET "$CUSTOMER_URL/api/v1/customers/5" "200" "" "Laura Sánchez"
check "Cliente inexistente (404)" GET "$CUSTOMER_URL/api/v1/customers/999" "404"

# ---- 3. Order Service - Crear Órdenes ----
echo -e "\n${YELLOW}[3/5] Order Service - Crear Órdenes${NC}"
check "Crear Orden - MacBook Pro (Cliente 1)" POST "$ORDER_URL/api/v1/orders" "201" \
  '{"order":{"customer_id":1,"product_name":"MacBook Pro M3","quantity":1,"price":2499.99}}' \
  "MacBook Pro M3"

check "Crear Orden - iPhone 15 (Cliente 2)" POST "$ORDER_URL/api/v1/orders" "201" \
  '{"order":{"customer_id":2,"product_name":"iPhone 15 Pro Max","quantity":2,"price":1199.99}}' \
  "iPhone 15 Pro Max"

check "Listar Órdenes" GET "$ORDER_URL/api/v1/orders" "200"
check "Filtrar Órdenes por Cliente 1" GET "$ORDER_URL/api/v1/orders?customer_id=1" "200" "" "MacBook"
check "Obtener Orden por ID" GET "$ORDER_URL/api/v1/orders/1" "200"
check "Orden inexistente (404)" GET "$ORDER_URL/api/v1/orders/99999" "404"

# ---- 4. Validaciones y Errores ----
echo -e "\n${YELLOW}[4/5] Validaciones y Errores${NC}"
check "Error - Cliente inexistente" POST "$ORDER_URL/api/v1/orders" "422" \
  '{"order":{"customer_id":999,"product_name":"Test","quantity":1,"price":100}}' \
  "errors"

check "Error - Campos faltantes" POST "$ORDER_URL/api/v1/orders" "422" \
  '{"order":{"customer_id":1}}' \
  "errors"

check "Error - Cantidad inválida (0)" POST "$ORDER_URL/api/v1/orders" "422" \
  '{"order":{"customer_id":1,"product_name":"Test","quantity":0,"price":100}}' \
  "errors"

check "Error - Precio negativo" POST "$ORDER_URL/api/v1/orders" "422" \
  '{"order":{"customer_id":1,"product_name":"Test","quantity":1,"price":-50}}' \
  "errors"

check "Error - Body vacío" POST "$ORDER_URL/api/v1/orders" "400" "{}"

# ---- 5. Flujo E2E (RabbitMQ + Sneakers) ----
echo -e "\n${YELLOW}[5/5] Flujo E2E - RabbitMQ + Sneakers${NC}"

# Get initial orders_count
initial_response=$(curl -s "$CUSTOMER_URL/api/v1/customers/4" 2>/dev/null)
initial_count=$(echo "$initial_response" | grep -o '"orders_count":[0-9]*' | grep -o '[0-9]*')
echo -e "  ${CYAN}INFO${NC} Juan Hernández orders_count inicial: $initial_count"

# Create order
check "Crear Orden para Juan" POST "$ORDER_URL/api/v1/orders" "201" \
  '{"order":{"customer_id":4,"product_name":"Samsung Galaxy S24","quantity":1,"price":1299.99}}' \
  "Samsung Galaxy S24"

# Wait for Sneakers to process
echo -e "  ${CYAN}INFO${NC} Esperando 3s para que Sneakers procese el evento..."
sleep 3

# Verify orders_count incremented
final_response=$(curl -s "$CUSTOMER_URL/api/v1/customers/4" 2>/dev/null)
final_count=$(echo "$final_response" | grep -o '"orders_count":[0-9]*' | grep -o '[0-9]*')

if [ -n "$final_count" ] && [ -n "$initial_count" ] && [ "$final_count" -gt "$initial_count" ]; then
  echo -e "  ${GREEN}PASS${NC} orders_count incrementó: $initial_count -> $final_count"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}FAIL${NC} orders_count no incrementó: $initial_count -> $final_count"
  echo -e "       Verifica que Sneakers esté corriendo"
  FAILED=$((FAILED + 1))
fi

# ---- Summary ----
TOTAL=$((PASSED + FAILED))
echo -e "\n${CYAN}========================================${NC}"
echo -e "  Total: $TOTAL  |  ${GREEN}Passed: $PASSED${NC}  |  ${RED}Failed: $FAILED${NC}"
echo -e "${CYAN}========================================${NC}"

if [ $FAILED -eq 0 ]; then
  echo -e "\n${GREEN}All checks passed! Stack is running correctly.${NC}"
else
  echo -e "\n${RED}Some checks failed. Review the output above.${NC}"
fi

exit $FAILED
