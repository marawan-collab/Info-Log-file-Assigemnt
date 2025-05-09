#!/bin/bash

# Check if log file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_log_file>"
    exit 1
fi

LOG_FILE=$1

# Check if file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: File $LOG_FILE not found!"
    exit 1
fi

# Output file
OUTPUT_FILE="log_analysis_report_$(date +%Y%m%d_%H%M%S).txt"

# Function to print separator
separator() {
    echo "=========================================" >> "$OUTPUT_FILE"
}

# Function to print header
header() {
    echo "" >> "$OUTPUT_FILE"
    separator
    echo "$1" >> "$OUTPUT_FILE"
    separator
}

# Clear output file if exists
> "$OUTPUT_FILE"

header "LOG FILE ANALYSIS REPORT"
echo "Analyzed file: $LOG_FILE" >> "$OUTPUT_FILE"
echo "Report generated: $(date)" >> "$OUTPUT_FILE"

# 1. Request Counts
header "1. REQUEST COUNTS"
total_requests=$(wc -l < "$LOG_FILE")
echo "Total requests: $total_requests" >> "$OUTPUT_FILE"

get_requests=$(grep -c 'GET' "$LOG_FILE")
echo "GET requests: $get_requests" >> "$OUTPUT_FILE"

post_requests=$(grep -c 'POST' "$LOG_FILE")
echo "POST requests: $post_requests" >> "$OUTPUT_FILE"

# 2. Unique IP Addresses
header "2. UNIQUE IP ADDRESSES"
unique_ips=$(awk '{print $1}' "$LOG_FILE" | sort | uniq | wc -l)
echo "Total unique IPs: $unique_ips" >> "$OUTPUT_FILE"

header "2.1 REQUESTS PER UNIQUE IP"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -10 | awk '{print "IP: " $2 ", Total requests: " $1}' >> "$OUTPUT_FILE"

header "2.2 GET/POST REQUESTS PER IP (TOP 10)"
awk '{print $1,$7}' "$LOG_FILE" | grep -E "GET|POST" | sort | uniq -c | sort -nr | head -10 | awk '{print "IP: " $2 ", Method: " $3 ", Count: " $1}' >> "$OUTPUT_FILE"

# 3. Failure Requests
header "3. FAILURE REQUESTS"
failed_requests=$(awk '{print $9}' "$LOG_FILE" | grep -E '^4|^5' | wc -l)
echo "Total failed requests (4xx/5xx): $failed_requests" >> "$OUTPUT_FILE"

percentage=$(echo "scale=2; ($failed_requests/$total_requests)*100" | bc)
echo "Percentage of failed requests: $percentage%" >> "$OUTPUT_FILE"

# 4. Top User
header "4. MOST ACTIVE IP"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print "IP: " $2 ", Requests: " $1}' >> "$OUTPUT_FILE"

# 5. Daily Request Averages
header "5. DAILY REQUEST AVERAGES"
dates=$(awk '{print $4}' "$LOG_FILE" | cut -d: -f1 | cut -d[ -f2 | sort | uniq)
total_days=$(echo "$dates" | wc -l)
echo "Total days in log: $total_days" >> "$OUTPUT_FILE"
avg_requests=$(echo "scale=2; $total_requests/$total_days" | bc)
echo "Average requests per day: $avg_requests" >> "$OUTPUT_FILE"

# 6. Failure Analysis
header "6. FAILURE ANALYSIS BY DAY"
awk '{print $4,$9}' "$LOG_FILE" | grep -E ' 4| 5' | cut -d: -f1 | cut -d[ -f2 | sort | uniq -c | sort -nr | head -5 | awk '{print "Date: " $2 ", Failures: " $1}' >> "$OUTPUT_FILE"

# Additional Analysis

# Request by Hour
header "ADDITIONAL: REQUESTS BY HOUR"
awk '{print $4}' "$LOG_FILE" | cut -d: -f2 | sort | uniq -c | sort -nr | awk '{print "Hour: " $2 ":00, Requests: " $1}' >> "$OUTPUT_FILE"

# Status Codes Breakdown
header "ADDITIONAL: STATUS CODE BREAKDOWN"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk '{print "Status: " $2 ", Count: " $1}' >> "$OUTPUT_FILE"

# Most Active User by Method
header "ADDITIONAL: MOST ACTIVE USER BY METHOD"
echo "Most active GET user:" >> "$OUTPUT_FILE"
awk '{if ($7 == "GET") print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print "IP: " $2 ", GET requests: " $1}' >> "$OUTPUT_FILE"

echo "Most active POST user:" >> "$OUTPUT_FILE"
awk '{if ($7 == "POST") print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1 | awk '{print "IP: " $2 ", POST requests: " $1}' >> "$OUTPUT_FILE"

# Patterns in Failure Requests
header "ADDITIONAL: FAILURE PATTERNS BY HOUR"
awk '{print $4,$9}' "$LOG_FILE" | grep -E ' 4| 5' | cut -d: -f2 | sort | uniq -c | sort -nr | head -5 | awk '{print "Hour: " $2 ":00, Failures: " $1}' >> "$OUTPUT_FILE"

# Suggestions
header "ANALYSIS SUGGESTIONS"
echo "1. Failure Reduction:" >> "$OUTPUT_FILE"
echo "   - Investigate the most common error codes and their causes" >> "$OUTPUT_FILE"
echo "   - Check server resources during peak failure times" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "2. Peak Times:" >> "$OUTPUT_FILE"
echo "   - Consider scaling resources during high traffic hours" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "3. Security:" >> "$OUTPUT_FILE"
echo "   - Monitor IPs with unusually high request rates" >> "$OUTPUT_FILE"
echo "   - Check for patterns in failed requests that might indicate attacks" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "4. System Improvements:" >> "$OUTPUT_FILE"
echo "   - Optimize endpoints with most failures" >> "$OUTPUT_FILE"
echo "   - Consider caching for frequently accessed resources" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "Analysis complete. Report saved to $OUTPUT_FILE"

# Display the report
cat "$OUTPUT_FILE"
