#!/bin/bash
# Linux Tweet App Advanced Monitor - v2.0 (2025-04-22)
# Tracks: CPU, Memory, Latency, Throughput, Network, Disk

# Config
read -p "Enter URL to monitor (e.g. http://localhost:8080): " URL

# Validate URL format
if [[ ! "$URL" =~ ^http(s)?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
  echo -e "\033[1;31mERROR: Invalid URL format\033[0m"
  exit 1
fi

# Initial connectivity test
if ! curl -sI --connect-timeout 3 "$URL" >/dev/null; then
  echo -e "\033[1;33mWARNING: URL may not be accessible (check firewall/network)\033[0m"
  read -p "Continue anyway? (y/n) " -n 1 -r
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
  echo
fi


DURATION=60  # 1-minute test
LOG_FILE="tweet_metrics_$(date +%Y%m%d_%H%M%S).csv"

# Init log with new columns
echo "timestamp, cpu_percent, mem_mb, latency_ms, rps, errors, net_rx_mb, net_tx_mb, block_read_mb, block_write_mb" > "$LOG_FILE"

# Thresholds (customize these)
NET_THRESHOLD=10    # MB/min
BLOCK_THRESHOLD=5   # MB/min
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Convert Docker size format (e.g. "1.45kB" → "0.00145")
to_mb() {
  echo "$1" | awk '{
    if ($1 ~ /kB/) {printf "%.2f", $1/1024}
    else if ($1 ~ /MB/) {printf "%.2f", $1}
    else if ($1 ~ /GB/) {printf "%.2f", $1*1024}
    else {printf "%.2f", $1/1048576}
  }'
}

while [ $SECONDS -lt $DURATION ]; do
  # 1. Get all Docker stats at once
  STATS=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.NetIO}},{{.BlockIO}}" | head -1)
  
  # Parse metrics
  CPU_PERCENT=$(echo "$STATS" | cut -d',' -f1 | tr -d '%')
  MEM_MB=$(echo "$STATS" | cut -d',' -f2 | awk '{print $1}')
  NET_RX=$(to_mb "$(echo "$STATS" | cut -d',' -f3 | awk '{print $1}')")
  NET_TX=$(to_mb "$(echo "$STATS" | cut -d',' -f3 | awk '{print $3}')")
  BLOCK_READ=$(to_mb "$(echo "$STATS" | cut -d',' -f4 | awk '{print $1}')")
  BLOCK_WRITE=$(to_mb "$(echo "$STATS" | cut -d',' -f4 | awk '{print $3}')")
  
  # 2. Latency & Throughput
  LATENCY=$(curl -o /dev/null -s -w "%{time_total}\n" "$URL" | awk '{printf "%.1f", $1*1000}')
  RPS=$(ab -n 100 -c 10 "$URL/" 2>/dev/null | grep "Requests per second" | awk '{printf "%.1f", $4}')
  HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}\n" "$URL")
  ERRORS=$([ "$HTTP_CODE" -ne 200 ] && echo 1 || echo 0)
  
  # Alert logic
  NET_ALERT=$([ $(echo "$NET_RX + $NET_TX >= $NET_THRESHOLD" | bc) -eq 1 ] && echo "${RED}HIGH${NC}" || echo "${GREEN}OK${NC}")
  BLOCK_ALERT=$([ $(echo "$BLOCK_READ + $BLOCK_WRITE >= $BLOCK_THRESHOLD" | bc) -eq 1 ] && echo "${YELLOW}ACTIVE${NC}" || echo "${GREEN}IDLE${NC}")
  
  # Live Dashboard
  clear
  echo -e "=== TWEET APP MONITOR ==="
  echo -e "Time remaining: $((DURATION - SECONDS))s"
  printf "%-15s %-15s %-15s\n" "CPU: ${CPU_PERCENT}%" "Memory: ${MEM_MB}MB" "Latency: ${LATENCY}ms"
  printf "%-15s %-15s %-15s\n" "Throughput: ${RPS}RPS" "Errors: ${ERRORS}"
  echo -e "\n${GREEN}NETWORK${NC}  RX: ${NET_RX}MB  TX: ${NET_TX}MB  Status: ${NET_ALERT}"
  echo -e "${GREEN}DISK${NC}    Read: ${BLOCK_READ}MB  Write: ${BLOCK_WRITE}MB  Status: ${BLOCK_ALERT}"
  
  # Log all data
  echo "$(date +%T), $CPU_PERCENT, $MEM_MB, $LATENCY, $RPS, $ERRORS, $NET_RX, $NET_TX, $BLOCK_READ, $BLOCK_WRITE" >> "$LOG_FILE"
  sleep 5
done

# Generate report
echo -e "\n=== TWEET APP ANALYSIS ==="
awk -F',' 'NR>1 {
  cpu+=$2; mem+=$3; lat+=$4; rps+=$5; err+=$6; 
  net_rx+=$7; net_tx+=$8; block_r+=$9; block_w+=$10
} END {
  print "CPU Avg: " cpu/(NR-1) "%"
  print "Mem Avg: " mem/(NR-1) "MB"
  print "Latency Avg: " lat/(NR-1) "ms"
  print "Throughput Avg: " rps/(NR-1) " RPS"
  print "Total Errors: " err
  print "\nNETWORK Totals:"
  print "  Received: " net_rx "MB (" net_rx/60 "MB/min)"
  print "  Sent: " net_tx "MB (" net_tx/60 "MB/min)"
  print "\nDISK Totals:"
  print "  Read: " block_r "MB (" block_r/60 "MB/min)"
  print "  Written: " block_w "MB (" block_w/60 "MB/min)"
}' "$LOG_FILE"