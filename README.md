# FFT-FPGA
8-point Cooley-Tukey radix-2 DIT FFT on an FPGA. 

## Motivation
The FFT is arguably the most important algorithm you could learn in a signal processing course, but my introductory signal processing course, ECE216, did not cover the DFT or the FFT to implement it. I also want to learn how to use SystemVerilog. 

## Overview
We will be implementing the 8-point Cooley-Tukey radix-2 DIT FFT on my DE1-SoC FPGA board. 

My implementation is not parameterized, and I am also using Q0.7 fixed-point arithmetic (1 sign bit, 7 fractional bits for a representation between -1 and 1). Putting my ECE216 knowledge to good use, I tested it with an impulse and a sine wave, and got expected results. 

I want an image in this writeup so here’s a butterfly diagram:
<img width="850" height="901" alt="image" src="https://github.com/user-attachments/assets/98af0509-9969-4f0f-a98f-d72aaa687cdf" />

## Next Steps
I’m not too happy with the workflow of this project because I quickly made test programs and kept running back and forth between my fixed-point hex converter, DFT calculator, and FPGA board hex display values (talk about visual debugging). 

A clear next step for this project is to have a better way to make test cases, with a multiplexer to feed a selected input into the FFT module. Also, my fixed-point needs more bits for precision and a larger range of values. I could also parameterize the FFT module itself so it accepts more than 8-point input. 

## References
- https://w.wiki/EjDe
- https://web.mit.edu/6.111/www/f2017/handouts/FFTtutorial121102.pdf
- https://vanhunteradams.com/FFT/FFT.html#8-sample-FFT,-step-by-step
- https://www.researchgate.net/figure/Signal-flow-graph-of-an-8-point-DIT-FFT_fig2_2982495
- https://vanhunteradams.com/FixedPoint/FixedPoint.html 
- ECE216 formula sheet 
