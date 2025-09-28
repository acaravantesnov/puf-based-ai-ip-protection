import numpy as np
from PIL import Image
import os
from os.path import isdir, join
import struct
from array import array

def relu(x):
    """Applies the ReLU activation function."""
    return np.maximum(0, x)

def softmax(x):
    """Applies the softmax activation function."""
    exp_x = np.exp(x - np.max(x, axis=1, keepdims=True))  # Stabilize softmax
    return exp_x / np.sum(exp_x, axis=1, keepdims=True)

# --- Define the unlock function for weights ---
def unlock_weights(weights_dict, key):
    """
    Reverses the permutations applied to the weight matrices.
    """
    unlocked_weights = {}
    permutation_matrices = []

    # --- Loop 1: Generate and STORE the permutation matrices ---
    for i in range(4):
        W_shape = weights_dict[f"W{i+1}"].shape

        # Generate P_row
        np.random.seed(key[2 * i])
        P_row = np.eye(W_shape[0])
        np.random.shuffle(P_row)
        permutation_matrices.append(P_row)

        # Generate P_col
        np.random.seed(key[2 * i + 1])
        P_col = np.eye(W_shape[1])
        np.random.shuffle(P_col)
        permutation_matrices.append(P_col)

    # --- Loop 2: Apply the inverse permutations ---
    for i in range(4):
        W_locked = weights_dict[f"W{i+1}"]
        # Retrieve the correct matrices from the list
        P_row = permutation_matrices[2 * i]
        P_col = permutation_matrices[2 * i + 1]
        
        # Perform inverse matrix multiplications using the transpose
        temp_W = np.dot(P_row.T, W_locked)
        unlocked_W = np.dot(temp_W, P_col.T)
        unlocked_weights[f"W{i+1}"] = unlocked_W
    
    return unlocked_weights

def forward_pass_mnist(x_test, w1, b1, w2, b2, w3, b3, w_out, b_out):
    """
    Performs a forward pass through the FULL 4-layer neural network.
    """
    # Layer 1
    Z1 = np.dot(x_test, w1) + b1
    A1 = relu(Z1)

    # Layer 2
    Z2 = np.dot(A1, w2) + b2
    A2 = relu(Z2)

    # Layer 3
    Z3 = np.dot(A2, w3) + b3
    A3 = relu(Z3)

    # Output Layer
    Z_out = np.dot(A3, w_out) + b_out
    Y_pred = softmax(Z_out)
    
    return Y_pred



def forward_pass_puf_response(x_test, w1, b1, w2, b2, w_out, b_out):
    """
    Performs a forward pass through the neural network.
    """
    Z1 = np.dot(x_test, w1) + b1
    A1 = relu(Z1)
    Z2 = np.dot(A1, w2) + b2
    A2 = relu(Z2)
    Z_out = np.dot(A2, w_out) + b_out # Uses w_out and b_out
    return Z_out

class MNISTDataLoader(object):
    def __init__(self, training_images_filepath, training_labels_filepath,
                 test_images_filepath, test_labels_filepath):
        self.training_images_filepath = training_images_filepath
        self.training_labels_filepath = training_labels_filepath
        self.test_images_filepath = test_images_filepath
        self.test_labels_filepath = test_labels_filepath

        self.x_train = None
        self.x_test = None
        self.y_train = None
        self.y_test = None

        self.load_data()

    def read_images_labels(self, images_filepath, labels_filepath):
        labels = []
        with open(labels_filepath, 'rb') as file:
            magic, size = struct.unpack(">II", file.read(8))
            if magic != 2049:
                raise ValueError(f'Magic number mismatch for labels, expected 2049, got {magic}')
            labels = array("B", file.read())

        with open(images_filepath, 'rb') as file:
            magic, size, rows, cols = struct.unpack(">IIII", file.read(16))
            if magic != 2051:
                raise ValueError(f'Magic number mismatch for images, expected 2051, got {magic}')
            image_data = array("B", file.read())

        images = np.frombuffer(image_data, dtype=np.uint8).reshape(size, rows * cols)
        return images, np.array(labels)

    def load_data(self):
        # We only need test data for this script, but keeping structure for consistency
        x_test_raw, y_test_raw = self.read_images_labels(self.test_images_filepath, self.test_labels_filepath)

        # Normalize images to range [0, 1]
        self.x_test = x_test_raw.astype(np.float32) / 255.0

        # One-hot encode labels
        num_classes = 10 
        self.y_test = np.zeros((y_test_raw.size, num_classes))
        self.y_test[np.arange(y_test_raw.size), y_test_raw] = 1
        
        print(f"MNIST Test Data loaded and processed:")
        print(f"  x_test shape: {self.x_test.shape}, dtype: {self.x_test.dtype}")
        print(f"  y_test shape: {self.y_test.shape}, dtype: {self.y_test.dtype}")

def calculate_accuracy(predicted_labels, true_labels):
    """
    Calculates the accuracy of the predictions.
    """
    correct_predictions = np.sum(predicted_labels == true_labels)  # Count matches
    total_predictions = len(true_labels)  # Total number of samples
    accuracy = correct_predictions / total_predictions * 100  # Percentage
    return accuracy
