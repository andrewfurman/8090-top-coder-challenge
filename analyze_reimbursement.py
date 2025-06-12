#!/usr/bin/env python3
"""
Comprehensive analysis of the reimbursement system based on public_cases.json
"""

import json
import numpy as np
import pandas as pd
from collections import defaultdict
import math

def load_data():
    """Load and parse the public cases data"""
    with open('/home/runner/workspace/public_cases.json', 'r') as f:
        data = json.load(f)
    
    # Convert to DataFrame for easier analysis
    inputs = []
    outputs = []
    
    for case in data:
        inputs.append(case['input'])
        outputs.append(case['expected_output'])
    
    df = pd.DataFrame(inputs)
    df['reimbursement'] = outputs
    
    return df

def basic_statistics(df):
    """Calculate basic statistics for all variables"""
    print("=== BASIC STATISTICS ===")
    print(f"Total cases: {len(df)}")
    print("\nInput Variables:")
    print(df[['trip_duration_days', 'miles_traveled', 'total_receipts_amount']].describe())
    print("\nReimbursement Output:")
    print(df['reimbursement'].describe())
    print()

def analyze_per_diem_patterns(df):
    """Analyze base per diem rates and patterns"""
    print("=== PER DIEM ANALYSIS ===")
    
    # Look at cases with minimal miles and receipts to isolate per diem
    minimal_cases = df[(df['miles_traveled'] <= 10) & (df['total_receipts_amount'] <= 5)]
    
    if len(minimal_cases) > 0:
        print("Cases with minimal miles and receipts (isolating per diem):")
        for _, row in minimal_cases.head(10).iterrows():
            per_day = row['reimbursement'] / row['trip_duration_days']
            print(f"Days: {row['trip_duration_days']}, Miles: {row['miles_traveled']}, "
                  f"Receipts: ${row['total_receipts_amount']:.2f}, "
                  f"Total: ${row['reimbursement']:.2f}, Per day: ${per_day:.2f}")
    
    # Analyze per-day rates by trip duration
    print("\nPer-day rates by trip duration:")
    for days in sorted(df['trip_duration_days'].unique()):
        day_cases = df[df['trip_duration_days'] == days]
        avg_per_day = day_cases['reimbursement'].mean() / days
        print(f"{days} days: Average ${avg_per_day:.2f}/day")
    
    print()

def analyze_5day_bonus(df):
    """Analyze 5-day trip bonus pattern"""
    print("=== 5-DAY TRIP BONUS ANALYSIS ===")
    
    # Compare 5-day trips vs others
    five_day = df[df['trip_duration_days'] == 5]
    other_days = df[df['trip_duration_days'] != 5]
    
    if len(five_day) > 0:
        print(f"5-day trips: {len(five_day)} cases")
        print(f"Average 5-day reimbursement: ${five_day['reimbursement'].mean():.2f}")
        print(f"Average per day for 5-day trips: ${five_day['reimbursement'].mean() / 5:.2f}")
        
        # Look for patterns by comparing similar trips
        print("\nSample 5-day trips:")
        for _, row in five_day.head(5).iterrows():
            print(f"Miles: {row['miles_traveled']}, Receipts: ${row['total_receipts_amount']:.2f}, "
                  f"Total: ${row['reimbursement']:.2f}")
    
    print()

def analyze_mileage_tiers(df):
    """Analyze mileage tier effects"""
    print("=== MILEAGE TIER ANALYSIS ===")
    
    # Group by mileage ranges
    df['miles_range'] = pd.cut(df['miles_traveled'], 
                               bins=[0, 50, 100, 150, 200, 250, 300, float('inf')],
                               labels=['0-50', '51-100', '101-150', '151-200', '201-250', '251-300', '300+'])
    
    print("Reimbursement by mileage ranges:")
    for range_label in ['0-50', '51-100', '101-150', '151-200', '201-250', '251-300', '300+']:
        range_data = df[df['miles_range'] == range_label]
        if len(range_data) > 0:
            avg_reimb = range_data['reimbursement'].mean()
            avg_per_mile = avg_reimb / range_data['miles_traveled'].mean() if range_data['miles_traveled'].mean() > 0 else 0
            print(f"{range_label} miles: {len(range_data)} cases, Avg: ${avg_reimb:.2f}, $/mile: ${avg_per_mile:.3f}")
    
    # Look specifically at the 100-mile breakpoint
    print("\nAnalyzing 100-mile breakpoint:")
    under_100 = df[df['miles_traveled'] <= 100]
    over_100 = df[df['miles_traveled'] > 100]
    
    print(f"Under 100 miles: {len(under_100)} cases, avg reimbursement: ${under_100['reimbursement'].mean():.2f}")
    print(f"Over 100 miles: {len(over_100)} cases, avg reimbursement: ${over_100['reimbursement'].mean():.2f}")
    
    print()

def analyze_efficiency_bonus(df):
    """Analyze efficiency bonus patterns (180-220 miles/day)"""
    print("=== EFFICIENCY BONUS ANALYSIS ===")
    
    # Calculate miles per day
    df['miles_per_day'] = df['miles_traveled'] / df['trip_duration_days']
    
    # Define efficiency ranges
    df['efficiency_range'] = pd.cut(df['miles_per_day'],
                                    bins=[0, 100, 150, 180, 220, 250, float('inf')],
                                    labels=['0-100', '101-150', '151-180', '181-220', '221-250', '250+'])
    
    print("Reimbursement by efficiency (miles/day):")
    for range_label in ['0-100', '101-150', '151-180', '181-220', '221-250', '250+']:
        range_data = df[df['efficiency_range'] == range_label]
        if len(range_data) > 0:
            avg_reimb = range_data['reimbursement'].mean()
            print(f"{range_label} miles/day: {len(range_data)} cases, Avg reimbursement: ${avg_reimb:.2f}")
    
    # Focus on the sweet spot
    sweet_spot = df[(df['miles_per_day'] >= 180) & (df['miles_per_day'] <= 220)]
    if len(sweet_spot) > 0:
        print(f"\nSweet spot (180-220 miles/day): {len(sweet_spot)} cases")
        print(f"Average reimbursement: ${sweet_spot['reimbursement'].mean():.2f}")
        print("Sample cases:")
        for _, row in sweet_spot.head(5).iterrows():
            print(f"  {row['miles_per_day']:.1f} miles/day, Total: ${row['reimbursement']:.2f}")
    
    print()

def analyze_receipt_patterns(df):
    """Analyze receipt processing patterns"""
    print("=== RECEIPT PROCESSING ANALYSIS ===")
    
    # Group by receipt amounts
    df['receipt_range'] = pd.cut(df['total_receipts_amount'],
                                 bins=[0, 5, 10, 20, 50, 100, float('inf')],
                                 labels=['0-5', '6-10', '11-20', '21-50', '51-100', '100+'])
    
    print("Reimbursement by receipt amounts:")
    for range_label in ['0-5', '6-10', '11-20', '21-50', '51-100', '100+']:
        range_data = df[df['receipt_range'] == range_label]
        if len(range_data) > 0:
            avg_reimb = range_data['reimbursement'].mean()
            print(f"${range_label}: {len(range_data)} cases, Avg reimbursement: ${avg_reimb:.2f}")
    
    # Look for small receipt penalties
    small_receipts = df[df['total_receipts_amount'] <= 5]
    larger_receipts = df[df['total_receipts_amount'] > 5]
    
    print(f"\nSmall receipts (≤$5): {len(small_receipts)} cases")
    print(f"Larger receipts (>$5): {len(larger_receipts)} cases")
    
    print()

def find_breakpoints_and_thresholds(df):
    """Find specific breakpoints and thresholds"""
    print("=== BREAKPOINTS AND THRESHOLDS ===")
    
    # Mileage breakpoints
    print("Analyzing mileage breakpoints:")
    mileage_points = [50, 75, 100, 125, 150, 200, 250]
    for point in mileage_points:
        below = df[df['miles_traveled'] < point]['reimbursement'].mean()
        above = df[df['miles_traveled'] >= point]['reimbursement'].mean()
        diff = above - below
        count_below = len(df[df['miles_traveled'] < point])
        count_above = len(df[df['miles_traveled'] >= point])
        print(f"  {point} miles: Below=${below:.2f} ({count_below}), Above=${above:.2f} ({count_above}), Diff=${diff:.2f}")
    
    # Trip length breakpoints
    print("\nTrip length analysis:")
    for days in sorted(df['trip_duration_days'].unique()):
        day_data = df[df['trip_duration_days'] == days]
        avg_reimb = day_data['reimbursement'].mean()
        avg_per_day = avg_reimb / days
        print(f"  {days} days: {len(day_data)} cases, Avg: ${avg_reimb:.2f}, Per day: ${avg_per_day:.2f}")
    
    print()

def reverse_engineer_calculation(df):
    """Attempt to reverse engineer the calculation components"""
    print("=== REVERSE ENGINEERING CALCULATION COMPONENTS ===")
    
    # Try to identify base components
    # Start with simple cases
    simple_cases = df[(df['miles_traveled'] <= 50) & (df['total_receipts_amount'] <= 10) & (df['trip_duration_days'] <= 3)]
    
    print("Analyzing simple cases to identify base components:")
    print("Days | Miles | Receipts | Total | Per Day | Per Mile | Analysis")
    print("-" * 80)
    
    for _, row in simple_cases.head(20).iterrows():
        days = row['trip_duration_days']
        miles = row['miles_traveled']
        receipts = row['total_receipts_amount']
        total = row['reimbursement']
        per_day = total / days
        per_mile = total / miles if miles > 0 else 0
        
        # Try to decompose
        base_per_day = 100  # Assumed base
        expected_base = base_per_day * days
        remaining = total - expected_base
        
        print(f"{days:4d} | {miles:5.0f} | ${receipts:7.2f} | ${total:6.2f} | ${per_day:6.2f} | ${per_mile:7.3f} | Remaining: ${remaining:.2f}")
    
    # Try different base rates
    print("\nTesting different base per diem rates:")
    base_rates = [90, 95, 100, 105, 110]
    
    for base_rate in base_rates:
        errors = []
        for _, row in simple_cases.iterrows():
            predicted_base = base_rate * row['trip_duration_days']
            actual = row['reimbursement']
            error = abs(actual - predicted_base)
            errors.append(error)
        
        avg_error = np.mean(errors)
        print(f"  Base rate ${base_rate}/day: Average error = ${avg_error:.2f}")
    
    print()

def detailed_pattern_analysis(df):
    """More detailed pattern analysis"""
    print("=== DETAILED PATTERN ANALYSIS ===")
    
    # Look for specific patterns mentioned in interviews
    print("1. Checking for mileage calculation patterns:")
    
    # Sample some cases and try to decompose
    sample_cases = df.sample(10, random_state=42)
    
    for _, row in sample_cases.iterrows():
        days = row['trip_duration_days']
        miles = row['miles_traveled']
        receipts = row['total_receipts_amount']
        total = row['reimbursement']
        
        # Try different decompositions
        base_100 = 100 * days
        remaining_after_base = total - base_100
        
        print(f"Case: {days}d, {miles}mi, ${receipts:.2f}rec → ${total:.2f}")
        print(f"  If base = $100/day: ${base_100:.2f}, Remaining: ${remaining_after_base:.2f}")
        
        if miles > 0:
            remaining_per_mile = remaining_after_base / miles
            print(f"  Remaining per mile: ${remaining_per_mile:.3f}")
        
        if miles <= 100:
            print(f"  Miles ≤ 100: Could be ${remaining_after_base/miles:.3f}/mile" if miles > 0 else "")
        else:
            first_100_value = 100 * 0.65  # Assume $0.65 for first 100
            remaining_miles = miles - 100
            if remaining_miles > 0:
                remaining_value = remaining_after_base - first_100_value
                rate_over_100 = remaining_value / remaining_miles
                print(f"  If first 100mi @ $0.65: ${first_100_value:.2f}, remaining {remaining_miles}mi @ ${rate_over_100:.3f}/mi")
        
        print()

def main():
    """Main analysis function"""
    print("REIMBURSEMENT SYSTEM ANALYSIS")
    print("=" * 50)
    
    # Load data
    df = load_data()
    
    # Run all analyses
    basic_statistics(df)
    analyze_per_diem_patterns(df)
    analyze_5day_bonus(df)
    analyze_mileage_tiers(df)
    analyze_efficiency_bonus(df)
    analyze_receipt_patterns(df)
    find_breakpoints_and_thresholds(df)
    reverse_engineer_calculation(df)
    detailed_pattern_analysis(df)
    
    print("Analysis complete!")

if __name__ == "__main__":
    main()