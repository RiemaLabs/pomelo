import os
import subprocess
import concurrent.futures
from collections import defaultdict

# Initialize counters and result storage
total_files = 0
execution_failures = 0
verification_failures = 0
successes = 0

results = []
folder_stats = defaultdict(list)

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
RESET = '\033[0m'

# Collect all .bs files
bs_files = []
for root, dirs, files in os.walk('benchmark'):
    for file in files:
        if file.endswith('.bs'):
            total_files += 1
            filepath = os.path.join(root, file)
            bs_files.append(filepath)

# Define execution function
def run_file(filepath):
    cmd = ['racket', 'run.rkt', '--file', filepath]
    try:
        process = subprocess.run(cmd, capture_output=True, text=True)
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
    except Exception as e:
        status = f'{RED}Failed{RESET}'
        error = str(e)
    # Print results
    print('=' * 40)
    print('Filename: {}'.format(filepath))
    print('Status: {}'.format(status))
    if 'Failed' in status:
        print('Error Message:')
        print(error)
    else:
        print('Output:')
        print(output)
    print('\n')
    return filepath, status

# Parallel execution
with concurrent.futures.ThreadPoolExecutor(max_workers=16) as executor:
    future_to_file = {executor.submit(run_file, filepath): filepath for filepath in bs_files}
    for future in concurrent.futures.as_completed(future_to_file):
        filepath = future_to_file[future]
        try:
            filepath, status = future.result()
            # Summarize results
            if 'Successful' in status:
                successes += 1
            elif 'Failed' in status:
                if 'Model' in status:
                    verification_failures += 1
                else:
                    execution_failures += 1
            # Categorize and store results
            folder = os.path.dirname(filepath)
            filename = os.path.basename(filepath)
            folder_stats[folder].append({'filename': filename, 'status': status})
        except Exception as exc:
            print('%r generated an exception: %s' % (filepath, exc))

# Print statistics table
print('=' * 40)
print('Result Statistics:')
print('Total Files: {}'.format(total_files))
print('Execution Successful: {}'.format(successes))
print('Execution Failed: {}'.format(execution_failures))
print('Verification Failed: {}'.format(verification_failures))
print('\n')

# Print table categorized by folder
for folder, files in folder_stats.items():
    print('Folder: {}'.format(folder))
    print('{:<50}{:<10}'.format('Filename', 'Status'))
    for file in files:
        print('{:<50}{:<10}'.format(file['filename'], file['status']))
    print('\n')