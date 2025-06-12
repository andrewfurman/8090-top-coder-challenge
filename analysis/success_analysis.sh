#!/bin/bash

echo "=== SUCCESS CASE ANALYSIS ==="
echo "Finding cases where your algorithm performs well to understand the correct patterns"
echo ""

# Let's test your algorithm against the first 50 cases and find the ones with small errors
echo "Testing first 50 cases to find successful patterns:"
echo ""

case_index=0
success_count=0
declare -a successful_cases=()

while IFS= read -r line && [ $case_index -lt 50 ]; do
    if [[ $line == *"trip_duration_days"* ]]; then
        days=$(echo "$line" | grep -o '[0-9]\+')
    elif [[ $line == *"miles_traveled"* ]]; then
        miles=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
    elif [[ $line == *"total_receipts_amount"* ]]; then
        receipts=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
    elif [[ $line == *"expected_output"* ]]; then
        expected=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        
        # Test your algorithm
        your_result=$(./run.sh $days $miles $receipts)
        error=$(echo "scale=2; $your_result - $expected" | bc)
        error_abs=${error#-}  # absolute value
        error_percent=$(echo "scale=1; ($error_abs / $expected) * 100" | bc)
        
        # Consider it successful if error is less than 20%
        if (( $(echo "$error_abs < ($expected * 0.2)" | bc -l) )); then
            echo "SUCCESS Case $case_index: $days days, $miles miles, \$$receipts receipts"
            echo "  Expected: \$$expected, Your: \$$your_result, Error: \$$error (${error_percent}%)"
            
            # Calculate some ratios for pattern analysis
            expected_per_day=$(echo "scale=2; $expected / $days" | bc)
            echo "  Expected per day: \$$expected_per_day"
            
            success_count=$((success_count + 1))
            successful_cases+=("$case_index:$days:$miles:$receipts:$expected:$your_result")
        fi
        
        case_index=$((case_index + 1))
    fi
done < public_cases.json

echo ""
echo "Found $success_count successful cases out of 50 tested"
echo ""

echo "=== ANALYZING SUCCESSFUL PATTERNS ==="
echo ""

# Analyze the characteristics of successful cases
echo "Characteristics of successful cases:"
echo ""

total_success_days=0
total_success_miles=0
total_success_receipts=0
max_success_receipts=0

for case_data in "${successful_cases[@]}"; do
    IFS=':' read -r idx days miles receipts expected your_result <<< "$case_data"
    
    total_success_days=$((total_success_days + days))
    total_success_miles=$(echo "scale=2; $total_success_miles + $miles" | bc)
    total_success_receipts=$(echo "scale=2; $total_success_receipts + $receipts" | bc)
    
    # Track max receipts in successful cases
    if (( $(echo "$receipts > $max_success_receipts" | bc -l) )); then
        max_success_receipts=$receipts
    fi
done

if [ $success_count -gt 0 ]; then
    avg_success_days=$(echo "scale=1; $total_success_days / $success_count" | bc)
    avg_success_miles=$(echo "scale=1; $total_success_miles / $success_count" | bc)
    avg_success_receipts=$(echo "scale=2; $total_success_receipts / $success_count" | bc)
    
    echo "Average successful case:"
    echo "  Days: $avg_success_days"
    echo "  Miles: $avg_success_miles" 
    echo "  Receipts: \$$avg_success_receipts"
    echo "  Max receipts in successful cases: \$$max_success_receipts"
fi

echo ""
echo "=== FAILURE THRESHOLD ANALYSIS ==="
echo ""

# Let's find the threshold where cases start failing badly
echo "Analyzing thresholds where algorithm starts failing:"
echo ""

echo "HIGH RECEIPT FAILURES:"
failure_count=0
case_index=0

while IFS= read -r line && [ $case_index -lt 100 ]; do
    if [[ $line == *"trip_duration_days"* ]]; then
        days=$(echo "$line" | grep -o '[0-9]\+')
    elif [[ $line == *"miles_traveled"* ]]; then
        miles=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
    elif [[ $line == *"total_receipts_amount"* ]]; then
        receipts=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
    elif [[ $line == *"expected_output"* ]]; then
        expected=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        
        # Check for high-receipt failures
        if (( $(echo "$receipts > 500" | bc -l) )); then
            your_result=$(./run.sh $days $miles $receipts)
            error=$(echo "scale=2; $your_result - $expected" | bc)
            error_abs=${error#-}
            error_percent=$(echo "scale=1; ($error_abs / $expected) * 100" | bc)
            
            if (( $(echo "$error_abs > ($expected * 0.5)" | bc -l) )); then
                echo "FAILURE Case $case_index: $days days, $miles miles, \$$receipts receipts"
                echo "  Expected: \$$expected, Your: \$$your_result, Error: \$$error (${error_percent}%)"
                
                failure_count=$((failure_count + 1))
                if [ $failure_count -ge 5 ]; then
                    break
                fi
            fi
        fi
        
        case_index=$((case_index + 1))
    fi
done < public_cases.json

echo ""
echo "=== CRITICAL INSIGHT: RECEIPT PROCESSING LOGIC ==="
echo ""

# Test a theory: maybe receipts above a certain amount get capped or penalized heavily
echo "Testing receipt cap theory with Case 151 (4 days, 69 miles, \$2321.49 → \$322):"
echo ""

# If the expected is $322 for 4 days, that's $80.50/day
# Your algorithm gives per-diem + mileage + receipt processing
# Let's see what happens if we cap receipts

echo "Possible receipt processing logic:"
echo ""

# Theory 1: Receipts capped at a low amount
for cap in 50 100 200 300; do
    capped_receipts=$cap
    if (( $(echo "$receipts > $cap" | bc -l) )); then
        capped_receipts=$cap
    else
        capped_receipts=$receipts
    fi
    
    echo "  If receipts capped at \$$cap: use \$$capped_receipts instead of \$2321.49"
done

echo ""

# Theory 2: High receipts get negative adjustment
echo "Theory: High receipts might get PENALTY instead of benefit"
echo "If receipts > \$X, maybe they REDUCE the reimbursement instead of increase it"
echo ""

# Let's test this theory
receipts_2321=2321.49
expected_322=322

echo "Case 151 math check:"
echo "  If base calculation (days + miles) = X"
echo "  And receipts over \$1000 get penalty = -Y"
echo "  Then X - Y = \$322"
echo ""

# Test what base calculation might be without receipts
base_without_receipts=$(./run.sh 4 69 0)
echo "Your algorithm with \$0 receipts: \$$base_without_receipts"
echo "Actual expected with \$2321.49 receipts: \$322"
echo "Difference: $(echo "scale=2; $base_without_receipts - 322" | bc)"
echo ""
echo "This suggests receipts REDUCE reimbursement by: $(echo "scale=2; $base_without_receipts - 322" | bc)"
echo "That's a penalty rate of: $(echo "scale=4; ($base_without_receipts - 322) / 2321.49" | bc) per dollar of receipts"

echo ""
echo "=== RECOMMENDED ALGORITHM CHANGES ==="
echo ""
echo "Based on analysis, the real algorithm likely:"
echo "1. Has much lower base per-diem rates than your current algorithm"
echo "2. Caps receipt reimbursement at a low amount (maybe \$100-200 max)"
echo "3. OR applies penalties for high receipts instead of benefits"
echo "4. Has more aggressive penalties for long trips"
echo "5. May have different mileage rates or caps"