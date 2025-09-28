# mlplocker.py

import numpy as np
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from src.mlp import MLP

class MLPLocker:
    def __init__(self, mlp_instance):
        self.mlp = mlp_instance
        self.original_weights = {k: v.copy() for k, v in mlp_instance.weights.items()}
        self.original_biases = {k: v.copy() for k, v in mlp_instance.biases.items()}
        self.permutation_matrices = []
        # Attributes for AES locking
        self.nonces = {}
        self.original_dtypes = {}

    def lock(self, key, method):
        if method == 'bias_circular_shifting':
            self.mlp.locking_method = 'bias_circular_shifting'

            for i in range(4):
                str_name = f"b{i+1}"
                self.mlp.biases[str_name] = np.roll(self.mlp.biases[str_name], key[i])

        elif method == 'weights_cols_and_rows_circular_shifting':
            self.mlp.locking_method = 'weights_cols_and_rows_circular_shifting'

            for i in range(4):
                str_name = f"W{i+1}"
                self.mlp.weights[str_name] = np.roll(self.mlp.weights[str_name], key[2 * i], axis = 0)
                self.mlp.weights[str_name] = np.roll(self.mlp.weights[str_name], key[2 * i + 1], axis = 1)
    
        elif method == 'permutation_matrices_rows':
            self.mlp.locking_method = 'permutation_matrices_rows'

            for i in range(4):
                str_name = f"W{i+1}"
                self.permutation_matrices.append(np.eye(self.mlp.weights[str_name].shape[0]))
                np.random.seed(key[i])
                np.random.shuffle(self.permutation_matrices[i])
                self.mlp.weights[str_name] = np.dot(self.permutation_matrices[i], self.mlp.weights[str_name])

        elif method == 'permutation_matrices_rows_and_columns':
            self.mlp.locking_method = 'permutation_matrices_rows_and_columns'
            
            for i in range(8):
                str_name = f"W{(i // 2) + 1}" # '//' floors
                # Permutation matrices {P1Row, P1Col, P2Row, P2Col, P3Row, P3Col, P4Row, P4Col}
                # Pcols need to be mxm and Prows need to be nxn given that W is mxn
                if i % 2 == 0:
                    self.permutation_matrices.append(np.eye(self.mlp.weights[str_name].shape[0]))
                else:
                    self.permutation_matrices.append(np.eye(self.mlp.weights[str_name].shape[1]))
                np.random.seed(key[i])
                np.random.shuffle(self.permutation_matrices[i])
            
            for i in range(4):
                str_name = f"W{i+1}"
                self.mlp.weights[str_name] = np.dot(self.permutation_matrices[2 * i], self.mlp.weights[str_name])
                self.mlp.weights[str_name] = np.dot(self.mlp.weights[str_name], self.permutation_matrices[2 * i + 1])
                
        elif method == 'aes_128':
            self.mlp.locking_method = 'aes_128'
            if not isinstance(key, bytes) or len(key) != 16:
                raise ValueError("AES-128 key must be 16 bytes long.")
            
            for str_name, weight_matrix in self.mlp.weights.items():
                # Store original data type for perfect reconstruction later
                self.original_dtypes[str_name] = weight_matrix.dtype
                
                # Generate and store a unique nonce for each weight matrix
                nonce = os.urandom(16)
                self.nonces[str_name] = nonce
                
                # Set up the AES cipher in CTR mode
                cipher = Cipher(algorithms.AES(key), modes.CTR(nonce))
                encryptor = cipher.encryptor()
                
                # Convert the numpy weight matrix to a byte string
                plaintext_bytes = weight_matrix.tobytes()
                
                # Encrypt the bytes
                ciphertext_bytes = encryptor.update(plaintext_bytes) + encryptor.finalize()
                
                # Convert the encrypted bytes back into a numpy array and reshape it
                encrypted_array = np.frombuffer(ciphertext_bytes, dtype=weight_matrix.dtype)
                self.mlp.weights[str_name] = encrypted_array.reshape(weight_matrix.shape)

        else:
            raise ValueError('Invalid locking method')
            
    def unlock(self, key):
        if self.mlp.locking_method == 'bias_circular_shifting':

            for i in range(4):
                str_name = f"b{i+1}"
                self.mlp.biases[str_name] = np.roll(self.mlp.biases[str_name], -key[i])
                
            self.permutation_matrices = []

        elif self.mlp.locking_method == 'weights_cols_and_rows_circular_shifting':

            for i in range(4):
                str_name = f"W{i+1}"
                self.mlp.weights[str_name] = np.roll(self.mlp.weights[str_name], -key[2 * i + 1], axis = 1)
                self.mlp.weights[str_name] = np.roll(self.mlp.weights[str_name], -key[2 * i], axis = 0)
                
            self.permutation_matrices = []

        elif self.mlp.locking_method == 'permutation_matrices_rows':

            for i in range(4):
                str_name = f"W{i+1}"
                self.mlp.weights[str_name] = np.dot(self.permutation_matrices[i].T, self.mlp.weights[str_name])
                
            self.permutation_matrices = []
                
        elif self.mlp.locking_method == 'permutation_matrices_rows_and_columns':
            
            for i in range(4):
                str_name = f"W{i+1}"
                self.mlp.weights[str_name] = np.dot(self.mlp.weights[str_name], self.permutation_matrices[2 * i + 1].T)
                self.mlp.weights[str_name] = np.dot(self.permutation_matrices[2 * i].T, self.mlp.weights[str_name])
                
            self.permutation_matrices = []
        
        elif self.mlp.locking_method == 'aes_128':
            if not isinstance(key, bytes) or len(key) != 16:
                raise ValueError("AES-128 key must be 16 bytes long.")

            for str_name, locked_weight_matrix in self.mlp.weights.items():
                nonce = self.nonces.get(str_name)
                if nonce is None:
                    raise RuntimeError(f"Nonce for {str_name} not found. Model might not be locked correctly.")
                    
                # Set up the exact same cipher to decrypt
                cipher = Cipher(algorithms.AES(key), modes.CTR(nonce))
                decryptor = cipher.encryptor() # In CTR mode, encryption and decryption are the same operation
                
                # Convert locked weights to bytes
                ciphertext_bytes = locked_weight_matrix.tobytes()
                
                # Decrypt the bytes
                plaintext_bytes = decryptor.update(ciphertext_bytes) + decryptor.finalize()
                
                # Convert back to numpy array with original shape and type
                original_dtype = self.original_dtypes.get(str_name)
                original_shape = self.original_weights[str_name].shape
                decrypted_array = np.frombuffer(plaintext_bytes, dtype=original_dtype)
                self.mlp.weights[str_name] = decrypted_array.reshape(original_shape)
            
            # Clean up stored nonces and dtypes after unlocking
            self.nonces = {}
            self.original_dtypes = {}
 
        else:
            raise ValueError('No locking method has been set')
        
        
    def test_locking(self, x_test, y_test):
        test_activations = self.mlp.forward_pass(x_test)
        test_pred = test_activations[f"A{len(self.mlp.weights)}"]
        test_accuracy = np.mean(np.argmax(test_pred, axis=1) == np.argmax(y_test, axis=1))
        return test_accuracy
    
# #FAF4F2