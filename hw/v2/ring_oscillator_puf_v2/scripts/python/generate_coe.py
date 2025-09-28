#
# generate_coe.py
#
# Generates a .coe file for the ro_map BRAM.
# Maps an LFSR value (0-495) to a pair of unique RO indices (0-31).
#

G_N_ROS_MAIN = 32
LFSR_RANGE = 496
BRAM_DEPTH = 512
BRAM_WIDTH = 10

def get_indices(lfsr_val, n_ros):
    if lfsr_val >= 496:
        return 0, 0

    g, s = 0, 0
    sum_val = n_ros - 2
    current_index = 0
    found = False

    for i in range(n_ros - 1):
        if not found and lfsr_val >= current_index and lfsr_val <= current_index + sum_val:
            g = i
            s = lfsr_val - current_index
            found = True
            break # Exit loop once found
        else:
            current_index = current_index + sum_val + 1
            sum_val = sum_val - 1

    ro0_index = g
    ro1_index = g + s + 1
    return ro0_index, ro1_index


if __name__ == "__main__":
    file_path = "ro_map_init.coe"
    with open(file_path, "w") as f:
        # Write .coe file header
        f.write("MEMORY_INITIALIZATION_RADIX=2;\n")
        f.write("MEMORY_INITIALIZATION_VECTOR=\n")

        # Generate data for each address
        for addr in range(BRAM_DEPTH):
            ro0, ro1 = get_indices(addr, G_N_ROS_MAIN)

            # Format the indices into a 10-bit binary string
            # ro1 is MSB (bits 9-5), ro0 is LSB (bits 4-0)
            binary_str = f"{ro1:05b}{ro0:05b}"

            # Write to file
            f.write(binary_str)
            if addr == BRAM_DEPTH - 1:
                f.write(";")
            else:
                f.write(",\n")

    print(f"Successfully generated '{file_path}' with {BRAM_DEPTH} entries.")