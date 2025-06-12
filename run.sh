#!/bin/bash

# Black Box Challenge - Reimbursement System Replica
# This script replicates the legacy 60-year-old reimbursement system
# Usage: ./run.sh <trip_duration_days> <miles_traveled> <total_receipts_amount>

# Validate input parameters
if [ $# -ne 3 ]; then
    echo "Error: Exactly 3 parameters required" >&2
    echo "Usage: $0 <trip_duration_days> <miles_traveled> <total_receipts_amount>" >&2
    exit 1
fi

# Get input parameters
days=$1
miles=$2
receipts=$3

# Check if parameters are numeric
if ! [[ "$days" =~ ^[0-9]+$ ]] || ! [[ "$miles" =~ ^[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$receipts" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Invalid numeric parameters" >&2
    exit 1
fi

# FIXED: Base per diem calculation with reduced rates based on high-error case analysis
# Analysis showed my rates were 50-100% too high for long trips
if [ "$days" -eq 1 ]; then
    base_perdiem=85  # Reduced from 95
elif [ "$days" -eq 2 ]; then
    base_perdiem=88  # Reduced from 102
elif [ "$days" -le 4 ]; then
    base_perdiem=85  # Reduced from 105
elif [ "$days" -eq 5 ]; then
    base_perdiem=85  # Reduced from 108, 5-day bonus was overestimated
elif [ "$days" -le 7 ]; then
    base_perdiem=80  # Reduced from 102
elif [ "$days" -le 10 ]; then
    base_perdiem=75  # Reduced from 98
else
    base_perdiem=65  # Reduced from 95 - long trips get much lower rates
fi

# Calculate base amount
base_amount=$(echo "scale=2; $days * $base_perdiem" | bc)

# Mileage calculation with tiered rates
if (( $(echo "$miles <= 100" | bc -l) )); then
    mileage_reimbursement=$(echo "scale=2; $miles * 0.65" | bc)
else
    mileage_reimbursement=$(echo "scale=2; 100 * 0.65 + ($miles - 100) * 0.45" | bc)
fi

# FIXED: Receipt processing - high receipts penalize instead of benefit
# Analysis showed high receipts (>$1000) cause major penalties, not benefits
if (( $(echo "$receipts <= 5.0" | bc -l) )); then
    receipt_adjustment=-10.0  # Small penalty for tiny receipts
elif (( $(echo "$receipts <= 50.0" | bc -l) )); then
    receipt_adjustment=$(echo "scale=2; $receipts * 0.2" | bc)  # Small benefit
elif (( $(echo "$receipts <= 500.0" | bc -l) )); then
    receipt_adjustment=$(echo "scale=2; $receipts * 0.15" | bc)  # Moderate benefit
elif (( $(echo "$receipts <= 1000.0" | bc -l) )); then
    # Cap beneficial receipts at 500, start applying penalties
    base_benefit=$(echo "scale=2; 500 * 0.15" | bc)  # $75 max benefit
    excess=$(echo "scale=2; $receipts - 500" | bc)
    penalty=$(echo "scale=2; $excess * 0.05" | bc)  # 5% penalty on excess
    receipt_adjustment=$(echo "scale=2; $base_benefit - $penalty" | bc)
else
    # High receipts (>$1000) get heavy penalties - this was the key missing piece
    base_benefit=$(echo "scale=2; 500 * 0.15" | bc)  # $75 max benefit
    excess_moderate=$(echo "scale=2; 500 * 0.05" | bc)  # $25 penalty for 500-1000 range
    excess_high=$(echo "scale=2; ($receipts - 1000) * 0.08" | bc)  # 8% penalty for >$1000
    receipt_adjustment=$(echo "scale=2; $base_benefit - $excess_moderate - $excess_high" | bc)
fi

# Efficiency and length adjustments
miles_per_day=$(echo "scale=2; $miles / $days" | bc)
efficiency_adjustment=0

if (( $(echo "$miles_per_day >= 100 && $miles_per_day <= 200" | bc -l) )); then
    efficiency_adjustment=15
elif (( $(echo "$miles_per_day > 250" | bc -l) )); then
    efficiency_adjustment=-10
fi

length_adjustment=0
if [ "$days" -eq 5 ]; then
    length_adjustment=25
elif [ "$days" -ge 12 ]; then
    length_adjustment=-15
fi

# Simple hash-based variance (pseudo-random)
hash_input="${days}_${miles}_${receipts}"
hash_val=$(echo -n "$hash_input" | cksum | cut -d' ' -f1)
hash_mod=$((hash_val % 100))
variance=$(echo "scale=2; ($hash_mod - 50) * 0.5" | bc)

# Combine all components
total=$(echo "scale=2; $base_amount + $mileage_reimbursement + $receipt_adjustment + $efficiency_adjustment + $length_adjustment + $variance" | bc)

# Ensure minimum reimbursement
if (( $(echo "$total < 50" | bc -l) )); then
    total=50.00
fi

# Output final result
printf "%.2f\n" "$total" 