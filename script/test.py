import os
import subprocess
import multiprocessing
from collections import defaultdict
import signal

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
    cmd = ['racket', 'run.rkt', '--file', filepath]
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
        elif 'Model' in output:
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

    # Print results
    print('=' * 40)
    print('Filename: {}'.format(filepath))
    print('Status: {}'.format(status))
    if 'Failed' in status or 'Timeout' in status:
        print('Error Message:')
        print(error)
    else:
        print('Output:')
        print(output)
    print('\n')
    return filepath, status

if __name__ == '__main__':
    # Parallel execution
    with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
        results = pool.map(run_file, bs_files)

    # Process results
    for filepath, status in results:
        # Summarize results
        if 'Successful' in status:
            successes += 1
        elif 'Failed' in status:
            if 'Model' in status:
                verification_failures += 1
            else:
                execution_failures += 1
        elif 'Timeout' in status:
            timeouts += 1
        # Categorize and store results
        folder = os.path.dirname(filepath)
        filename = os.path.basename(filepath)
        folder_stats[folder].append({'filename': filename, 'status': status})

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
        print('{:<50}{:<10}'.format('Filename', 'Status'))
        for file in files:
            print('{:<50}{:<10}'.format(file['filename'], file['status']))
        print('\n')
