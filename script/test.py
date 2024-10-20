import os
import subprocess
import multiprocessing
from collections import defaultdict
import signal
import time
import csv
from datetime import datetime

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
def run_file(filepath):
    filename = os.path.basename(filepath)
    if filename.startswith('TO-'):
        return filepath, f'{YELLOW}Timeout{RESET}', 60.0

    cmd = ['racket', 'run.rkt', '--file', filepath , '--solver', 'bitwuzla']
    start_time = time.time()
    try:
        # Set timeout signal
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(60)  # 60 seconds timeout

        process = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        output = process.stdout
        error = process.stderr
        # Check if execution failed
        if process.returncode != 0:
            status = f'{RED}Failed{RESET}'
        # Check if verification failed
        elif 'Evaluated' in output:
            status = f'{RED}Failed{RESET}'
        else:
            status = f'{GREEN}Successful{RESET}'
    except subprocess.TimeoutExpired:
        status = f'{YELLOW}Timeout{RESET}'
        error = "Execution timed out"
    except TimeoutError:
        status = f'{YELLOW}Timeout{RESET}'
        error = "Execution timed out"
    except Exception as e:
        status = f'{RED}Failed{RESET}'
        error = str(e)
    finally:
        # Cancel timeout signal
        signal.alarm(0)

    execution_time = time.time() - start_time
    
    # Print results
    print('=' * 40)
    print('Filename: {}'.format(filepath))
    print('Status: {}'.format(status))
    print('Execution time: {:.2f} seconds'.format(execution_time))
    if 'Failed' in status or 'Timeout' in status:
        print('Error Message:')
        print(error)
    else:
        print('Output:')
        print(output)
    print('\n')
    return filepath, status, execution_time

if __name__ == '__main__':
    # Parallel execution
    with multiprocessing.Pool(processes=16) as pool:
        results = pool.map(run_file, bs_files)

    # Process results
    for filepath, status, execution_time in results:
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
        folder_stats[folder].append({'filename': filename, 'status': status, 'execution_time': execution_time})

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
        print('{:<50}{:<20}{:<15}'.format('Filename', 'Status', 'Execution Time(s)'))
        for file in files:
            print('{:<50}{:<20}{:<15.2f}'.format(file['filename'], file['status'], file['execution_time']))
        print('\n')

    # Generate timestamp for the filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_filename = f'test_results_{timestamp}.csv'

    # Write results to CSV file
    with open(csv_filename, 'w', newline='') as csvfile:
        fieldnames = ['Folder', 'Filename', 'Status', 'Execution Time(s)']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for folder, files in folder_stats.items():
            for file in files:
                writer.writerow({
                    'Folder': folder,
                    'Filename': file['filename'],
                    'Status': file['status'].replace(GREEN, '').replace(RED, '').replace(YELLOW, '').replace(RESET, ''),
                    'Execution Time(s)': f"{file['execution_time']:.2f}"
                })

    print(f"Results have been written to {csv_filename}")
