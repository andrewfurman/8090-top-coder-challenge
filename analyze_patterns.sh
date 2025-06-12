#!/bin/bash

echo "REIMBURSEMENT SYSTEM ANALYSIS"
echo "=================================================="

# Extract data using jq for analysis
echo "=== BASIC STATISTICS ==="

# Count total cases
total_cases=$(jq 'length' public_cases.json)
echo "Total cases: $total_cases"

# Basic statistics for inputs
echo ""
echo "Trip Duration (days):"
jq -r '.[].input.trip_duration_days' public_cases.json | sort -n | uniq -c | head -10

echo ""
echo "Miles Traveled ranges:"
jq -r '.[].input.miles_traveled' public_cases.json | awk '
{
    if ($1 <= 50) count_0_50++
    else if ($1 <= 100) count_51_100++
    else if ($1 <= 150) count_101_150++
    else if ($1 <= 200) count_151_200++
    else if ($1 <= 250) count_201_250++
    else count_250_plus++
    total++
}
END {
    print "0-50 miles:", count_0_50+0
    print "51-100 miles:", count_51_100+0
    print "101-150 miles:", count_101_150+0
    print "151-200 miles:", count_151_200+0
    print "201-250 miles:", count_201_250+0
    print "250+ miles:", count_250_plus+0
}'

echo ""
echo "Receipts ranges:"
jq -r '.[].input.total_receipts_amount' public_cases.json | awk '
{
    if ($1 <= 5) count_0_5++
    else if ($1 <= 10) count_6_10++
    else if ($1 <= 20) count_11_20++
    else if ($1 <= 50) count_21_50++
    else count_50_plus++
    total++
}
END {
    print "$0-5:", count_0_5+0
    print "$6-10:", count_6_10+0
    print "$11-20:", count_11_20+0
    print "$21-50:", count_21_50+0
    print "$50+:", count_50_plus+0
}'

echo ""
echo "=== ANALYZING SIMPLE CASES FOR BASE PATTERNS ==="

# Look for simple cases with low miles and receipts
echo "Cases with ≤50 miles and ≤$10 receipts (isolating base per diem):"
jq -r '.[] | select(.input.miles_traveled <= 50 and .input.total_receipts_amount <= 10) | 
[.input.trip_duration_days, .input.miles_traveled, .input.total_receipts_amount, .expected_output] | @csv' public_cases.json | 
head -20 | awk -F, '
{
    days = $1
    miles = $2
    receipts = $3
    total = $4
    per_day = total / days
    printf "%s days, %s miles, $%s receipts → $%s total (%.2f/day)\n", days, miles, receipts, total, per_day
}'

echo ""
echo "=== ANALYZING 5-DAY TRIPS ==="

# Count and analyze 5-day trips
five_day_count=$(jq '[.[] | select(.input.trip_duration_days == 5)] | length' public_cases.json)
echo "Number of 5-day trips: $five_day_count"

if [ "$five_day_count" -gt 0 ]; then
    echo "Sample 5-day trips:"
    jq -r '.[] | select(.input.trip_duration_days == 5) | 
    [.input.miles_traveled, .input.total_receipts_amount, .expected_output] | @csv' public_cases.json | 
    head -10 | awk -F, '
    {
        miles = $1
        receipts = $2
        total = $3
        per_day = total / 5
        printf "%s miles, $%s receipts → $%s total (%.2f/day)\n", miles, receipts, total, per_day
    }'
fi

echo ""
echo "=== MILEAGE BREAKPOINT ANALYSIS ==="

# Analyze 100-mile breakpoint
echo "Comparing under vs over 100 miles:"

under_100_avg=$(jq '[.[] | select(.input.miles_traveled <= 100) | .expected_output] | add / length' public_cases.json)
over_100_avg=$(jq '[.[] | select(.input.miles_traveled > 100) | .expected_output] | add / length' public_cases.json)
under_100_count=$(jq '[.[] | select(.input.miles_traveled <= 100)] | length' public_cases.json)
over_100_count=$(jq '[.[] | select(.input.miles_traveled > 100)] | length' public_cases.json)

echo "≤100 miles: $under_100_count cases, avg reimbursement: \$$under_100_avg"
echo ">100 miles: $over_100_count cases, avg reimbursement: \$$over_100_avg"

echo ""
echo "=== EFFICIENCY ANALYSIS (Miles per Day) ==="

# Calculate and analyze miles per day patterns
echo "Analyzing efficiency patterns:"
jq -r '.[] | [(.input.miles_traveled / .input.trip_duration_days), .expected_output] | @csv' public_cases.json | 
awk -F, '
{
    mpd = $1
    reimb = $2
    if (mpd >= 180 && mpd <= 220) {
        sweet_spot_total += reimb
        sweet_spot_count++
    }
    if (mpd < 100) {
        low_eff_total += reimb
        low_eff_count++
    } else if (mpd >= 100 && mpd < 180) {
        med_eff_total += reimb
        med_eff_count++
    } else if (mpd > 220) {
        high_eff_total += reimb
        high_eff_count++
    }
}
END {
    if (low_eff_count > 0) printf "Low efficiency (<100 mpd): %d cases, avg $%.2f\n", low_eff_count, low_eff_total/low_eff_count
    if (med_eff_count > 0) printf "Medium efficiency (100-180 mpd): %d cases, avg $%.2f\n", med_eff_count, med_eff_total/med_eff_count
    if (sweet_spot_count > 0) printf "Sweet spot (180-220 mpd): %d cases, avg $%.2f\n", sweet_spot_count, sweet_spot_total/sweet_spot_count
    if (high_eff_count > 0) printf "High efficiency (>220 mpd): %d cases, avg $%.2f\n", high_eff_count, high_eff_total/high_eff_count
}'

echo ""
echo "=== DETAILED CALCULATION REVERSE ENGINEERING ==="

# Try to reverse engineer the formula with specific cases
echo "Analyzing specific cases to identify calculation components:"
echo "Format: Days | Miles | Receipts | Total | Analysis"
echo "------------------------------------------------------------"

jq -r '.[] | select(.input.miles_traveled <= 100 and .input.total_receipts_amount <= 20) | 
[.input.trip_duration_days, .input.miles_traveled, .input.total_receipts_amount, .expected_output] | @csv' public_cases.json | 
head -15 | awk -F, '
{
    days = $1
    miles = $2
    receipts = $3
    total = $4
    
    # Assume base rate of $100/day
    base_100 = days * 100
    remaining = total - base_100
    
    printf "%s | %s | $%s | $%s | Base($100/day)=$%.2f, Remaining=$%.2f", days, miles, receipts, total, base_100, remaining
    
    if (miles > 0) {
        per_mile_remaining = remaining / miles
        printf ", $%.3f/mile", per_mile_remaining
    }
    print ""
}'

echo ""
echo "=== MILEAGE RATE ANALYSIS ==="

# Analyze potential mileage rates
echo "Analyzing potential mileage calculation patterns:"
echo "(Assuming $100/day base, looking at remaining amount per mile)"

jq -r '.[] | select(.input.miles_traveled > 0 and .input.miles_traveled <= 200) | 
[.input.trip_duration_days, .input.miles_traveled, .input.total_receipts_amount, .expected_output] | @csv' public_cases.json | 
awk -F, '
{
    days = $1
    miles = $2
    receipts = $3
    total = $4
    
    # Subtract assumed base
    remaining = total - (days * 100)
    rate_per_mile = remaining / miles
    
    if (miles <= 100) {
        under_100_rates[++under_100_count] = rate_per_mile
        under_100_sum += rate_per_mile
    } else {
        # For over 100 miles, assume first 100 at one rate
        first_100_value = 100 * 0.65  # Assumed rate
        remaining_after_first_100 = remaining - first_100_value
        remaining_miles = miles - 100
        if (remaining_miles > 0) {
            over_100_rate = remaining_after_first_100 / remaining_miles
            over_100_rates[++over_100_count] = over_100_rate
            over_100_sum += over_100_rate
        }
    }
}
END {
    if (under_100_count > 0) {
        printf "First 100 miles - Average rate: $%.3f/mile (%d samples)\n", under_100_sum/under_100_count, under_100_count
    }
    if (over_100_count > 0) {
        printf "Over 100 miles - Average rate: $%.3f/mile (%d samples)\n", over_100_sum/over_100_count, over_100_count
    }
}'

echo ""
echo "Analysis complete!"