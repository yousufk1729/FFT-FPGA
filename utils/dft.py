import numpy as np

def dft(x):
    N = len(x)
    X = []
    for k in range(N):
        sum_val = 0
        for n in range(N):
            angle = -2j * np.pi * k * n / N
            sum_val += x[n] * np.exp(angle)
        X.append(sum_val)
    return X

# sin(2pi * n / 8)
x = [0, 0.707, 1, 0.707, 0, -0.707, -1, -0.707]
X = dft(x)

print("Time Domain:", x)
print("Frequency Domain:")
for k, val in enumerate(X):
    print(f"X[{k}] = {val:.6f}")