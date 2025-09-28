# config.py

import os

PROJECT_NAME = 'local_pc'
DATASET_PATH = r'C:\Users\acara\Desktop\TFM\00_MNIST_Dataset'
WEIGHTS_AND_BIASES_PATH = 'models'

TRAINING_IMAGES_FILEPATH = r'C:\ring_oscillator_puf\sw\data\mnist_dataset\train-images.idx3-ubyte'
TRAINING_LABELS_FILEPATH = r'C:\ring_oscillator_puf\sw\data\mnist_dataset\train-labels.idx1-ubyte'
TEST_IMAGES_FILEPATH = r'C:\ring_oscillator_puf\sw\data\mnist_dataset\t10k-images.idx3-ubyte'
TEST_LABELS_FILEPATH = r'C:\ring_oscillator_puf\sw\data\mnist_dataset\t10k-labels.idx1-ubyte'

LEARNING_RATE = 0.01
NUM_CLASSES = 10
HIDDEN_SIZES = [512, 56, 128]
INPUT_SIZE = 28 * 28

N_TESTS_PER_LL_APPROACH = 100

LOCKING_METHODS = {
    'bias_circular_shifting': 4,
    'weights_cols_and_rows_circular_shifting': 8,
    'permutation_matrices_rows': 4,
    'permutation_matrices_rows_and_columns': 8,
    'aes_128': 1
}
MAX_SHUFFLE = 200