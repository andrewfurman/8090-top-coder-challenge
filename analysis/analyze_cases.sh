#!/bin/bash

# Function to find specific cases in the JSON
find_specific_cases() {
    echo "=== FINDING SPECIFIC HIGH-ERROR CASES ==="
    echo ""
    
    # Target cases with their characteristics
    declare -a target_cases=(
        "8:795:1645.99:644.69"
        "14:481:939.99:877.17"
        "4:69:2321.49:322.00"
        "8:482:1411.49:631.81"
        "11:740:1171.99:902.09"
    )
    
    case_index=0
    found_count=0
    
    # Read through the JSON file line by line
    while IFS= read -r line; do
        if [[ $line == *"trip_duration_days"* ]]; then
            days=$(echo "$line" | grep -o '[0-9]\+')
        elif [[ $line == *"miles_traveled"* ]]; then
            miles=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        elif [[ $line == *"total_receipts_amount"* ]]; then
            receipts=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        elif [[ $line == *"expected_output"* ]]; then
            expected=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
            
            # Check if this matches any target case
            for target in "${target_cases[@]}"; do
                IFS=':' read -r t_days t_miles t_receipts t_expected <<< "$target"
                
                # Compare with tolerance for floating point
                if [ "$days" == "$t_days" ] && [ "$miles" == "$t_miles" ]; then
                    receipts_diff=$(echo "scale=2; $receipts - $t_receipts" | bc)
                    receipts_diff=${receipts_diff#-}  # absolute value
                    expected_diff=$(echo "scale=2; $expected - $t_expected" | bc)
                    expected_diff=${expected_diff#-}  # absolute value
                    
                    # Check if differences are small (within 0.01)
                    if (( $(echo "$receipts_diff < 0.01" | bc -l) )) && (( $(echo "$expected_diff < 0.01" | bc -l) )); then
                        echo "FOUND Case $case_index: $days days, $miles miles, \$$receipts receipts"
                        echo "  Expected: \$$expected"
                        
                        # Calculate ratios and per-day amounts
                        receipts_to_expected=$(echo "scale=2; $receipts / $expected" | bc)
                        expected_per_day=$(echo "scale=2; $expected / $days" | bc)
                        
                        echo "  Expected per day: \$$expected_per_day"
                        echo "  Receipts/Expected ratio: $receipts_to_expected"
                        echo "  Analysis: Expected is $(echo "scale=1; $receipts_to_expected" | bc)x LOWER than receipts!"
                        echo ""
                        
                        # Calculate what your algorithm would produce
                        your_result=$(./run.sh $days $miles $receipts)
                        error=$(echo "scale=2; $your_result - $expected" | bc)
                        echo "  Your algorithm result: \$$your_result"
                        echo "  Error: \$$error"
                        echo ""
                        
                        found_count=$((found_count + 1))
                        break
                    fi
                fi
            done
            
            case_index=$((case_index + 1))
        fi
    done < public_cases.json
    
    echo "Found $found_count out of 5 target cases"
    echo ""
}

# Function to analyze high-receipt cases
analyze_high_receipts() {
    echo "=== ANALYZING HIGH-RECEIPT CASES (>\$1000) ==="
    echo ""
    
    case_index=0
    high_receipt_count=0
    
    while IFS= read -r line; do
        if [[ $line == *"trip_duration_days"* ]]; then
            days=$(echo "$line" | grep -o '[0-9]\+')
        elif [[ $line == *"miles_traveled"* ]]; then
            miles=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        elif [[ $line == *"total_receipts_amount"* ]]; then
            receipts=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        elif [[ $line == *"expected_output"* ]]; then
            expected=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
            
            # Check if receipts > 1000
            if (( $(echo "$receipts > 1000" | bc -l) )); then
                expected_per_day=$(echo "scale=2; $expected / $days" | bc)
                receipts_to_expected=$(echo "scale=2; $receipts / $expected" | bc)
                
                echo "Case $case_index: $days days, $miles miles, \$$receipts receipts"
                echo "  Expected: \$$expected (\$$expected_per_day/day)"
                echo "  Receipts/Expected ratio: $receipts_to_expected"
                echo ""
                
                high_receipt_count=$((high_receipt_count + 1))
                
                # Stop after showing 15 cases
                if [ $high_receipt_count -ge 15 ]; then
                    break
                fi
            fi
            
            case_index=$((case_index + 1))
        fi
    done < public_cases.json
    
    echo "Found $high_receipt_count high-receipt cases"
    echo ""
}

# Function to analyze long trips
analyze_long_trips() {
    echo "=== ANALYZING LONG TRIPS (8+ days) ==="
    echo ""
    
    case_index=0
    long_trip_count=0
    
    while IFS= read -r line; do
        if [[ $line == *"trip_duration_days"* ]]; then
            days=$(echo "$line" | grep -o '[0-9]\+')
        elif [[ $line == *"miles_traveled"* ]]; then
            miles=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        elif [[ $line == *"total_receipts_amount"* ]]; then
            receipts=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        elif [[ $line == *"expected_output"* ]]; then
            expected=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
            
            # Check if days >= 8
            if [ "$days" -ge 8 ]; then
                expected_per_day=$(echo "scale=2; $expected / $days" | bc)
                
                echo "Case $case_index: $days days, $miles miles, \$$receipts receipts"
                echo "  Expected: \$$expected (\$$expected_per_day/day)"
                echo ""
                
                long_trip_count=$((long_trip_count + 1))
                
                # Stop after showing 15 cases
                if [ $long_trip_count -ge 15 ]; then
                    break
                fi
            fi
            
            case_index=$((case_index + 1))
        fi
    done < public_cases.json
    
    echo "Found $long_trip_count long-trip cases"
    echo ""
}

# Function to analyze low-receipt cases to understand base logic
analyze_base_logic() {
    echo "=== ANALYZING BASE LOGIC (low receipts < \$50) ==="
    echo ""
    
    case_index=0
    low_receipt_count=0
    
    while IFS= read -r line; do
        if [[ $line == *"trip_duration_days"* ]]; then
            days=$(echo "$line" | grep -o '[0-9]\+')
        elif [[ $line == *"miles_traveled"* ]]; then
            miles=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        elif [[ $line == *"total_receipts_amount"* ]]; then
            receipts=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
        elif [[ $line == *"expected_output"* ]]; then
            expected=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\|[0-9]\+')
            
            # Check if receipts < 50
            if (( $(echo "$receipts < 50" | bc -l) )); then
                expected_per_day=$(echo "scale=2; $expected / $days" | bc)
                
                # Try to calculate implied mileage rate
                remaining_after_receipts=$(echo "scale=2; $expected - $receipts" | bc)
                if [ "$miles" != "0" ]; then
                    implied_mile_rate=$(echo "scale=4; $remaining_after_receipts / $miles" | bc)
                else
                    implied_mile_rate="N/A"
                fi
                
                echo "Case $case_index: $days days, $miles miles, \$$receipts receipts"
                echo "  Expected: \$$expected (\$$expected_per_day/day)"
                echo "  Remaining after receipts: \$$remaining_after_receipts"
                echo "  Implied mile rate: \$$implied_mile_rate/mile"
                echo ""
                
                low_receipt_count=$((low_receipt_count + 1))
                
                # Stop after showing 10 cases
                if [ $low_receipt_count -ge 10 ]; then
                    break
                fi
            fi
            
            case_index=$((case_index + 1))
        fi
    done < public_cases.json
    
    echo "Found $low_receipt_count low-receipt cases"
    echo ""
}

# Main execution
echo "Starting analysis of specific high-error cases..."
echo ""

find_specific_cases
analyze_high_receipts  
analyze_long_trips
analyze_base_logic

echo "=== SUMMARY OF FINDINGS ==="
echo ""
echo "Key observations:"
echo "1. High-receipt cases show expected values MUCH lower than receipts"
echo "2. This suggests there are caps or heavy penalties for high receipts"
echo "3. Long trips may have diminishing per-day rates"
echo "4. The algorithm likely has maximum reimbursement limits"
echo ""