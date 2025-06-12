# CRITICAL ALGORITHM ANALYSIS - High-Error Cases

## Executive Summary

Your algorithm is failing on high-receipt and long-trip cases because it **ADDS** receipts as benefits, while the real algorithm appears to **CAP or PENALIZE** high receipts. Here are the specific findings:

## 1. The 5 High-Error Cases - Detailed Analysis

### Case 151: 4 days, 69 miles, $2321.49 receipts → Expected: $322.00
- **Your result**: $1392.94 (334% too high)
- **Key insight**: Receipts are 7.2x higher than expected reimbursement!
- **Expected per day**: $80.50
- **Critical finding**: Your algorithm with $0 receipts = $456.35, but with $2321.49 receipts expected = $322
- **This means high receipts REDUCE reimbursement by $134.35 (penalty rate: -$0.058 per receipt dollar)**

### Case 519: 14 days, 481 miles, $939.99 receipts → Expected: $877.17  
- **Your result**: $1949.94 (122% too high)
- **Expected per day**: $62.65 (extremely low for 14-day trip)
- **Key insight**: Long trips have severely diminished per-day rates, not $95+ like your algorithm

### Case 683: 8 days, 795 miles, $1645.99 receipts → Expected: $644.69
- **Your result**: $1843.14 (186% too high)  
- **Expected per day**: $80.58
- **Key insight**: High mileage + high receipts compounds the penalty effect

### Case 547: 8 days, 482 miles, $1411.49 receipts → Expected: $631.81
- **Your result**: $1601.49 (153% too high)
- **Receipts/Expected ratio**: 2.23 (receipts much higher than total reimbursement)

### Case 366: 11 days, 740 miles, $1171.99 receipts → Expected: $902.09
- **Your result**: $1864.79 (107% too high)
- **Expected per day**: $82.00 (very low for 11-day trip)

## 2. Pattern Analysis - What's Actually Happening

### Receipt Processing Discovery
- **Your algorithm**: Adds receipts with scaling factors (0.4x to 0.6x)
- **Real algorithm**: Appears to CAP receipts or apply PENALTIES for high amounts

**Evidence from testing different receipt levels:**
```
5 days, 200 miles with varying receipts (your algorithm):
$50 receipts → $720.00 reimbursement  
$1000 receipts → $1085.50 reimbursement
$2000 receipts → $1492.00 reimbursement
```

But Case 151 shows: $2321.49 receipts → only $322 expected (massive penalty)

### Trip Length Analysis
**Your algorithm per-day rates:**
- 1 day: $515/day
- 8 days: $150.68/day  
- 14 days: $123.71/day

**Real algorithm per-day rates (from failed cases):**
- 14 days: $62.65/day (HALF your rate)
- 11 days: $82.00/day  
- 8 days: $80.58/day

### Success Pattern Analysis
- **42 out of 50** early cases succeeded (84% success rate)
- **Average successful case**: 4.4 days, 352 miles, $465 receipts
- **Max receipts in successful cases**: $1817.85
- **Key insight**: Algorithm works well for moderate receipts, fails badly for high receipts

## 3. Reverse Engineering the Real Logic

### Receipt Handling - Two Possible Theories:

**Theory 1: Receipt Cap**
- Receipts above $X get capped (maybe $200-500 max)
- Evidence: Successful cases max out around $1800 receipts

**Theory 2: Receipt Penalty (More Likely)**
- High receipts SUBTRACT from reimbursement instead of adding
- Case 151 math: Base calculation ($456) - Receipt penalty ($134) = Expected ($322)
- Penalty rate: approximately -$0.058 per dollar above threshold

### Per-Diem Rates Need Major Reduction
Your current rates are 50-100% too high for long trips:
- **Your 14-day rate**: $123/day
- **Real 14-day rate**: ~$63/day (50% lower)

## 4. Specific Algorithm Fixes Needed

### Immediate Changes Required:

1. **Receipt Processing Overhaul**
   ```bash
   # Instead of:
   receipt_adjustment=$(echo "scale=2; $receipts * 0.4" | bc)
   
   # Try:
   if (( $(echo "$receipts > 500" | bc -l) )); then
       # Apply penalty for high receipts
       excess=$(echo "scale=2; $receipts - 500" | bc)
       receipt_penalty=$(echo "scale=2; $excess * 0.1" | bc)  # 10% penalty
       receipt_adjustment=$(echo "scale=2; 500 * 0.3 - $receipt_penalty" | bc)
   fi
   ```

2. **Reduce Base Per-Diem Rates**
   ```bash
   # Current rates too high, try:
   if [ "$days" -le 7 ]; then
       base_perdiem=85  # Reduced from 95-108
   elif [ "$days" -le 10 ]; then
       base_perdiem=75  # Reduced from 98  
   else
       base_perdiem=65  # Reduced from 95
   fi
   ```

3. **Implement Receipt Cap Alternative**
   ```bash
   # Cap receipts at reasonable maximum
   if (( $(echo "$receipts > 800" | bc -l) )); then
       effective_receipts=800
   else
       effective_receipts=$receipts
   fi
   ```

## 5. Testing Strategy

Test these specific cases after fixes:
1. Case 151: Should get closer to $322 (currently $1392.94)
2. Case 519: Should get closer to $877.17 (currently $1949.94)  
3. Case 683: Should get closer to $644.69 (currently $1843.14)

## 6. Root Cause Summary

**Your algorithm assumes receipts are always beneficial additions.**
**The real algorithm treats high receipts as caps, penalties, or replacements for per-diem.**

This explains why:
- Low-receipt cases succeed (receipts act as small additions)
- High-receipt cases fail catastrophically (receipts should penalize, not benefit)
- Long trips fail (per-diem rates too generous)

The 60-year-old system likely had strict expense controls that penalized excessive spending rather than rewarding it.