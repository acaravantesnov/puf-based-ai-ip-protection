import os
import pandas as pd
import numpy as np
from src import analysis as an

def hamming_distance(s1, s2):
    """Calculates the number of differing bits between two strings."""
    return sum(c1 != c2 for c1, c2 in zip(s1, s2))

def string_to_bits(bit_string):
    # Converting each character to an integer
    bits = [int(char) for char in bit_string]
    return pd.Series(bits)

# Section is 'LFSR_Seed' or 'PUF_Response'
def preprocess_df(df, section, num_bits, debug, save_path=None, validity_threshold=20, augmentation_factor=2):

    ## nitial Preparation of Original Data
    # Convert V/T columns to numeric type once at the beginning.
    df[f'{section}_Vccint'] = pd.to_numeric(df[f'{section}_Vccint'])
    df[f'{section}_Temperature'] = pd.to_numeric(df[f'{section}_Temperature'])

    # Get the min/max from the ORIGINAL data to use for augmentation range.
    vccint_min_orig = df[f'{section}_Vccint'].min()
    vccint_max_orig = df[f'{section}_Vccint'].max()
    temp_min_orig = df[f'{section}_Temperature'].min()
    temp_max_orig = df[f'{section}_Temperature'].max()

    # --- Find Ideal Value and Create Smart Labels for Original Data ---
    ideal_value = an.get_ideal_value(df, f'{section}_Value')
    if debug:
        print(f"Ideal Value found: {ideal_value}\n")

    distances = an.calculate_intra_hamming_distances(df, f'{section}_Value', ideal_value)
    df[f'{section}_Target_Value'] = np.where(
        distances <= validity_threshold,
        ideal_value,
        df[f'{section}_Value']
    )

    # --- Augment the dataset with random garbage data ---
    # This explicitly teaches the model the identity task for random inputs.
    num_to_augment = int(len(df) * augmentation_factor)
    if debug:
        print(f"Augmenting dataset with {num_to_augment} samples...\n")

    augmented_rows = []
    
    num_high_flip = num_to_augment // 2  # Use half the budget for highly-flipped samples
    num_random = num_to_augment - num_high_flip # Use the other half for random samples
    
    # High-Flip Augmentation
    ideal_array = np.array(list(map(int, ideal_value)))
    for _ in range(num_high_flip):
        bits_to_flip = np.random.choice(num_bits, size=int(num_bits * 0.3), replace=False)
        
        flipped_array = ideal_array.copy()
        flipped_array[bits_to_flip] = 1 - flipped_array[bits_to_flip] # Flip the bits
        flipped_string = "".join(map(str, flipped_array))
        
        new_row = {
            f'{section}_Value': flipped_string,
            f'{section}_Vccint': np.random.uniform(vccint_min_orig, vccint_max_orig),
            f'{section}_Temperature': np.random.uniform(temp_min_orig, temp_max_orig),
            f'{section}_Target_Value': flipped_string
        }
        augmented_rows.append(new_row)

    # Random Garbage Augmentation
    for _ in range(num_random):
        random_bits = np.random.randint(0, 2, num_bits)
        random_string = "".join(map(str, random_bits))
        
        new_row = {
            f'{section}_Value': random_string,
            f'{section}_Vccint': np.random.uniform(vccint_min_orig, vccint_max_orig),
            f'{section}_Temperature': np.random.uniform(temp_min_orig, temp_max_orig),
            f'{section}_Target_Value': random_string
        }
        augmented_rows.append(new_row)
        
    # Explicitly add all-zero and all-one examples
    num_explicit_garbage = 200 # Add 200 of each

    # All Zeros
    for _ in range(num_explicit_garbage):
        new_row = {
            f'{section}_Value': '0' * num_bits,
            f'{section}_Vccint': np.random.uniform(vccint_min_orig, vccint_max_orig),
            f'{section}_Temperature': np.random.uniform(temp_min_orig, temp_max_orig),
            f'{section}_Target_Value': '0' * num_bits
        }
        augmented_rows.append(new_row)
        
    # All Ones
    for _ in range(num_explicit_garbage):
        new_row = {
            f'{section}_Value': '1' * num_bits,
            f'{section}_Vccint': np.random.uniform(vccint_min_orig, vccint_max_orig),
            f'{section}_Temperature': np.random.uniform(temp_min_orig, temp_max_orig),
            f'{section}_Target_Value': '1' * num_bits
        }
        augmented_rows.append(new_row)

    # Add the new augmented data to the main DataFrame
    if augmented_rows:
        augmented_df = pd.DataFrame(augmented_rows)
        df = pd.concat([df, augmented_df], ignore_index=True)
    
    # Final Normalization on the Complete Dataset
    # Now that the DataFrame is complete (original + augmented), we normalize everything.
    df[f'{section}_Vccint'] = (df[f'{section}_Vccint'] - df[f'{section}_Vccint'].min()) / (df[f'{section}_Vccint'].max() - df[f'{section}_Vccint'].min())
    df[f'{section}_Temperature'] = (df[f'{section}_Temperature'] - df[f'{section}_Temperature'].min()) / (df[f'{section}_Temperature'].max() - df[f'{section}_Temperature'].min())

    # Expand Bitstrings and Split into X and y
    bits_df = df[f'{section}_Value'].apply(string_to_bits).add_prefix(f'{section}_Bit_')
    target_bits_df = df[f'{section}_Target_Value'].apply(string_to_bits).add_prefix(f'{section}_Target_Bit_')

    original_data_df = df[[f'{section}_Vccint', f'{section}_Temperature']]
    final_df = pd.concat([original_data_df, bits_df, target_bits_df], axis=1)
    
    final_df_shuffled = final_df.sample(frac=1).reset_index(drop=True)

    if save_path:
        final_df_shuffled.to_csv(save_path, index=False)
        print(f"Processed data saved to {save_path}")

    feature_columns = [f'{section}_Vccint', f'{section}_Temperature'] + [f'{section}_Bit_{i}' for i in range(num_bits)]
    label_columns = [f'{section}_Target_Bit_{i}' for i in range(num_bits)]
    X = final_df_shuffled[feature_columns].values
    y = final_df_shuffled[label_columns].values
    
    if debug:
        print(f"Final shape of features (X): {X.shape}")
        print(f"Final shape of labels (y): {y.shape}")
    
    return (X, y)

def preprocess_csv(csv_path, debug, save_dir=None, validity_threshold=20):
    
    try:
        df = pd.read_csv(csv_path, dtype=str)
    except FileNotFoundError:
        print(f"Error: {csv_path} not found.")
        import sys
        sys.exit()
    
    (lfsr_seed_df, puf_response_df) = (df.iloc[:, :3].copy(), df.iloc[:, 3:].copy())
    
    lfsr_save_path = None
    puf_save_path = None
    if save_dir:
        os.makedirs(save_dir, exist_ok=True)
        lfsr_save_path = os.path.join(save_dir, 'lfsr_seed_processed_2.csv')
        puf_save_path = os.path.join(save_dir, 'puf_response_processed_2.csv')

    return {
        'lfsr_seed': preprocess_df(
            lfsr_seed_df, 'LFSR_Seed', 9, debug, 
            save_path=lfsr_save_path, 
            validity_threshold=2
        ),
        'puf_response': preprocess_df(
            puf_response_df, 'PUF_Response', 128, debug, 
            save_path=puf_save_path, 
            validity_threshold=validity_threshold
        )
    }
