def compare_files(file1, file2, output_file):
    # Read lines and strip whitespace
    with open(file1, "r", encoding="utf-8") as f1:
        lines1 = set(line.strip() for line in f1 if line.strip())

    with open(file2, "r", encoding="utf-8") as f2:
        lines2 = set(line.strip() for line in f2 if line.strip())

    # Find differences
    diff = lines1.symmetric_difference(lines2)  # lines in either file but not both

    # Write to output file
    with open(output_file, "w", encoding="utf-8") as out:
        for line in sorted(diff):
            out.write(line + "\n")

    print(f"Differences written to {output_file}")


if __name__ == "__main__":
    compare_files("1.txt", "2.txt", "diff.txt")
