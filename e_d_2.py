#!/usr/bin/env python3
"""
extract_output.py

Reads a large .txt file (one entry per line, format like):
[facebook-usernames] [http] [low] https://mywebsite.com/apps/... ["zz.com/xyz"]

Extracts the text found inside ["..."] on each line, removes duplicates,
sorts the results, and writes them to output.txt (one per line).

Designed to handle files with millions of lines efficiently:
- Streams the file line-by-line (never loads the whole file into memory)
- Uses a single compiled regex for fast matching
- Uses a set for O(1) duplicate checking
- Prints periodic progress so you can monitor long runs

Usage:
    python extract_output.py path/to/file.txt
    (or just run it with no arguments and it will prompt for a path)
"""

import re
import sys
import os
import time

# Matches the content inside a ["..."] bracket, which may hold ONE value
# or SEVERAL comma-separated quoted values, e.g.:
#   ["zz.com/xyz"]                                  -> one value
#   ["a.com/1","a.com/2","a.com/3"]                 -> three values
# The captured group is everything between the first and last quote inside
# the brackets; individual values are then split on the `","` separator.
PATTERN = re.compile(r'\["(.*)"\]')

PROGRESS_EVERY = 500_000  # print a progress update every N lines


def get_input_path():
    """Get the input file path from a command-line argument or user prompt."""
    if len(sys.argv) > 1:
        path = sys.argv[1].strip()
    else:
        path = input("Enter the .txt file name or path: ").strip()

    # Strip accidental surrounding quotes if the user pasted a quoted path
    if len(path) >= 2 and path[0] == path[-1] and path[0] in ('"', "'"):
        path = path[1:-1]

    if not os.path.isfile(path):
        print(f"Error: file not found: {path}")
        sys.exit(1)

    return path


def extract_unique_sorted(input_path):
    """Stream the file, extract bracketed-quoted text, return a sorted list of unique values."""
    results = set()
    total_lines = 0
    matched_lines = 0
    start_time = time.time()

    with open(input_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            total_lines += 1

            match = PATTERN.search(line)
            if match:
                # Split on the separator between quoted values: ","
                for value in match.group(1).split('","'):
                    value = value.strip()
                    if value:
                        results.add(value)
                matched_lines += 1

            if total_lines % PROGRESS_EVERY == 0:
                elapsed = time.time() - start_time
                print(
                    f"  ...processed {total_lines:,} lines "
                    f"({matched_lines:,} matched, {len(results):,} unique so far) "
                    f"[{elapsed:.1f}s elapsed]"
                )

    elapsed = time.time() - start_time
    print(f"Finished reading. Total lines: {total_lines:,}, matched: {matched_lines:,}, "
          f"unique values: {len(results):,} [{elapsed:.1f}s]")

    return sorted(results)


def write_output(values, output_path="output.txt"):
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(values))
        if values:
            f.write("\n")
    print(f"Wrote {len(values):,} unique sorted entries to {output_path}")


def main():
    input_path = get_input_path()
    print(f"Processing: {input_path}")
    values = extract_unique_sorted(input_path)
    write_output(values, "output.txt")


if __name__ == "__main__":
    main()
