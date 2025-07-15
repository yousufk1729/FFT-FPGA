#include <math.h>
#include <stdint.h>
#include <stdio.h>

int8_t float_to_q07(float input) {
  if (input >= 1.0f) input = 0.9921875;  // Max for Q0.7 = 127/128
  if (input < -1.0f) input = -1.0;
  return (int8_t)roundf(input * 128.0);
}

float q07_to_float(int8_t input) { return (float)input / 128.0; }

void float_to_q07_batch(const float input[8], int8_t output[8]) {
  for (int i = 0; i < 8; ++i) {
    output[i] = float_to_q07(input[i]);
  }
}

void q07_to_float_batch(const int8_t input[8], float output[8]) {
  for (int i = 0; i < 8; ++i) {
    output[i] = q07_to_float(input[i]);
  }
}

int main() {
  // Used in FFT module
  // float float_vals[8] = {1.0, 0.0, 0.707, -0.707, 0.0, -1.0, -0.707, -0.707};
  // sin(2pi * n / 8)
  float float_vals[8] = {0, 0.707, 1, 0.707, 0, -0.707, -1, -0.707};
  int8_t fixed_vals[8];
  float restored_vals[8];

  float_to_q07_batch(float_vals, fixed_vals);
  q07_to_float_batch(fixed_vals, restored_vals);

  for (int i = 0; i < 8; ++i) {
    printf("Original: % .6f, Fixed: %4d (0x%02X), Restored: % .6f\n",
           float_vals[i], fixed_vals[i], (uint8_t)fixed_vals[i],
           restored_vals[i]);
  }

  return 0;
}