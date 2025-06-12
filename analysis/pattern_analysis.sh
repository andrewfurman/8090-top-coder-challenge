#!/bin/bash

echo "=== DETAILED PATTERN ANALYSIS ==="
echo ""

echo "1. SPECIFIC HIGH-ERROR CASES ANALYSIS:"
echo "------------------------------------"

# Analyze the 5 specific cases
declare -a cases=(
    "Case 151: 4 days, 69 miles, \$2321.49 receipts → Expected: \$322.00 (Your: \$1392.94)"
    "Case 366: 11 days, 740 miles, \$1171.99 receipts → Expected: \$902.09 (Your: \$1864.79)"  
    "Case 519: 14 days, 481 miles, \$939.99 receipts → Expected: \$877.17 (Your: \$1949.94)"
    "Case 547: 8 days, 482 miles, \$1411.49 receipts → Expected: \$631.81 (Your: \$1601.49)"
    "Case 683: 8 days, 795 miles, \$1645.99 receipts → Expected: \$644.69 (Your: \$1843.14)"
)

for case in "${cases[@]}"; do
    echo "$case"
done

echo ""
echo "2. KEY INSIGHTS FROM THE HIGH-ERROR CASES:"
echo "-----------------------------------------"

echo "Case 151 (4 days, 69 miles, \$2321.49 → \$322):"
echo "  - Expected per day: \$80.50"
echo "  - Receipts are 7.2x higher than expected reimbursement!"
echo "  - This suggests MASSIVE penalty for high receipts"
echo "  - Your algorithm gives \$1392.94 vs expected \$322 (334% too high)"
echo ""

echo "Case 519 (14 days, 481 miles, \$939.99 → \$877.17):"
echo "  - Expected per day: \$62.65 (VERY low for 14-day trip)"
echo "  - Long trips have severely diminished per-day rates"
echo "  - Your algorithm gives \$1949.94 vs expected \$877.17 (122% too high)"
echo ""

echo "Case 683 (8 days, 795 miles, \$1645.99 → \$644.69):"
echo "  - Expected per day: \$80.58"
echo "  - High mileage + high receipts = major penalty"
echo "  - Receipts 2.55x higher than expected reimbursement"
echo ""

echo "3. RECEIPT PENALTY ANALYSIS:"
echo "---------------------------"

# Let's look at what happens with different receipt levels
echo "Analyzing receipt impact patterns..."

# Test different receipt amounts with same trip (using a known case structure)
test_days=5
test_miles=200

echo "Testing receipt penalties with $test_days days, $test_miles miles:"

for receipts in 50 200 500 1000 1500 2000; do
    result=$(./run.sh $test_days $test_miles $receipts)
    echo "  \$$receipts receipts → \$$result reimbursement"
done

echo ""
echo "4. TRIP LENGTH PENALTY ANALYSIS:"
echo "-------------------------------"

# Test different trip lengths with same basic parameters
test_miles=400
test_receipts=500

echo "Testing trip length penalties with $test_miles miles, \$$test_receipts receipts:"

for days in 1 3 5 8 11 14 20; do
    result=$(./run.sh $days $test_miles $test_receipts)
    per_day=$(echo "scale=2; $result / $days" | bc)
    echo "  $days days → \$$result total (\$$per_day/day)"
done

echo ""
echo "5. REVERSE ENGINEERING ATTEMPT:"
echo "------------------------------"

echo "Based on the specific cases, let's calculate what logic might work:"
echo ""

# Case 151: 4 days, 69 miles, $2321.49 → $322
echo "Case 151 Analysis (4 days, 69 miles, \$2321.49 → \$322):"
base_per_day_151=$(echo "scale=2; 322 / 4" | bc)
echo "  If all reimbursement is per-day: \$${base_per_day_151}/day"
echo "  If receipts fully replaced: Need \$${base_per_day_151}/day base + \$0 receipts"
echo "  If receipts capped at 10%: $(echo "scale=2; 2321.49 * 0.1" | bc) from receipts + $(echo "scale=2; 322 - 2321.49 * 0.1" | bc) from base"
echo ""

# Case 519: 14 days, 481 miles, $939.99 → $877.17  
echo "Case 519 Analysis (14 days, 481 miles, \$939.99 → \$877.17):"
base_per_day_519=$(echo "scale=2; 877.17 / 14" | bc)
echo "  If all reimbursement is per-day: \$${base_per_day_519}/day"
echo "  This is VERY low per-day rate for long trips"
echo ""

echo "6. PROPOSED ALGORITHM FIXES:"
echo "----------------------------"

echo "Based on patterns observed:"
echo ""
echo "A. RECEIPT HANDLING:"
echo "   - Current algorithm adds receipts proportionally"
echo "   - ACTUAL algorithm likely has severe caps or replacement logic"
echo "   - Possible: Receipts over \$X get heavily penalized or capped"
echo "   - Possible: High receipts REPLACE per-diem rather than add to it"
echo ""

echo "B. TRIP LENGTH PENALTIES:"
echo "   - Long trips (14+ days) have very low per-day rates (~\$62/day)"
echo "   - Current algorithm gives ~\$95/day base - this is too high"
echo "   - Need much more aggressive length penalties"
echo ""

echo "C. MILEAGE IMPACT:"
echo "   - High mileage + high receipts seems to compound penalties"
echo "   - Current mileage rates may be too generous"
echo ""

echo "D. SPECIFIC FIXES NEEDED:"
echo "   1. Implement receipt caps (maybe max 10-20% of total)"
echo "   2. Reduce base per-diem rates, especially for long trips"
echo "   3. Add penalty for high-receipt cases"
echo "   4. Consider receipt replacement rather than addition"
echo ""