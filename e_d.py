import re

def extract_text_in_quotes(input_file, temp_file):
    """
    Extract text within double quotes from the input file and write it to a temporary file.

    :param input_file: Path to the input file.
    :param temp_file: Path to the temporary file where extracted text will be saved.
    """
    try:
        with open(input_file, 'r') as infile, open(temp_file, 'w') as outfile:
            for line in infile:
                # Find all occurrences of text within double quotes
                matches = re.findall(r'"(.*?)"', line)
                for match in matches:
                    outfile.write(match + '\n')
        print(f"Extracted text has been written to {temp_file}")
    except FileNotFoundError:
        print(f"File {input_file} not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def remove_duplicate_lines(temp_file, output_file):
    """
    Remove duplicate lines from the temporary file and save unique lines to the output file.

    :param temp_file: Path to the temporary file with extracted text.
    :param output_file: Path to the output file where unique lines will be saved.
    """
    try:
        with open(temp_file, 'r') as infile:
            lines = infile.readlines()

        # Remove duplicates while preserving order
        unique_lines = list(dict.fromkeys(lines))

        with open(output_file, 'w') as outfile:
            outfile.writelines(unique_lines)

        print(f"Duplicate lines removed. Unique lines saved to {output_file}")
    except FileNotFoundError:
        print(f"File {temp_file} not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    # Ask the user for input file via the terminal
    input_file = input("Enter the input file path: ")
    temp_file = 'temp_output.txt'  # Temporary file to store extracted text
    output_file = 'output.txt'  # Final output file with unique lines

    # Step 1: Extract text in quotes
    extract_text_in_quotes(input_file, temp_file)

    # Step 2: Remove duplicate lines from the extracted text
    remove_duplicate_lines(temp_file, output_file)
