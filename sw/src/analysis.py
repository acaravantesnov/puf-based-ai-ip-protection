import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from mpl_toolkits.mplot3d import Axes3D
from scipy.interpolate import griddata

# ==============================================================================
# 1. ANALYSIS FUNCTIONS
# ==============================================================================

def calculate_intra_hamming_distances(df, column_name, ideal_value):
    """
    Calculates the Hamming distance for each response compared to an ideal value.
    Returns a pandas Series containing the distance for each row.
    """
    responses_str = df[column_name].astype(str)
    
    # Convert strings to numpy arrays of integers for fast comparison
    int_arrays = np.array([list(map(int, r)) for r in responses_str])
    ideal_array = np.array(list(map(int, ideal_value)))
    
    # Calculate Hamming distance for each row using vectorized XOR and sum
    distances = np.sum(int_arrays ^ ideal_array, axis=1)
    
    return pd.Series(distances, index=df.index)

def analyze_bit_proportions(df, column_name):
    '''
    Analyzes bit proportions for a given column of a Pandas Dataframe.
    '''
    series = df[column_name].astype(str)
    zeros_per_row = series.str.count('0')
    ones_per_row = series.str.count('1')
    length_per_row = series.str.len()
    zeroes_proportions_per_row = zeros_per_row / length_per_row
    ones_proportions_per_row = ones_per_row / length_per_row
    total_length = length_per_row.sum()
    zeroes_proportions = zeros_per_row.sum() / total_length
    ones_proportions = ones_per_row.sum() / total_length
    return {
        'zeroes_proportions': zeroes_proportions,
        'ones_proportions': ones_proportions,
        'zeroes_proportions_per_row': zeroes_proportions_per_row,
        'ones_proportions_per_row': ones_proportions_per_row
    }

def convert_binary_to_naturals(bit_string: str, chunk_size: int = 16):
    """
    Converts a binary string into a list of natural numbers.
    """
    if len(bit_string) != 128:
        raise ValueError("Input string must be exactly 128 bits long.")

    natural_values = []
    
    # Iterate through the string in chunks of the specified size
    for i in range(0, len(bit_string), chunk_size):
        # Slice the string to get the current chunk of bits
        bit_chunk = bit_string[i:i + chunk_size]
        
        # Convert the binary string chunk to a base-10 integer
        natural_value = int(bit_chunk, 2)
        
        natural_values.append(natural_value)
        
    return natural_values

def get_ideal_value(df, column_name):
    '''
    Finds the most common bit at each position to create an "ideal" value.
    '''
    series = df[column_name].astype(str)
    series_as_df = series.str.split('', expand=True)
    bits_df = series_as_df.iloc[:, 1:-1]
    ideal_value_list = [bits_df[column].mode()[0] for column in bits_df.columns]
    return "".join(ideal_value_list)

def analyze_bit_stability(df, column_name, ideal_value_str):
    '''
    Analyzes the stability of each bit compared to an ideal value.
    '''
    series = df[column_name].astype(str)
    series_as_df = series.str.split('', expand=True)
    bits_df = series_as_df.iloc[:, 1:-1]
    ideal_value_list = list(ideal_value_str)
    bit_flips = (bits_df != ideal_value_list)
    bit_flips_count = bit_flips.sum(axis=0)
    flip_percentages = bit_flips_count / len(df)
    return flip_percentages.sort_values(ascending=False)

def get_formatted_stability(df, column, ideal_value):
    """
    Analyzes, filters, and formats stability results for unstable bits.
    """
    result = analyze_bit_stability(df, column, ideal_value)
    non_zero_flips = result[result > 0]
    return non_zero_flips

# ==============================================================================
# 2. PLOTTING FUNCTIONS
# ==============================================================================

import pandas as pd
import matplotlib.pyplot as plt

def plot_dual_bit_proportions(df, column1, column2, analyze_func):
    """
    Creates two side-by-side pie charts in a single figure to compare 
    the bit proportions of two different columns.
    """
    # Create a figure and a set of subplots (1 row, 2 columns)
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 7))
    
    # --- Plot 1: First Column ---
    proportions1 = analyze_func(df, column1)
    sizes1 = [proportions1['zeroes_proportions'], proportions1['ones_proportions']]
    labels = 'Zeros', 'Ones'
    
    ax1.pie(sizes1, labels=labels, autopct='%1.1f%%', startangle=90, colors=['#66b3ff','#ff9999'])
    ax1.axis('equal')  # Ensures the pie is drawn as a circle.
    ax1.set_title(f'Bit Proportions for {column1}')
    
    # --- Plot 2: Second Column ---
    proportions2 = analyze_func(df, column2)
    sizes2 = [proportions2['zeroes_proportions'], proportions2['ones_proportions']]
    
    ax2.pie(sizes2, labels=labels, autopct='%1.1f%%', startangle=90, colors=['#66b3ff','#ff9999'])
    ax2.axis('equal')
    ax2.set_title(f'Bit Proportions for {column2}')
    
    # Add a main title for the entire figure
    fig.suptitle('Comparison of Bit Proportions', fontsize=16)
    
    # Adjust layout and display the plot
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.show()
    
def plot_stability_heatmap(df, column_name, ideal_value):
    """
    Creates a heatmap to visualize the stability of each bit across all runs.
    White areas are stable, colored areas are "flips".
    """
    series = df[column_name].astype(str)
    
    # Split into a DataFrame of bits
    bits_df = series.str.split('', expand=True).iloc[:, 1:-1]
    
    # Create a boolean DataFrame of flips (True where bits differ)
    ideal_list = list(ideal_value)
    flips_df = (bits_df != ideal_list)

    # Plotting
    plt.figure(figsize=(15, 8))
    sns.heatmap(flips_df, cmap='viridis', cbar=False)
    plt.title(f'Bit Stability Heatmap for {column_name}')
    plt.xlabel('Bit Position (MSB-based)')
    plt.ylabel('Measurement Run Index')
    plt.show()

def plot_inter_hamming_distribution(df, column_name, samples=10000):
    """
    Calculates and plots the distribution of Hamming distances between
    random pairs of responses to evaluate uniqueness.
    """
    responses = df[column_name].astype(str).to_numpy()
    num_responses = len(responses)
    bit_length = len(responses[0])

    max_pairs = num_responses * (num_responses - 1) // 2
    if samples > max_pairs:
        samples = max_pairs

    # Convert strings to numpy arrays of integers for fast comparison
    int_arrays = np.array([list(map(int, r)) for r in responses])
    
    distances = []
    for _ in range(samples):
        # Choose two different random indices
        idx1, idx2 = np.random.choice(num_responses, 2, replace=False)
        
        # Calculate Hamming distance using vectorized XOR and sum
        distance = np.sum(int_arrays[idx1] ^ int_arrays[idx2])
        distances.append(distance)
        
    # Plotting the histogram
    plt.figure(figsize=(10, 6))
    plt.hist(distances, bins=range(bit_length + 1), density=True, alpha=0.75, label='Measured Distribution')
    
    plt.title(f'Inter-Hamming Distance Distribution for {column_name}')
    plt.xlabel('Hamming Distance')
    plt.ylabel('Probability Density')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.show()

def temperature_plot(df, column_name):
    '''
    Creates and saves a plot showing the evolution of temperature.
    '''
    plt.figure(figsize=(12, 6))
    # Using the DataFrame index directly for the x-axis ensures order
    sns.lineplot(data=df, y=column_name, x=df.index, alpha=0.8)
    plt.title(f'Temperature Evolution for {column_name}')
    plt.xlabel('Sample Index')
    plt.ylabel('Temperature (°C)')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()

def voltage_plot(df, column_name):
    '''
    Creates and saves a plot showing the evolution of vccint.
    '''
    plt.figure(figsize=(12, 6))
    sns.lineplot(data=df, y=column_name, x=df.index, color='orange', alpha=0.8)
    plt.title(f'VCCINT Voltage Evolution for {column_name}')
    plt.xlabel('Sample Index')
    plt.ylabel('Voltage (V)')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()

def plot_unstable_bit_flips(df, column_name, ideal_value):
    """
    Creates and saves a bar chart of the flip percentages for unstable bits.
    """
    stability_results = get_formatted_stability(df, column_name, ideal_value)
    if stability_results.empty:
        print("No unstable bits found!")
        return
    plt.figure(figsize=(15, 7))
    stability_results.plot(kind='bar', color='steelblue')
    plt.title(f'Flip Percentage of Unstable Bits for {column_name}')
    plt.xlabel('Bit Position (from MSB)')
    plt.ylabel('Flip Percentage')
    plt.xticks(rotation=45)
    plt.grid(axis='y', linestyle='--', alpha=0.6)
    plt.tight_layout()
    plt.show()

def plot_flips_vs_environment(df, puf_column, ideal_value, env_column):
    """
    Visualizes the correlation between the number of bit flips (Hamming distance
    from ideal) and an environmental variable (temperature or voltage).
    """
    # Calculate Intra-Hamming distance (number of flips from ideal) for each row
    flips_per_row = calculate_intra_hamming_distances(df, puf_column, ideal_value)

    # Create the plot
    plt.figure(figsize=(10, 8))
    hb = plt.hexbin(x=df[env_column], y=flips_per_row, gridsize=30, cmap='inferno', mincnt=1)

    # Add a color bar
    cb = plt.colorbar(hb)
    cb.set_label('Number of Occurrences')

    plt.title(f'Bit Flips vs. {env_column}')
    plt.xlabel(env_column)
    plt.ylabel('Number of Bit Flips (Hamming Distance from Ideal)')
    plt.grid(True, alpha=0.2)
    plt.tight_layout()
    plt.show()

def plot_environmental_distribution(df, temp_col, volt_col):
    """
    Plots the distribution of temperature and voltage to show the experimental conditions.
    """
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    # Temperature Distribution
    sns.histplot(df[temp_col], kde=True, ax=ax1, color='red', bins=30)
    ax1.set_title(f'Distribution of {temp_col}')
    ax1.set_xlabel('Temperature (°C)')
    ax1.set_ylabel('Frequency')

    # Voltage Distribution
    sns.histplot(df[volt_col], kde=True, ax=ax2, color='blue', bins=30)
    ax2.set_title(f'Distribution of {volt_col}')
    ax2.set_xlabel('Voltage (V)')
    
    fig.suptitle('Distribution of Environmental Conditions', fontsize=16)
    plt.tight_layout(rect=[0, 0, 1, 0.96])
    plt.show()
