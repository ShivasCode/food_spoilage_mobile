# Open the CSV file for reading
file_path = 'transactions.csv'

# Initialize variables for total bet, total payout, and net result
total_bet = 0.0
total_payout = 0.0

# Open and read the CSV file, skipping the first 3 rows (metadata)
with open(file_path, 'r', encoding='utf-8') as file:
    # Skip the first 3 rows (metadata)
    for _ in range(3):
        next(file)

    # Iterate through each line of the CSV file
    for line in file:
        # Strip any extra whitespace and split the line by semicolons
        parts = line.strip().split(';')
        
        # Check if the row contains a Bet or Payout
        if len(parts) >= 10:
            if 'Bet' in parts:
                try:
                    # Extract the amount, which is the 4th from last element
                    amount = float(parts[-3])
                    total_bet += amount
                except (ValueError, IndexError):
                    pass  # In case the conversion to float fails, ignore that row
            elif 'Payout' in parts:
                try:
                    # Extract the amount, which is the 4th from last element
                    amount = float(parts[-3])
                    total_payout += amount
                except (ValueError, IndexError):
                    pass  # In case the conversion to float fails, ignore that row

# Calculate profit or loss
net_result = total_payout - total_bet

# Display the results
print(f"Total Bet Amount: PHP {total_bet}")
print(f"Total Payout Amount: PHP {total_payout}")
print(f"Profit/Loss: PHP {net_result}")
