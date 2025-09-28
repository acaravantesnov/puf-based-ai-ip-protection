# mlp.py

import numpy as np

class MLP:
    def __init__(self, num_classes = 10, learning_rate = 0.01,
                 W1=None, W2=None, W3=None, W4=None, 
                 b1=None, b2=None, b3=None, b4=None):
        
        self.num_classes = num_classes
        self.learning_rate = learning_rate
        self.locking_method = None

        self.weights = {}
        if W1 is not None: self.weights['W1'] = W1
        if W2 is not None: self.weights['W2'] = W2
        if W3 is not None: self.weights['W3'] = W3
        if W4 is not None: self.weights['W4'] = W4

        self.biases = {}
        if b1 is not None: self.biases['b1'] = b1
        if b2 is not None: self.biases['b2'] = b2
        if b3 is not None: self.biases['b3'] = b3
        if b4 is not None: self.biases['b4'] = b4

    def relu(self, x):
        return np.maximum(0, x)

    def softmax(self, x):
        exp_x = np.exp(x - np.max(x, axis=1, keepdims=True))
        return exp_x / np.sum(exp_x, axis=1, keepdims=True)

    def initialize_weights(self, input_size, hidden_sizes):
        sizes = [input_size] + hidden_sizes + [self.num_classes]
        for i in range(len(sizes) - 1):
            self.weights[f"W{i+1}"] = np.random.randn(sizes[i], sizes[i+1]) * 0.01
            self.biases[f"b{i+1}"] = np.zeros((1, sizes[i+1]))

    def forward_pass(self, x):
        activations = {"A0": x}
        for i in range(1, len(self.weights) + 1):
            z = np.dot(activations[f"A{i-1}"], self.weights[f"W{i}"]) + self.biases[f"b{i}"]
            activations[f"Z{i}"] = z
            activations[f"A{i}"] = self.relu(z) if i != len(self.weights) else self.softmax(z)
        return activations

    def backward_pass(self, x, y, activations):
        gradients = {}
        m = x.shape[0]

        # Compute output layer error
        dA = activations[f"A{len(self.weights)}"] - y

        # Loop backward through layers
        for i in reversed(range(1, len(self.weights) + 1)):
            gradients[f"dW{i}"] = np.dot(activations[f"A{i-1}"].T, dA) / m
            gradients[f"db{i}"] = np.sum(dA, axis=0, keepdims=True) / m

            # Backpropagate the error to the previous layer
            if i > 1:
                dA = np.dot(dA, self.weights[f"W{i}"].T) * (activations[f"Z{i-1}"] > 0)

        # Update weights and biases
        for i in range(1, len(self.weights) + 1):
            self.weights[f"W{i}"] -= self.learning_rate * gradients[f"dW{i}"]
            self.biases[f"b{i}"] -= self.learning_rate * gradients[f"db{i}"]


    def predict(self, x):
        activations = self.forward_pass(x)
        return np.argmax(activations[f"A{len(self.weights)}"], axis=1)
