# I am not writing this by hand
# Claude Sonnet 4, prompt = "8-pt dft in python using built-in numpy dft function"
# Reformatted after

import time

import matplotlib.pyplot as plt
import numpy as np


def analyze_dft(x):
    start_time = time.perf_counter()
    X = np.fft.fft(x)
    end_time = time.perf_counter()

    dft_time = end_time - start_time
    print(f"DFT computation time: {dft_time:.6f} seconds")

    print("Input signal x[n]:")
    for k, val in enumerate(x):
        print(f"x[{k}] = {val:.6f}")

    print("\nDFT coefficients X[k]:")
    for k, val in enumerate(X):
        print(f"X[{k}] = {val:.6f}")

    print()  # I just want to print 1 newline ??

    magnitude = np.abs(X)
    phase = np.angle(X)

    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(12, 8))

    ax1.stem(range(8), x, basefmt=" ")
    ax1.set_title("Input Signal x[n]")
    ax1.set_xlabel("n")
    ax1.set_ylabel("x[n]")
    ax1.grid(True)

    ax2.stem(range(8), magnitude, basefmt=" ")
    ax2.set_title("Magnitude Spectrum |X[k]|")
    ax2.set_xlabel("k")
    ax2.set_ylabel("|X[k]|")
    ax2.grid(True)

    ax3.stem(range(8), phase, basefmt=" ")
    ax3.set_title("Phase Spectrum ∠X[k]")
    ax3.set_xlabel("k")
    ax3.set_ylabel("∠X[k] (radians)")
    ax3.grid(True)

    ax4.stem(range(8), np.real(X), basefmt=" ", label="Real")
    ax4.stem(
        range(8),
        np.imag(X),
        basefmt=" ",
        label="Imaginary",
        linefmt="r-",
        markerfmt="ro",
    )
    ax4.set_title("DFT Real and Imaginary Parts")
    ax4.set_xlabel("k")
    ax4.set_ylabel("X[k]")
    ax4.legend()
    ax4.grid(True)

    plt.tight_layout()
    plt.show()


# Impulse
# x[0] = 1.0, all others = 0
# Expected: X[k] = 1.0 for all k
x_impulse = np.array([1, 0, 0, 0, 0, 0, 0, 0])
analyze_dft(x_impulse)

# sin(2pi*n/8)
# x = [0, 0.70710677, 1, 0.70710677, 0, -0.70710677, -1, -0.70710677]
# Expected: X[1] = -4j, X[7] = +4j, all others ~ 0
x_sine = np.array([0, 0.70710677, 1, 0.70710677, 0, -0.70710677, -1, -0.70710677])
analyze_dft(x_sine)
