# Detailed Multi-Step Approach to Reverse Engineer Legacy Reimbursement System

## Overview
This document outlines a systematic approach to reverse-engineer ACME Corp's 60-year-old travel reimbursement system by analyzing 1,000 historical data points and employee interviews to create a perfect behavioral replica.

## Phase 1: Data Understanding and Initial Analysis

### Step 1.1: Comprehensive Data Exploration
- **Load and examine all 1,000 test cases** from `public_cases.json`
- **Statistical analysis** of input distributions:
  - Trip duration range and frequency distribution
  - Miles traveled patterns and outliers
  - Receipt amounts distribution and spending patterns
- **Output analysis**:
  - Reimbursement amount ranges
  - Identify obvious outliers or anomalies
  - Calculate basic statistics (mean, median, std dev)

### Step 1.2: Interview Insights Extraction
From the employee interviews, extract key behavioral patterns:

**Confirmed Patterns:**
- **Per diem base**: ~$100/day (Lisa from Accounting)
- **5-day trip bonus**: Consistent bonus for 5-day trips (Lisa)
- **Mileage tiers**: First 100 miles at full rate (~$0.58/mile), then decreasing (Lisa)
- **Efficiency rewards**: 180-220 miles/day sweet spot (Kevin)
- **Receipt penalties**: Small amounts (<$50) often penalized
- **Spending thresholds**: Optimal ranges vary by trip length (Kevin)

**Suspected Patterns:**
- **Quarterly variations**: End of Q4 more generous (Marcus)
- **Weekly submission timing**: Tuesday best, Friday worst (Kevin)
- **Rounding artifacts**: Receipts ending in .49/.99 get bonuses (Lisa)
- **Experience factor**: Long-term employees do better (Jennifer)

## Phase 2: Pattern Discovery Through Data Analysis

### Step 2.1: Basic Component Analysis
**Isolate base calculations:**
1. **Per diem component**: Analyze cases with minimal receipts to identify base daily rate
2. **Mileage component**: Examine low-receipt cases to isolate mileage calculations
3. **Receipt processing**: Study how receipt amounts affect total reimbursement

### Step 2.2: Advanced Pattern Recognition
**Multi-dimensional analysis:**
1. **Trip length effects**: Group by days (1,2,3,4,5,6,7,8+ days) and analyze patterns
2. **Efficiency analysis**: Calculate miles/day ratios and correlate with reimbursements
3. **Spending pattern analysis**: Analyze receipts/day ratios across different trip lengths
4. **Interaction effects**: Look for non-linear combinations of factors

### Step 2.3: Threshold and Breakpoint Detection
**Identify decision boundaries:**
1. **Mileage tiers**: Find exact breakpoints where per-mile rates change
2. **Spending caps**: Identify where receipt reimbursement rates decrease
3. **Trip length bonuses/penalties**: Pinpoint optimal trip durations
4. **Efficiency thresholds**: Find the 180-220 miles/day sweet spot

## Phase 3: Algorithm Hypothesis Formation

### Step 3.1: Component-Based Model Development
**Build modular calculation system:**
1. **Base per diem calculation**: `base_perdiem = days * base_rate`
2. **Mileage calculation**: Tiered system with breakpoints
3. **Receipt processing**: Complex curve with penalties/bonuses
4. **Efficiency bonuses**: Miles/day ratio adjustments
5. **Trip length modifiers**: Special handling for 5-day trips, etc.

### Step 3.2: Decision Tree Analysis
**Following Kevin's clustering insights:**
1. **Categorize trips** into 6+ calculation paths:
   - Quick high-mileage trips
   - Long low-mileage trips  
   - Balanced medium trips
   - High-spending short trips
   - Efficient multi-day trips
   - Extended travel (8+ days)

### Step 3.3: Quirk and Bug Integration
**Incorporate known anomalies:**
1. **Rounding bugs**: Extra money for receipts ending in .49/.99
2. **Small receipt penalties**: Worse than zero receipts in some cases
3. **Efficiency paradoxes**: Some high-efficiency trips penalized
4. **Seasonal variations**: Quarterly adjustment factors

## Phase 4: Model Implementation and Testing

### Step 4.1: Prototype Development
**Create initial implementation:**
1. **Copy `run.sh.template` to `run.sh`**
2. **Implement base algorithm** with identified components
3. **Add decision logic** for different trip categories
4. **Include known quirks and edge cases**

### Step 4.2: Iterative Refinement
**Systematic improvement process:**
1. **Run `./eval.sh`** to test against all 1,000 cases
2. **Analyze mismatches**:
   - Group by error magnitude
   - Identify patterns in failed cases
   - Look for missing components or thresholds
3. **Refine algorithm** based on error analysis
4. **Repeat until achieving high accuracy**

### Step 4.3: Edge Case Handling
**Address remaining discrepancies:**
1. **Manual analysis** of worst-performing cases
2. **Cross-reference** with interview insights for missed patterns
3. **Implement special-case logic** for outliers
4. **Fine-tune thresholds** and breakpoints

## Phase 5: Advanced Optimization

### Step 5.1: Statistical Modeling
**If rule-based approach insufficient:**
1. **Feature engineering**: Create derived features (efficiency ratios, spending rates, etc.)
2. **Regression analysis**: Use multiple regression to find optimal coefficients
3. **Machine learning**: Consider decision trees, random forests if needed
4. **Ensemble methods**: Combine multiple approaches

### Step 5.2: Randomness Integration
**Handle systematic variation:**
1. **Identify pseudo-random components** (Kevin's lunar cycle theory)
2. **Test submission timing effects** using available data
3. **Add controlled randomization** if consistent with patterns
4. **Model user history effects** if detectable

## Phase 6: Validation and Finalization

### Step 6.1: Comprehensive Testing
**Final validation process:**
1. **Achieve >95% accuracy** on public test cases (within $1.00)
2. **Achieve >80% exact matches** (within $0.01)
3. **Verify edge case handling** for extreme values
4. **Test performance** requirements (<5 seconds per case)

### Step 6.2: Documentation and Submission
**Prepare final deliverables:**
1. **Document algorithm logic** and decision rules
2. **Explain known quirks** and their implementations
3. **Run `./generate_results.sh`** for private cases
4. **Submit via GitHub** and form completion

## Success Metrics

### Primary Goals:
- **Exact matches**: >80% of cases within $0.01
- **Close matches**: >95% of cases within $1.00
- **Average error**: <$0.50 across all test cases

### Implementation Quality:
- **Clean, maintainable code** in `run.sh`
- **Fast execution** (<5 seconds per case)
- **No external dependencies**
- **Handles all edge cases** gracefully

## Risk Mitigation

### Common Pitfalls:
1. **Over-fitting** to public data - validate logic against interview insights
2. **Missing interaction effects** - test all factor combinations
3. **Ignoring historical bugs** - preserve known quirks even if illogical
4. **Threshold precision** - fine-tune breakpoints to exact values

### Contingency Plans:
1. **If rule-based fails**: Fall back to statistical modeling
2. **If accuracy insufficient**: Add more granular decision trees
3. **If performance issues**: Optimize algorithm efficiency
4. **If edge cases fail**: Add special-case handling logic

This systematic approach leverages both the quantitative data analysis and qualitative insights from employee interviews to build a comprehensive understanding of the legacy system's behavior, ensuring the highest possible fidelity in replication.