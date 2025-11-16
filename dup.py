def remove_duplicate_lines(input_file, output_file):
    """
    Remove duplicate lines from a file.
    
    :param input_file: Path to the input file.
    :param output_file: Path to the output file where unique lines will be saved.
    """
    try:
        with open(input_file, 'r') as infile:
            lines = infile.readlines()
        
        unique_lines = list(dict.fromkeys(lines))
        
        with open(output_file, 'w') as outfile:
            outfile.writelines(unique_lines)
        
        print(f"Duplicate lines removed. Unique lines saved to {output_file}")
    
    except FileNotFoundError:
        print(f"File {input_file} not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
input_file = 'output.txt'
output_file = 'output1.txt'
remove_duplicate_lines(input_file, output_file)
