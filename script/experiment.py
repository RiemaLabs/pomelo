import os
import subprocess
from collections import defaultdict
import csv
from datetime import datetime
import re
from tqdm import tqdm

# ANSI color codes for colored terminal output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
RESET = '\033[0m'

TIMEOUT = 20.0


def run_file(filepath, use_bitwuzla=False):
    """
    Executes the given .bs file using Racket and measures execution time.

    Args:
        filepath (str): Path to the .bs file.
        use_bitwuzla (bool): Whether to include the '--solver bitwuzla' argument.

    Returns:
        tuple: (filepath, status, execution_time, loc)
    """
    filename = os.path.basename(filepath)

    # Count the number of words starting with 'OP_'
    with open(filepath, 'r') as f:
        loc = sum(1 for word in f.read().split() if word.startswith('OP_'))

    # If the filename starts with 'TO-', mark it as a timeout
    if filename.startswith('TO-'):
        return filepath, f'{YELLOW}Timeout{RESET}', TIMEOUT, loc

    # Define the command to run
    cmd = ['racket', 'run.rkt', '--file', filepath]
    if use_bitwuzla:
        cmd += ['--solver', 'bitwuzla']

    # Use '/usr/bin/time' to measure execution time and output to stderr
    time_cmd = ['/usr/bin/time', '-f', 'ELAPSED_TIME %e']

    # Combine the time command with the actual command
    full_cmd = time_cmd + cmd

    try:
        # Run the command and capture both stdout and stderr
        process = subprocess.run(
            full_cmd, capture_output=True, text=True, timeout=TIMEOUT
        )

        output = process.stdout
        error = process.stderr

        # Extract the execution time from stderr
        execution_time = 0.0
        match = re.search(r'ELAPSED_TIME (\d+\.\d+)', error)
        if match:
            execution_time = float(match.group(1))

        # Determine the status based on the return code and output
        if process.returncode != 0:
            status = f'{RED}Failed{RESET}'
        elif 'Evaluated' in output:
            status = f'{RED}Failed{RESET}'
        else:
            status = f'{GREEN}Successful{RESET}'

    except subprocess.TimeoutExpired:
        # Handle the timeout scenario
        status = f'{YELLOW}Timeout{RESET}'
        error = "Execution timed out"
        execution_time = TIMEOUT
    except Exception as e:
        # Handle other exceptions
        status = f'{RED}Failed{RESET}'
        error = str(e)
        execution_time = 0.0

    # Return the result
    return filepath, status, execution_time, loc


def collect_bs_files(directory):
    """
    Collects all .bs files from the specified directory, excluding those containing 'inner'.

    Args:
        directory (str): Directory to search for .bs files.

    Returns:
        list: List of paths to .bs files.
    """
    bs_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.bs') and 'inner' not in file:
                bs_files.append(os.path.join(root, file))
    return bs_files


def separate_inv_and_regular(bs_files):
    """
    Separates .bs files into regular and _inv.bs files.

    Args:
        bs_files (list): List of paths to .bs files.

    Returns:
        tuple: (regular_bs_files, inv_bs_files)
    """
    inv_bs_files = []
    regular_bs_files = []

    # Identify _inv.bs files and separate them
    for file in bs_files:
        if file.endswith('_inv.bs'):
            inv_bs_files.append(file)
        else:
            regular_bs_files.append(file)

    return regular_bs_files, inv_bs_files


def process_files(files, use_bitwuzla, desc):
    """
    Processes a list of .bs files by executing them and collecting results.

    Args:
        files (list): List of file paths to process.
        use_bitwuzla (bool): Whether to include the '--solver bitwuzla' argument.
        desc (str): Description for the progress bar.

    Returns:
        tuple: (folder_stats, summary)
    """
    total_files = len(files)
    execution_failures = 0
    verification_failures = 0
    successes = 0
    timeouts = 0

    folder_stats = defaultdict(list)

    for filepath, status, execution_time, loc in tqdm(
        (run_file(filepath, use_bitwuzla=use_bitwuzla) for filepath in files),
        total=total_files,
        desc=desc,
        unit="file"
    ):
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
        folder_stats[folder].append({
            'filename': filename,
            'status': status,
            'execution_time': execution_time,
            'loc': loc
        })

    summary = {
        'Total Files': total_files,
        'Execution Successful': successes,
        'Execution Failed': execution_failures,
        'Verification Failed': verification_failures,
        'Execution Timed Out': timeouts
    }

    return folder_stats, summary


def write_detailed_csv(csv_filename, folder_stats):
    """
    Writes detailed results to a CSV file.

    Args:
        csv_filename (str): Name of the CSV file to write.
        folder_stats (dict): Dictionary containing detailed results categorized by folder.
    """
    with open(csv_filename, 'w', newline='') as csvfile:
        fieldnames = ['Folder', 'Filename',
                      'Status', 'Execution Time(s)', 'LoC']
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


def write_summary_csv(summary_csv, summary):
    """
    Writes summary statistics to a CSV file.

    Args:
        summary_csv (str): Name of the summary CSV file.
        summary (dict): Dictionary containing summary statistics.
    """
    with open(summary_csv, 'w', newline='') as csvfile:
        fieldnames = ['Total Files', 'Execution Successful',
                      'Execution Failed', 'Verification Failed', 'Execution Timed Out']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        writer.writerow(summary)


if __name__ == '__main__':
    import argparse

    # Set up argument parser
    parser = argparse.ArgumentParser(description='Run tests on .bs files')
    parser.add_argument('--directory', type=str, default='benchmark',
                        help='Specify the directory to search for .bs files')
    args = parser.parse_args()

    # Collect all .bs files from the specified directory, excluding 'inner'
    bs_files = collect_bs_files(args.directory)

    # Separate into regular and _inv.bs files
    regular_bs_files, inv_bs_files = separate_inv_and_regular(bs_files)

    # Generate timestamp for filenames
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    # Process CSV1: Regular files without bitwuzla
    if regular_bs_files:
        folder_stats_csv1, summary_csv1 = process_files(
            regular_bs_files, use_bitwuzla=False, desc="Processing CSV1 (No Bitwuzla)"
        )
        csv1_filename = f'test_results_no_bitwuzla_{timestamp}.csv'
        write_detailed_csv(csv1_filename, folder_stats_csv1)
        summary_csv1_filename = f'summary_no_bitwuzla_{timestamp}.csv'
        write_summary_csv(summary_csv1_filename, summary_csv1)
        print(f"CSV1 detailed results written to {csv1_filename}")
        print(f"CSV1 summary written to {summary_csv1_filename}")
    else:
        print("No regular .bs files to process for CSV1.")

    # Process CSV2: Regular files with bitwuzla
    if regular_bs_files:
        folder_stats_csv2, summary_csv2 = process_files(
            regular_bs_files, use_bitwuzla=True, desc="Processing CSV2 (With Bitwuzla)"
        )
        csv2_filename = f'test_results_with_bitwuzla_{timestamp}.csv'
        write_detailed_csv(csv2_filename, folder_stats_csv2)
        summary_csv2_filename = f'summary_with_bitwuzla_{timestamp}.csv'
        write_summary_csv(summary_csv2_filename, summary_csv2)
        print(f"CSV2 detailed results written to {csv2_filename}")
        print(f"CSV2 summary written to {summary_csv2_filename}")
    else:
        print("No regular .bs files to process for CSV2.")

    # Process CSV3: _inv.bs files with bitwuzla
    if inv_bs_files:
        folder_stats_csv3, summary_csv3 = process_files(
            inv_bs_files, use_bitwuzla=True, desc="Processing CSV3 (_inv.bs with Bitwuzla)"
        )
        csv3_filename = f'test_results_inv_with_bitwuzla_{timestamp}.csv'
        write_detailed_csv(csv3_filename, folder_stats_csv3)
        summary_csv3_filename = f'summary_inv_with_bitwuzla_{timestamp}.csv'
        write_summary_csv(summary_csv3_filename, summary_csv3)
        print(f"CSV3 detailed results written to {csv3_filename}")
        print(f"CSV3 summary written to {summary_csv3_filename}")
    else:
        print("No _inv.bs files to process for CSV3.")
