
#!/bin/bash
# Voting App Performance Monitor - v1.0 (2025-04-22)
# Tracks: Redis queue, DB writes, vote processing, and container resources

# Config
read -p "Enter Voting URL to monitor (e.g. http://localhost:8080): " VOTE_URL
read -p "Enter Results URL to monitor (e.g. http://localhost:8080): " RESULTS_URL


# Validate URL format
if [[ ! "$VOTE_URL" =~ ^http(s)?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
  echo -e "\033[1;31mERROR: Invalid URL format for Voting URL\033[0m"
  exit 1
fi

if [[ ! "$RESULTS_URL" =~ ^http(s)?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
  echo -e "\033[1;31mERROR: Invalid URL format for Results URL\033[0m"
  exit 1
fi

# Initial connectivity test
if ! curl -sI --connect-timeout 3 "$VOTE_URL" >/dev/null; then
  echo -e "\033[1;33mWARNING: Voting URL may not be accessible (check firewall/network)\033[0m"
  read -p "Continue anyway? (y/n) " -n 1 -r
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
  echo
fi

# Initial connectivity test
if ! curl -sI --connect-timeout 3 "$RESULTS_URL" >/dev/null; then
  echo -e "\033[1;33mWARNING: Results URL may not be accessible (check firewall/network)\033[0m"
  read -p "Continue anyway? (y/n) " -n 1 -r
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
  echo
fi

if ! command -v ab >/dev/null; then
    echo "Installing apache2-utils for ab..."
    sudo apt-get install -y apache2-utils
fi

DURATION=300  # 5-minute test
LOG_FILE="voting_metrics_$(date +%Y%m%d_%H%M%S).csv"

# Init log with application-specific columns
echo "timestamp, cpu_percent, mem_mb, redis_queue, db_writes, db_commits, db_rollbacks, vote_latency, result_latency, vote_rps, result_rps, worker_active" > "$LOG_FILE"

# Color codes
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Get container IDs
REDIS_CONTAINER=$(docker ps --filter "name=example-voting-app-redis-1" --format "{{.ID}}" | head -1)
WORKER_CONTAINER=$(docker ps --filter "name=example-voting-app-worker-1" --format "{{.ID}}" | head -1)
DB_CONTAINER=$(docker ps --filter "name=example-voting-app-db-1" --format "{{.ID}}" | head -1)
# example-voting-app-redis-1
while [ $SECONDS -lt $DURATION ]; do
  # 1. System Metrics
  CPU_PERCENT=$(docker stats --no-stream --format "{{.CPUPerc}}" $WORKER_CONTAINER | tr -d '%')
  MEM_MB=$(docker stats --no-stream --format "{{.MemUsage}}" $WORKER_CONTAINER | awk '{print $1}')
  
  # 2. Application-Specific Metrics
  # Redis queue length
  REDIS_QUEUE=$(docker exec "$REDIS_CONTAINER" redis-cli LLEN votes 2>/dev/null | tr -d ' ')  
  # Database write operations
  DB_WRITES=$(docker exec "$DB_CONTAINER" psql -U postgres -d postgres -t -c "SELECT COALESCE(SUM(xact_commit + xact_rollback), 0) FROM pg_stat_database WHERE datname='postgres';" | awk '{print $1}')  
  DB_COMMITS=$(docker exec "$DB_CONTAINER" psql -U postgres -d postgres -t -c "SELECT COALESCE(SUM(xact_commit), 0) FROM pg_stat_database WHERE datname='postgres';" | awk '{print $1}')
  DB_ROLLBACKS=$(docker exec "$DB_CONTAINER" psql -U postgres -d postgres -t -c "SELECT COALESCE(SUM(xact_rollback), 0) FROM pg_stat_database WHERE datname='postgres';" | awk '{print $1}')
  # Worker activity
  WORKER_ACTIVE=$(docker exec $WORKER_CONTAINER ps aux | wc -l | tr -d ' ')
  
  # 3. Endpoint Performance
  VOTE_LATENCY=$(curl -o /dev/null -s -w "%{time_total}\n" $VOTE_URL | awk '{printf "%.1f", $1*1000}')
  RESULT_LATENCY=$(curl -o /dev/null -s -w "%{time_total}\n" $RESULTS_URL | awk '{printf "%.1f", $1*1000}')
  
  # Throughput tests (short bursts)
  VOTE_RPS=$(ab -n 50 -c 5 -q "$VOTE_URL/" 2>/dev/null | grep "Requests per second" | awk '{printf "%.1f", $4}')
  RESULT_RPS=$(ab -n 50 -c 5 -q "$RESULTS_URL/" 2>/dev/null | grep "Requests per second" | awk '{printf "%.1f", $4}')

  # Live Dashboard
  clear
  echo -e "=== VOTING APP MONITOR ==="
  echo -e "Time remaining: $((DURATION - SECONDS))s"
  printf "%-20s %-20s\n" "CPU in %: ${CPU_PERCENT}%" "Memory in MiB: ${MEM_MB}"
  echo -e "\n${GREEN}APPLICATION QUEUES${NC}"
  printf "%-20s %-20s\n" "Redis backlog:" "${REDIS_QUEUE} votes" "DB writes:" "${DB_WRITES} tx" "DB commits:" "${DB_COMMITS} tx" "DB rollbacks:" "${DB_ROLLBACKS} tx"
  echo -e "\n${GREEN}ENDPOINT PERFORMANCE${NC}"
  printf "%-20s %-20s\n" "Vote latency:" "${VOTE_LATENCY}ms" "Results latency:" "${RESULT_LATENCY}ms"
  printf "%-20s %-20s\n" "Vote throughput:" "${VOTE_RPS}RPS" "Results throughput:" "${RESULT_RPS}RPS"
  echo -e "\n${GREEN}WORKER STATUS${NC}"
  echo -e "Active processes: ${WORKER_ACTIVE}"
  
  # Log all data
  echo "$(date +%T), $CPU_PERCENT, $MEM_MB, $REDIS_QUEUE, $DB_WRITES, $DB_COMMITS, $DB_ROLLBACKS, $VOTE_LATENCY, $RESULT_LATENCY, $VOTE_RPS, $RESULT_RPS, $WORKER_ACTIVE" >> "$LOG_FILE"
  sleep 10
done

# Generate specialized report
echo -e "\n=== VOTING APP ANALYSIS ==="
awk -F',' 'NR>1 {
  cpu+=$2; mem+=$3; redis+=$4; db+=$5; commits+=$6; rollbacks+=$7;
  vlat+=$8; rlat+=$9; vrps+=$10; rrps+=$11
} END {
  print "Resource Usage:"
  print "  CPU Avg: " cpu/(NR-1) "%"
  print "  Mem Avg: " mem/(NR-1) "MB"
  print "\nApplication Metrics:"
  print "  Redis queue avg: " redis/(NR-1) " votes"
  print "  DB write rate: " db/300 " tx/min"
  print "  DB commit rate: " commits/300 " tx/min"
  print "  DB rollback rate: " rollbacks/300 " tx/min"
  print "  Vote latency avg: " vlat/(NR-1) "ms"
  print "  Results latency avg: " rlat/(NR-1) "ms"
  print "\nThroughput Capacity:"
  print "  Vote avg: " vrps/(NR-1) " RPS"
  print "  Results avg: " rrps/(NR-1) " RPS"
}' "$LOG_FILE"
