# FFT-FPGA
8-point Cooley-Tukey radix-2 DIT FFT on an FPGA. 

## Motivation
The FFT is arguably the most important algorithm you could learn in a signal processing course, but my introductory signal processing course, ECE216, did not cover the DFT or the FFT to implement it. I also want to learn how to use SystemVerilog. 

## Overview
We will be implementing the 8-point Cooley-Tukey radix-2 DIT FFT on my DE1-SoC FPGA board. 

I am using Q7.8 fixed-point arithmetic (1 sign bit, 7 integer bits, 8 fractional bits for representation between -128 and 127.99609375). 

The algorithm is well-documented and fairly straightforward to implement. I want an image in this writeup so here’s a butterfly diagram:
<img width="850" height="901" alt="image" src="https://github.com/user-attachments/assets/98af0509-9969-4f0f-a98f-d72aaa687cdf" />

I also created some utilities for float-fix conversion and an FFT implementation in C. 

## Results

Measuring performance is quite a difficult operation. For simplicity, I use an average of 10 sine and 10 impulse tests for each implementation.

In Python, this is easy to do using time.perf_counter(). 

Unfortunately, my C code is fast enough that the clock() function and the Windows QueryPerformanceFrequency and QueryPerformanceCounter functions do not have enough resolution to register anything (Windows API has 100 ns on my machine). When I tried to use delay loops to compute 1e6 identical FFTs and average the total time, the compiler optimized it out. I didn’t feel like writing randomized test cases for each of my 3 implementations and it’s not like timing is a serious goal anyway, so I just estimate time using __rdtsc() to return CPU cycles and divide by my processor’s 2.9 GHz clock speed. 

FPGA testing coming soon… I need to add a timer and use smth like JTAG UART to send it back

| Implementation | Execution Time | Cycles | Speedup |
|----------------|----------------|--------|-------------------|
| Python | 2,078,200 ns | too many | 1x |
| C | 108.62 ns | ~315 | 19,133x |
| FPGA | … | - | - |

## Next Steps

A clear next step for this project is pipelining to take advantage of the FPGA, as well as writing a better test suite. 

## References
- https://w.wiki/EjDe
- https://web.mit.edu/6.111/www/f2017/handouts/FFTtutorial121102.pdf
- https://vanhunteradams.com/FFT/FFT.html#8-sample-FFT,-step-by-step
- https://www.researchgate.net/figure/Signal-flow-graph-of-an-8-point-DIT-FFT_fig2_2982495
- https://vanhunteradams.com/FixedPoint/FixedPoint.html 
- https://chummersone.github.io/qformat.html#converter 
- ECE216 formula sheet 
- https://stackoverflow.com/questions/138932/how-do-i-obtain-cpu-cycle-count-in-win32 
- https://stackoverflow.com/questions/15720542/measure-execution-time-in-c-on-windows
