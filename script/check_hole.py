#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import shutil
from pathlib import Path
import sys

try:
    from colorama import Fore, Style, init
except ImportError:
    print("The colorama module is not installed. Please run 'pip install colorama' and try again.")
    sys.exit(1)


def main():
    # Initialize colorama for colored output
    init(autoreset=True)

    # Define paths
    script_dir = Path(__file__).parent.resolve()
    total_bench_path = script_dir / 'total_bench.txt'
    benchmark_dir = script_dir.parent / 'benchmark'
    extra_dir = benchmark_dir / 'extra'

    # Check if total_bench.txt exists
    if not total_bench_path.exists():
        print(f"{Fore.RED}total_bench.txt does not exist in {script_dir}")
        sys.exit(1)

    # Read total_bench.txt and collect required files
    required_files = set()

    with total_bench_path.open('r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue  # Skip empty lines
            parts = line.split('\t')
            if len(parts) != 3:
                print(
                    f"{Fore.YELLOW}Warning: Line {line_num} has an incorrect format, skipping.")
                continue
            rel_dir, base_name, flag = parts
            # Construct the base file path
            base_file = benchmark_dir / rel_dir / f"{base_name}.bs"
            required_files.add(base_file.resolve())
            # If flag is 1, also add _inv file
            if flag == '1':
                inv_file = benchmark_dir / rel_dir / f"{base_name}_inv.bs"
                required_files.add(inv_file.resolve())

    # Collect 'TO-' prefixed versions of required non '_inv' files
    to_version_files = set()
    for file_path in required_files:
        if not file_path.name.endswith('_inv.bs'):
            to_file = file_path.parent / f"TO-{file_path.name}"
            to_version_files.add(to_file.resolve())

    # Collect all .bs files in the benchmark directory
    all_bs_files = set(benchmark_dir.rglob('*.bs'))

    # Exclude files already in the extra directory and 'TO-' prefixed files
    extra_dir_files = set(extra_dir.rglob(
        '*.bs')) if extra_dir.exists() else set()
    extra_files = all_bs_files - required_files - to_version_files - extra_dir_files

    # Move unnecessary files to the extra directory
    for file_path in extra_files:
        if file_path.is_file():
            try:
                shutil.move(str(file_path), str(extra_dir / file_path.name))
                print(
                    f"Moved: {file_path.relative_to(benchmark_dir)} -> extra/")
            except Exception as e:
                print(f"{Fore.YELLOW}Warning: Could not move file {file_path}: {e}")

    # Check if required files exist
    for file_path in required_files:
        if not file_path.exists():
            if not file_path.name.endswith('_inv.bs'):
                # Check for 'TO-' prefixed version
                to_file = file_path.parent / f"TO-{file_path.name}"
                if not to_file.exists():
                    relative_path = file_path.relative_to(benchmark_dir)
                    print(f"{Fore.RED}{relative_path} does not exist")
            else:
                # '_inv' files do not have 'TO-' prefix
                relative_path = file_path.relative_to(benchmark_dir)
                print(f"{Fore.RED}{relative_path} does not exist")


if __name__ == "__main__":
    main()
