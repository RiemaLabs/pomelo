import os
import subprocess
import multiprocessing
from collections import defaultdict
import signal
import time
import csv
from datetime import datetime
import shlex
import tempfile
import re

# Initialize counters and result storage
total_files = 0
execution_failures = 0
verification_failures = 0
successes = 0
timeouts = 0

results = []
folder_stats = defaultdict(list)

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
RESET = '\033[0m'

# Collect all .bs files
bs_files = []
for root, dirs, files in os.walk('benchmark'):
    for file in files:
        if file.endswith('.bs'):
            total_files += 1
            filepath = os.path.join(root, file)
            bs_files.append(filepath)

# Define timeout handler
def timeout_handler(signum, frame):
    raise TimeoutError("Execution timed out")

# Define execution function
def run_file(filepath, no_rewrite):
    filename = os.path.basename(filepath)

    with open(filepath, 'r') as f:
        loc = sum(1 for line in f if line.strip())
    
    if filename.startswith('TO-'):
        return filepath, f'{YELLOW}Timeout{RESET}', 60.0, loc

    cmd = ['racket', 'run.rkt', '--file', filepath, '--solver', 'bitwuzla']
    if no_rewrite:
        cmd.append('--no-rewrite')
    
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_file:
        time_output_path = temp_file.name
    
    time_cmd = ['/usr/bin/time', '-l', '-o', time_output_path]
    full_cmd = time_cmd + cmd

    try:
        process = subprocess.run(full_cmd, capture_output=True, text=True, timeout=60)
        with open(time_output_path, 'r') as f:
            time_output = f.read()
            match = re.search(r'(\d+\.\d+)\s+real', time_output)
            execution_time = float(match.group(1)) if match else 0.0
        
        output = process.stdout
        error = process.stderr
        
        if process.returncode != 0:
            status = f'{RED}Failed{RESET}'
        elif 'Evaluated' in output:
            status = f'{RED}Failed{RESET}'
        else:
            status = f'{GREEN}Successful{RESET}'
    except subprocess.TimeoutExpired:
        status = f'{YELLOW}Timeout{RESET}'
        error = "Execution timed out"
        execution_time = 60.0
    except ValueError as e:
        status = f'{RED}Failed{RESET}'
        error = f"Error reading execution time: {str(e)}"
        execution_time = 0.0
    except Exception as e:
        status = f'{RED}Failed{RESET}'
        error = str(e)
        execution_time = 0.0
    finally:
        if os.path.exists(time_output_path):
            os.remove(time_output_path)

    print('=' * 40)
    print(f'Filename: {filepath}')
    print(f'Status: {status}')
    print(f'Execution time: {execution_time:.2f} seconds')
    print(f'Total Lines of Code (LoC): {loc}')
    if 'Failed' in status or 'Timeout' in status:
        print('Error Message:')
        print(error)
    else:
        print('Output:')
        print(output)
    print('\n')
    
    return filepath, status, execution_time, loc


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Run tests')
    parser.add_argument('--no-rewrite', action='store_true',
                        help='disable automatic stack rewriting')
    parser.add_argument('--single-core', action='store_true',
                        help='use single core for more accurate time measurements')
    args = parser.parse_args()

    if args.single_core:
        results = [run_file(filepath, args.no_rewrite) for filepath in bs_files]
    else:
        with multiprocessing.Pool(processes=24) as pool:
            results = pool.starmap(
                run_file, [(filepath, args.no_rewrite) for filepath in bs_files])

    # Process results
    for filepath, status, execution_time, loc in results:
        # Summarize results
        if 'Successful' in status:
            successes += 1
        elif 'Failed' in status:
            if 'Evaluated' in status:
                verification_failures += 1
            else:
                execution_failures += 1
        elif 'Timeout' in status:
            timeouts += 1
        # Categorize and store results
        folder = os.path.dirname(filepath)
        filename = os.path.basename(filepath)
        folder_stats[folder].append(
            {'filename': filename, 'status': status, 'execution_time': execution_time, 'loc': loc})

    # Print statistics table
    print('=' * 40)
    print('Result Statistics:')
    print('Total Files: {}'.format(total_files))
    print('Execution Successful: {}'.format(successes))
    print('Execution Failed: {}'.format(execution_failures))
    print('Verification Failed: {}'.format(verification_failures))
    print('Execution Timed Out: {}'.format(timeouts))
    print('\n')

    # Print table categorized by folder
    for folder, files in folder_stats.items():
        print('Folder: {}'.format(folder))
        print('{:<50}{:<20}{:<15}{:<10}'.format(
            'Filename', 'Status', 'Execution Time(s)', 'LoC'))
        for file in files:
            print('{:<50}{:<20}{:<15.2f}{:<10}'.format(
                file['filename'], file['status'], file['execution_time'], file['loc']))
        print('\n')

    # Generate timestamp for the filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_filename = f'test_results_{timestamp}.csv'

    # Write results to CSV file
    with open(csv_filename, 'w', newline='') as csvfile:
        fieldnames = ['Folder', 'Filename', 'Status', 'Execution Time(s)', 'LoC']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for folder, files in folder_stats.items():
            for file in files:
                writer.writerow({
                    'Folder': folder,
                    'Filename': file['filename'],
                    'Status': file['status'].replace(GREEN, '').replace(RED, '').replace(YELLOW, '').replace(RESET, ''),
                    'Execution Time(s)': f"{file['execution_time']:.2f}",
                    'LoC': file['loc']
                })

    print(f"Results have been written to {csv_filename}")
