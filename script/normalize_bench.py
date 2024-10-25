import os


def process_bs_files(folder_path):
    for root, _, filenames in os.walk(folder_path):
        for filename in filenames:
            if filename.endswith('.bs'):
                file_path = os.path.join(root, filename)
                new_lines = []

                with open(file_path, 'r', encoding='utf-8') as file:
                    for line_number, line in enumerate(file, start=1):
                        line = line.strip()
                        if not line:
                            new_lines.append(line)
                            continue

                        tokens = line.split()
                        current_non_op = []
                        current_op_line = []

                        for token in tokens:
                            if token.startswith('OP'):
                                if current_non_op:
                                    new_lines.append(' '.join(current_non_op))
                                    current_non_op = []
                                if current_op_line:
                                    new_lines.append(' '.join(current_op_line))
                                    current_op_line = []
                                current_op_line.append(token)
                            else:
                                if current_op_line:
                                    current_op_line.append(token)
                                else:
                                    current_non_op.append(token)

                        if current_op_line:
                            new_lines.append(' '.join(current_op_line))
                        if current_non_op:
                            new_lines.append(' '.join(current_non_op))

                with open(file_path, 'w', encoding='utf-8') as new_file:
                    for new_line in new_lines:
                        new_file.write(new_line + '\n')

                print(f"Processed file saved as: {file_path}")
                # exit(0)


if __name__ == "__main__":
    folder = os.path.join(os.path.dirname(
        os.path.abspath(__file__)), '../benchmark/')
    process_bs_files(folder)
