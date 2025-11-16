import re

def extract_text_in_quotes(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            # Find all occurrences of text within double quotes
            matches = re.findall(r'"(.*?)"', line)
            for match in matches:
                outfile.write(match + '\n')

if __name__ == "__main__":
    input_file = 'input.txt'  # Replace with your input file name
    output_file = 'output.txt'  # Replace with your desired output file name
    extract_text_in_quotes(input_file, output_file)
    print(f"Extracted text has been written to {output_file}")
