# mnist.py

import struct
from array import array
import numpy as np

class MNIST(object):
    def __init__(self, training_images_filepath, training_labels_filepath,
                 test_images_filepath, test_labels_filepath):
        self.training_images_filepath = training_images_filepath
        self.training_labels_filepath = training_labels_filepath
        self.test_images_filepath = test_images_filepath
        self.test_labels_filepath = test_labels_filepath

        # Initialize attributes that will hold the loaded and processed data
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

        # Directly convert to numpy array and reshape to (num_images, rows * cols)
        images = np.frombuffer(image_data, dtype=np.uint8).reshape(size, rows * cols)

        return images, np.array(labels) # Return labels as a numpy array too

    def load_data(self):
        # Load raw data
        x_train_raw, y_train_raw = self.read_images_labels(self.training_images_filepath, self.training_labels_filepath)
        x_test_raw, y_test_raw = self.read_images_labels(self.test_images_filepath, self.test_labels_filepath)

        # --- Data Preprocessing ---

        # 1. Normalize images to range [0, 1]
        self.x_train = x_train_raw.astype(np.float32) / 255.0
        self.x_test = x_test_raw.astype(np.float32) / 255.0

        # 2. One-hot encode labels
        # 10 classes for MNIST (digits 0-9)
        num_classes = 10 
        
        # Create one-hot encoded y_train
        self.y_train = np.zeros((y_train_raw.size, num_classes))
        self.y_train[np.arange(y_train_raw.size), y_train_raw] = 1

        # Create one-hot encoded y_test
        self.y_test = np.zeros((y_test_raw.size, num_classes))
        self.y_test[np.arange(y_test_raw.size), y_test_raw] = 1
        
        print(f"MNIST Data loaded and processed:")
        print(f"  x_train shape: {self.x_train.shape}, dtype: {self.x_train.dtype}")
        print(f"  y_train shape: {self.y_train.shape}, dtype: {self.y_train.dtype}")
        print(f"  x_test shape: {self.x_test.shape}, dtype: {self.x_test.dtype}")
        print(f"  y_test shape: {self.y_test.shape}, dtype: {self.y_test.dtype}")

        return (self.x_train, self.y_train), (self.x_test, self.y_test)
