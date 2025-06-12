#!/usr/bin/env python3

import json

def find_specific_cases():
    """Find the specific cases mentioned by the user"""
    
    # Load the test cases
    with open('public_cases.json', 'r') as f:
        cases = json.load(f)
    
    # Define the target cases with their characteristics
    target_cases = [
        {"days": 8, "miles": 795, "receipts": 1645.99, "expected": 644.69},
        {"days": 14, "miles": 481, "receipts": 939.99, "expected": 877.17},
        {"days": 4, "miles": 69, "receipts": 2321.49, "expected": 322.00},
        {"days": 8, "miles": 482, "receipts": 1411.49, "expected": 631.81},
        {"days": 11, "miles": 740, "receipts": 1171.99, "expected": 902.09}
    ]
    
    found_cases = []
    
    for i, case in enumerate(cases):
        input_data = case['input']
        expected = case['expected_output']
        
        # Check if this matches any of our target cases
        for target in target_cases:
            if (input_data['trip_duration_days'] == target['days'] and 
                input_data['miles_traveled'] == target['miles'] and 
                abs(input_data['total_receipts_amount'] - target['receipts']) < 0.01 and
                abs(expected - target['expected']) < 0.01):
                
                found_cases.append({
                    'index': i,
                    'case': case,
                    'target': target
                })
                print(f"Found case {i}: {target['days']} days, {target['miles']} miles, ${target['receipts']:.2f} receipts")
                print(f"  Expected: ${expected:.2f}")
                print(f"  Receipts to expected ratio: {target['receipts']/expected:.2f}")
                print()
                break
    
    return found_cases

def analyze_patterns(cases_data):
    """Analyze patterns in high-receipt cases"""
    
    print("=== ANALYZING HIGH-RECEIPT CASES (>$1000) ===")
    high_receipt_cases = []
    
    for i, case in enumerate(cases_data):
        input_data = case['input']
        expected = case['expected_output']
        receipts = input_data['total_receipts_amount']
        
        if receipts > 1000:
            days = input_data['trip_duration_days']
            miles = input_data['miles_traveled']
            
            # Calculate some ratios
            expected_per_day = expected / days
            receipts_to_expected = receipts / expected
            
            high_receipt_cases.append({
                'index': i,
                'days': days,
                'miles': miles,
                'receipts': receipts,
                'expected': expected,
                'expected_per_day': expected_per_day,
                'receipts_to_expected': receipts_to_expected
            })
    
    # Sort by receipts amount
    high_receipt_cases.sort(key=lambda x: x['receipts'], reverse=True)
    
    print(f"Found {len(high_receipt_cases)} cases with receipts > $1000")
    print()
    
    for case in high_receipt_cases[:20]:  # Show top 20
        print(f"Case {case['index']}: {case['days']} days, {case['miles']} miles, ${case['receipts']:.2f} receipts")
        print(f"  Expected: ${case['expected']:.2f} (${case['expected_per_day']:.2f}/day)")
        print(f"  Receipts/Expected ratio: {case['receipts_to_expected']:.2f}")
        print()
    
    return high_receipt_cases

def analyze_long_trips(cases_data):
    """Analyze patterns in long trips (8+ days)"""
    
    print("\n=== ANALYZING LONG TRIPS (8+ days) ===")
    long_trip_cases = []
    
    for i, case in enumerate(cases_data):
        input_data = case['input']
        expected = case['expected_output']
        days = input_data['trip_duration_days']
        
        if days >= 8:
            miles = input_data['miles_traveled']
            receipts = input_data['total_receipts_amount']
            
            expected_per_day = expected / days
            
            long_trip_cases.append({
                'index': i,
                'days': days,
                'miles': miles,
                'receipts': receipts,
                'expected': expected,
                'expected_per_day': expected_per_day
            })
    
    # Sort by days
    long_trip_cases.sort(key=lambda x: x['days'], reverse=True)
    
    print(f"Found {len(long_trip_cases)} cases with 8+ days")
    print()
    
    for case in long_trip_cases[:20]:  # Show top 20
        print(f"Case {case['index']}: {case['days']} days, {case['miles']} miles, ${case['receipts']:.2f} receipts")
        print(f"  Expected: ${case['expected']:.2f} (${case['expected_per_day']:.2f}/day)")
        print()
    
    return long_trip_cases

def reverse_engineer_logic(cases_data):
    """Try to reverse engineer the logic from patterns"""
    
    print("\n=== REVERSE ENGINEERING LOGIC ===")
    
    # Let's look at some basic cases first to understand the base logic
    simple_cases = []
    
    for i, case in enumerate(cases_data[:100]):  # First 100 cases
        input_data = case['input']
        expected = case['expected_output']
        
        days = input_data['trip_duration_days']
        miles = input_data['miles_traveled']
        receipts = input_data['total_receipts_amount']
        
        if receipts < 100:  # Low receipt cases to understand base logic
            expected_per_day = expected / days
            miles_rate = (expected - receipts) / miles if miles > 0 else 0
            
            simple_cases.append({
                'index': i,
                'days': days,
                'miles': miles,
                'receipts': receipts,
                'expected': expected,
                'expected_per_day': expected_per_day,
                'miles_rate': miles_rate
            })
    
    print("Sample low-receipt cases:")
    for case in simple_cases[:10]:
        print(f"Case {case['index']}: {case['days']} days, {case['miles']} miles, ${case['receipts']:.2f} receipts")
        print(f"  Expected: ${case['expected']:.2f} (${case['expected_per_day']:.2f}/day)")
        print(f"  Implied miles rate: ${case['miles_rate']:.4f}/mile")
        print()

if __name__ == "__main__":
    # Load data
    with open('public_cases.json', 'r') as f:
        cases_data = json.load(f)
    
    print(f"Loaded {len(cases_data)} test cases")
    print()
    
    # Find the specific cases mentioned
    found_cases = find_specific_cases()
    
    # Analyze patterns
    high_receipt_cases = analyze_patterns(cases_data)
    long_trip_cases = analyze_long_trips(cases_data)
    reverse_engineer_logic(cases_data)