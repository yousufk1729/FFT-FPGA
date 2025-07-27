#define _USE_MATH_DEFINES

#include <intrin.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>

#define N 8
#define CPU_GHZ 2.9

// Q7.8/fix uses 1 sign bit, 7 integer bits, 8 fractional bits
#define fix int16_t
#define FIX_MIN -128.0f
#define FIX_MAX 127.99609375f
#define float2fix(a) (fix)(fminf(fmaxf(a, FIX_MIN), FIX_MAX) * 256.0f)
#define fix2float(a) (float)(a / 256.0f)
#define multfix(a, b) (fix)((((int32_t)(a)) * ((int32_t)(b)) >> 8))

typedef struct {
  fix real;
  fix imag;
} fix_complex;

void test_arithmetic() {
  fix x = float2fix(1.0f);                            // 0x0100
  fix y = float2fix(0.70703125f);                     // 0x00B5
  fix z = float2fix(-128.0f);                         // 0x8000
  fix w = float2fix(127.99609375f);                   // 0x7FFF
  fix v = multfix(float2fix(4.0f), float2fix(2.0f));  // 0x0800 (8)

  printf("%04hx, %04hx, %04hx, %04hx, %04hx\n", x, y, z, w, v);
}

void compute_twiddles(fix_complex twiddles[N]) {
  for (int k = 0; k < N / 2; ++k) {
    float angle = -2.0f * M_PI * k / N;
    float real = cosf(angle);
    float imag = sinf(angle);
    twiddles[k].real = float2fix(real);
    twiddles[k].imag = float2fix(imag);

    printf("k = %d\n", k);
    printf(" Re: Float = %.8f, Hex = 0x%04hX, Fixed = %.8f\n", real,
           twiddles[k].real, fix2float(twiddles[k].real));
    printf(" Im: Float = %.8f, Hex = 0x%04hX, Fixed = %.8f\n", imag,
           twiddles[k].imag, fix2float(twiddles[k].imag));
  }
}

int bit_reverse(int index) {
  return ((index & 1) << 2) | (index & 2) | ((index & 4) >> 2);
}

fix_complex complex_mult(fix_complex a, fix_complex b) {
  fix_complex result;
  int32_t temp_real = (int32_t)a.real * b.real - (int32_t)a.imag * b.imag;
  int32_t temp_imag = (int32_t)a.real * b.imag + (int32_t)a.imag * b.real;
  result.real = (fix)(temp_real >> 8);
  result.imag = (fix)(temp_imag >> 8);
  return result;
}

void butterfly(fix_complex *a, fix_complex *b, fix_complex w) {
  fix_complex wb = complex_mult(w, *b);
  fix_complex temp_a = *a;
  a->real = temp_a.real + wb.real;
  a->imag = temp_a.imag + wb.imag;
  b->real = temp_a.real - wb.real;
  b->imag = temp_a.imag - wb.imag;
}

void fft(fix_complex x[N], fix_complex X[N]) {
  fix_complex stage0[N], stage1[N], stage2[N];

  fix_complex W[4] = {
      {0x0100, 0x0000}, {0x00B5, 0xFF4B}, {0x0000, 0xFF00}, {0xFF4B, 0xFF4B}};

  for (int i = 0; i < N; i++) {
    int rev_i = bit_reverse(i);
    stage0[i] = x[rev_i];
  }

  for (int i = 0; i < N; i += 2) {
    stage1[i] = stage0[i];
    stage1[i + 1] = stage0[i + 1];
    butterfly(&stage1[i], &stage1[i + 1], W[0]);
  }

  for (int i = 0; i < N; i += 4) {
    stage2[i] = stage1[i];
    stage2[i + 2] = stage1[i + 2];
    butterfly(&stage2[i], &stage2[i + 2], W[0]);

    stage2[i + 1] = stage1[i + 1];
    stage2[i + 3] = stage1[i + 3];
    butterfly(&stage2[i + 1], &stage2[i + 3], W[2]);
  }

  X[0] = stage2[0];
  X[4] = stage2[4];
  butterfly(&X[0], &X[4], W[0]);

  X[1] = stage2[1];
  X[5] = stage2[5];
  butterfly(&X[1], &X[5], W[1]);

  X[2] = stage2[2];
  X[6] = stage2[6];
  butterfly(&X[2], &X[6], W[2]);

  X[3] = stage2[3];
  X[7] = stage2[7];
  butterfly(&X[3], &X[7], W[3]);
}

void print_complex_array(const char *name, fix_complex arr[N]) {
  printf("%s:\n", name);
  for (int i = 0; i < N; i++) {
    printf("X[%d]: 0x%04hX + 0x%04hXj (%f + %fj)\n", i, arr[i].real,
           arr[i].imag, fix2float(arr[i].real), fix2float(arr[i].imag));
  }
}

void time_fft(const char *test_name, fix_complex *x) {
  fix_complex X[N] = {{0}};

  // https://stackoverflow.com/questions/138932/how-do-i-obtain-cpu-cycle-count-in-win32
  unsigned long long start_cycles = __rdtsc();
  fft(x, X);
  unsigned long long end_cycles = __rdtsc();
  unsigned long long cpu_time = end_cycles - start_cycles;

  printf("CPU cycles: %llu\n", cpu_time);
  printf("Estimated speed based on %.1f GHz processor: %.0f ns\n", CPU_GHZ,
         cpu_time / CPU_GHZ);

  print_complex_array("FFT Output", X);
}

void test_impulse() {
  // Impulse
  // x[0] = 1.0, all others = 0
  // Expected: X[k] = 1.0 for all k
  fix_complex x[N] = {{0}};
  x[0].real = float2fix(1.0f);

  time_fft("Impulse", x);
}

void test_sine_wave() {
  // sin(2pi*n/8)
  // x = [0, 0.70710677, 1, 0.70710677, 0, -0.70710677, -1, -0.70710677]
  // Expected: X[1] = -4j, X[7] = +4j, all others ~ 0
  fix_complex x[N] = {{0}};
  float x_float[N] = {0, 0.70710677,  1,  0.70710677,
                      0, -0.70710677, -1, -0.70710677};
  for (int i = 0; i < N; i++) {
    x[i].real = float2fix(x_float[i]);
  }

  time_fft("Sine", x);
}

int main(void) {
  // test_arithmetic();
  // fix_complex twiddles[N];
  // compute_twiddles(twiddles);

  test_impulse();
  test_sine_wave();

  return 0;
}