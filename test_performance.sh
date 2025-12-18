#!/bin/bash
# test_performance.sh - SentinelCore Performance Benchmark Suite

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

API_URL="${API_URL:-http://localhost:8080/api}"
COOKIE_JAR="/tmp/sentinelcore_cookies_$$.txt"
CONCURRENT_REQUESTS="${CONCURRENT_REQUESTS:-20}"
REQUESTS_PER_WORKER="${REQUESTS_PER_WORKER:-5}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SentinelCore Performance & Stability Benchmark Suite      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Cleanup function
cleanup() {
    rm -f "$COOKIE_JAR"
}
trap cleanup EXIT

# Check if API is running
echo -e "${YELLOW}[1/5] Checking API connectivity...${NC}"
if ! curl -s "$API_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}✗ API not responding at $API_URL${NC}"
    echo "Start backend with: cd vulnerability-manager && cargo run --release"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"
echo ""

# Authenticate and save cookies
echo -e "${YELLOW}[2/5] Getting authentication token...${NC}"

AUTHENTICATED=0
for CREDS in '{"username":"admin","password":"admin123"}' \
             '{"username":"admin","password":"admin"}' \
             '{"email":"admin@sentinelcore.local","password":"admin123"}' \
             '{"email":"admin@sentinelcore.local","password":"admin"}'; do
    curl -s -c "$COOKIE_JAR" -X POST "$API_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "$CREDS" > /dev/null 2>&1
    
    if grep -q "auth_token" "$COOKIE_JAR" 2>/dev/null; then
        AUTHENTICATED=1
        break
    fi
done

if [ $AUTHENTICATED -eq 0 ]; then
    echo -e "${RED}✗ Failed to authenticate${NC}"
    echo "Please check your login credentials and try:"
    echo "  bash test_performance.sh"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated (cookie saved)${NC}"
echo ""

# Test 1: Sequential Requests (Baseline)
echo -e "${YELLOW}[3/5] TEST 1: Sequential Requests (Baseline)${NC}"
echo "Making 20 sequential requests to measure latency..."

TOTAL_TIME=0

for i in {1..20}; do
    START=$(date +%s%N)
    HTTP_CODE=$(curl -s -b "$COOKIE_JAR" -o /dev/null -w "%{http_code}" -X GET "$API_URL/vulnerabilities?limit=5")
    END=$(date +%s%N)
    ELAPSED=$(( ($END - $START) / 1000000 ))
    TOTAL_TIME=$(( $TOTAL_TIME + $ELAPSED ))
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -ne "\r  Request $i/20: ${GREEN}200 OK${NC} (${ELAPSED}ms)"
    else
        echo -ne "\r  Request $i/20: ${RED}$HTTP_CODE ERROR${NC}"
    fi
done

AVG_TIME=$(( $TOTAL_TIME / 20 ))
echo ""
echo -e "  Average latency: ${GREEN}${AVG_TIME}ms${NC}"
echo ""

# Test 2: Concurrent Requests (Connection Pool Test)
echo -e "${YELLOW}[4/5] TEST 2: Concurrent Requests (Connection Pool Stress)${NC}"
echo "Simulating $CONCURRENT_REQUESTS concurrent users with $REQUESTS_PER_WORKER requests each..."

RESULTS_DIR="/tmp/sentinelcore_bench_$$"
mkdir -p "$RESULTS_DIR"

SUCCESS=0
FAILURE=0
START_TOTAL=$(date +%s%N)

for i in $(seq 1 $CONCURRENT_REQUESTS); do
    {
        for j in $(seq 1 $REQUESTS_PER_WORKER); do
            HTTP_CODE=$(curl -s -b "$COOKIE_JAR" -o /dev/null -w "%{http_code}" -X GET "$API_URL/vulnerabilities?limit=10")
            echo "$HTTP_CODE" >> "$RESULTS_DIR/worker_$i.txt"
        done
    } &
done

wait

END_TOTAL=$(date +%s%N)
TOTAL_TEST_TIME=$(( ($END_TOTAL - $START_TOTAL) / 1000000000 ))

# Analyze results
for file in "$RESULTS_DIR"/worker_*.txt; do
    if [ -f "$file" ]; then
        while IFS= read -r code; do
            if [ "$code" = "200" ]; then
                SUCCESS=$((SUCCESS + 1))
            else
                FAILURE=$((FAILURE + 1))
            fi
        done < "$file"
    fi
done

TOTAL_REQUESTS=$(( $SUCCESS + $FAILURE ))
if [ $TOTAL_REQUESTS -gt 0 ]; then
    SUCCESS_RATE=$(( ($SUCCESS * 100) / $TOTAL_REQUESTS ))
else
    SUCCESS_RATE=0
fi

echo -e "  Completed in: ${GREEN}${TOTAL_TEST_TIME}s${NC}"
echo -e "  Total requests: $TOTAL_REQUESTS"
echo -e "  Successful (200): ${GREEN}$SUCCESS${NC}"
echo -e "  Failed (5xx): ${RED}$FAILURE${NC}"
echo -e "  Success rate: $([ $SUCCESS_RATE -ge 95 ] && echo -e "${GREEN}" || echo -e "${RED}")${SUCCESS_RATE}%${NC}"
if [ $TOTAL_TEST_TIME -gt 0 ]; then
    echo -e "  Throughput: $(( $TOTAL_REQUESTS / $TOTAL_TEST_TIME )) req/sec"
fi
echo ""

# Cleanup
rm -rf "$RESULTS_DIR"

# Test 3: Health Check Analysis
echo -e "${YELLOW}[5/5] TEST 3: Connection Pool Status${NC}"
HEALTH=$(curl -s -b "$COOKIE_JAR" -X GET "$API_URL/health")

echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH"
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  BENCHMARK COMPLETE                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $SUCCESS_RATE -ge 99 ]; then
    echo -e "${GREEN}✓ System is STABLE${NC}"
    echo "  - Success rate > 99%"
    echo "  - Connection pool healthy"
    exit 0
elif [ $SUCCESS_RATE -ge 95 ]; then
    echo -e "${YELLOW}⚠ System is ACCEPTABLE${NC}"
    echo "  - Success rate 95-99%"
    echo "  - Some connection timeouts detected"
    echo "  - Monitor database and consider optimization"
    exit 0
else
    echo -e "${RED}✗ System is UNSTABLE${NC}"
    echo "  - Success rate < 95%"
    echo "  - Significant connection pool exhaustion"
    echo "  - Apply fixes immediately"
    exit 1
fi
