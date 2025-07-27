module fft (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [15:0] x_real [0:7],
    input wire signed [15:0] x_imag [0:7],
    output logic signed [15:0] X_real [0:7],
    output logic signed [15:0] X_imag [0:7],
    output logic done
);

    logic signed [15:0] stage0_real [0:7];
    logic signed [15:0] stage0_imag [0:7];
    logic signed [15:0] stage1_real [0:7];
    logic signed [15:0] stage1_imag [0:7];
    logic signed [15:0] stage2_real [0:7];
    logic signed [15:0] stage2_imag [0:7];

    parameter signed [15:0] W8_0_REAL = 16'h0100;  
    parameter signed [15:0] W8_0_IMAG = 16'h0000;  
    parameter signed [15:0] W8_1_REAL = 16'h00B5;  
    parameter signed [15:0] W8_1_IMAG = 16'hFF4B;  
    parameter signed [15:0] W8_2_REAL = 16'h0000;  
    parameter signed [15:0] W8_2_IMAG = 16'hFF00;  
    parameter signed [15:0] W8_3_REAL = 16'hFF4B;  
    parameter signed [15:0] W8_3_IMAG = 16'hFF4B;  
    
    typedef enum logic [2:0] {
        IDLE,
        STAGE0,
        STAGE1,
        STAGE2,
        DONE
    } state_t;
    
    state_t state, next_state;
    
    function [2:0] bit_reverse;
        input [2:0] index;
        begin
            bit_reverse = {index[0], index[1], index[2]};
        end
    endfunction
    
    function void complex_mult;
        input signed [15:0] a_real; 
        input signed [15:0] a_imag;
        input signed [15:0] b_real;
        input signed [15:0] b_imag;
        output signed [15:0] result_real;
        output signed [15:0] result_imag;
        logic signed [31:0] temp_real;
        logic signed [31:0] temp_imag;
        begin
            temp_real = (a_real * b_real) - (a_imag * b_imag);
            temp_imag = (a_real * b_imag) + (a_imag * b_real);
            result_real = temp_real[23:8];  
            result_imag = temp_imag[23:8];  
        end
    endfunction
    
    task butterfly;
        input signed [15:0] a_real, a_imag;
        input signed [15:0] b_real, b_imag;
        input signed [15:0] w_real, w_imag;
        output signed [15:0] out1_real, out1_imag;
        output signed [15:0] out2_real, out2_imag;
        logic signed [15:0] wb_real, wb_imag;
        begin
            complex_mult(w_real, w_imag, b_real, b_imag, wb_real, wb_imag);
            out1_real = a_real + wb_real;
            out1_imag = a_imag + wb_imag;
            out2_real = a_real - wb_real;
            out2_imag = a_imag - wb_imag;
        end
    endtask
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always_comb begin
        case (state)
            IDLE: next_state = start ? STAGE0 : IDLE;
            STAGE0: next_state = STAGE1;
            STAGE1: next_state = STAGE2;
            STAGE2: next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                for (int i = 0; i < 8; i++) begin
                    stage0_real[i] <= x_real[bit_reverse(i)]; 
                    stage0_imag[i] <= x_imag[bit_reverse(i)];  
                end
            end
            
            STAGE0: begin
                butterfly(stage0_real[0], stage0_imag[0], stage0_real[1], stage0_imag[1], 
                         W8_0_REAL, W8_0_IMAG, stage1_real[0], stage1_imag[0], stage1_real[1], stage1_imag[1]);
                butterfly(stage0_real[2], stage0_imag[2], stage0_real[3], stage0_imag[3], 
                         W8_0_REAL, W8_0_IMAG, stage1_real[2], stage1_imag[2], stage1_real[3], stage1_imag[3]);
                butterfly(stage0_real[4], stage0_imag[4], stage0_real[5], stage0_imag[5], 
                         W8_0_REAL, W8_0_IMAG, stage1_real[4], stage1_imag[4], stage1_real[5], stage1_imag[5]);
                butterfly(stage0_real[6], stage0_imag[6], stage0_real[7], stage0_imag[7], 
                         W8_0_REAL, W8_0_IMAG, stage1_real[6], stage1_imag[6], stage1_real[7], stage1_imag[7]);
            end
            
            STAGE1: begin
                butterfly(stage1_real[0], stage1_imag[0], stage1_real[2], stage1_imag[2], 
                         W8_0_REAL, W8_0_IMAG, stage2_real[0], stage2_imag[0], stage2_real[2], stage2_imag[2]);
                butterfly(stage1_real[1], stage1_imag[1], stage1_real[3], stage1_imag[3], 
                         W8_2_REAL, W8_2_IMAG, stage2_real[1], stage2_imag[1], stage2_real[3], stage2_imag[3]);
                butterfly(stage1_real[4], stage1_imag[4], stage1_real[6], stage1_imag[6], 
                         W8_0_REAL, W8_0_IMAG, stage2_real[4], stage2_imag[4], stage2_real[6], stage2_imag[6]);
                butterfly(stage1_real[5], stage1_imag[5], stage1_real[7], stage1_imag[7], 
                         W8_2_REAL, W8_2_IMAG, stage2_real[5], stage2_imag[5], stage2_real[7], stage2_imag[7]);
            end
            
            STAGE2: begin
                butterfly(stage2_real[0], stage2_imag[0], stage2_real[4], stage2_imag[4], 
                         W8_0_REAL, W8_0_IMAG, X_real[0], X_imag[0], X_real[4], X_imag[4]);
                butterfly(stage2_real[1], stage2_imag[1], stage2_real[5], stage2_imag[5], 
                         W8_1_REAL, W8_1_IMAG, X_real[1], X_imag[1], X_real[5], X_imag[5]);
                butterfly(stage2_real[2], stage2_imag[2], stage2_real[6], stage2_imag[6], 
                         W8_2_REAL, W8_2_IMAG, X_real[2], X_imag[2], X_real[6], X_imag[6]);
                butterfly(stage2_real[3], stage2_imag[3], stage2_real[7], stage2_imag[7], 
                         W8_3_REAL, W8_3_IMAG, X_real[3], X_imag[3], X_real[7], X_imag[7]);
            end
            
            DONE: begin
                done <= 1'b1;
            end
        endcase
    end
endmodule

module de1_soc_top (
    input wire CLOCK_50,
    input wire [3:0] KEY,
    input wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5
);

    logic clk;
    logic rst_n;
    logic start;
    logic signed [15:0] x_real [0:7];  
    logic signed [15:0] x_imag [0:7];
    wire signed [15:0] X_real [0:7];
    wire signed [15:0] X_imag [0:7];
    wire done;
    
    logic [31:0] timer_count;
    logic [31:0] execution_cycles;
    logic timing_active;
    logic start_prev;
    
    assign clk = CLOCK_50;
    assign rst_n = KEY[0];
    assign start = ~KEY[1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count <= 32'h0;
            execution_cycles <= 32'h0;
            timing_active <= 1'b0;
            start_prev <= 1'b0;
        end else begin
            start_prev <= start;
            
            // Detect start pulse (rising edge)
            if (start && !start_prev) begin
                timer_count <= 32'h0;
                timing_active <= 1'b1;
            end
            
            // Count cycles while FFT is running
            if (timing_active && !done) begin
                timer_count <= timer_count + 1;
            end
            
            // Capture final count when done
            if (done && timing_active) begin
                execution_cycles <= timer_count;
                timing_active <= 1'b0;
            end
        end
    end

    always_comb begin
        if (SW[9]) begin
            // Impulse
            // x[0] = 1.0, all others = 0
            // Expected: X[k] = 1.0 for all k
            x_real[0] = 16'h0100; 
            x_imag[0] = 16'h0000; 
            for (int i = 1; i < 8; i++) begin
                x_real[i] = 16'h0000; 
                x_imag[i] = 16'h0000; 
            end
        end else begin
            // sin(2pi*n/8)
            // x = [0, 0.70710677, 1, 0.70710677, 0, -0.70710677, -1, -0.70710677]
            // Expected: X[1] = -4j, X[7] = +4j, all others ~ 0
            x_real[0] = 16'h0000; 
            x_real[1] = 16'h00B5; 
            x_real[2] = 16'h0100;  
            x_real[3] = 16'h00B5; 
            x_real[4] = 16'h0000; 
            x_real[5] = 16'hFF4B;  
            x_real[6] = 16'hFF00;  
            x_real[7] = 16'hFF4B; 

            for (int i = 0; i < 8; i++) begin
                x_imag[i] = 16'h0000; 
            end
        end
    end

    fft fft_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .x_real(x_real),
        .x_imag(x_imag),
        .X_real(X_real),
        .X_imag(X_imag),
        .done(done)
    );

    assign LEDR[0] = done;  
    
    function [6:0] hex_decoder;
        input [3:0] value;
        begin
            case (value)
                4'h0: hex_decoder = 7'b1000000;
                4'h1: hex_decoder = 7'b1111001;
                4'h2: hex_decoder = 7'b0100100;
                4'h3: hex_decoder = 7'b0110000;
                4'h4: hex_decoder = 7'b0011001;
                4'h5: hex_decoder = 7'b0010010;
                4'h6: hex_decoder = 7'b0000010;
                4'h7: hex_decoder = 7'b1111000;
                4'h8: hex_decoder = 7'b0000000;
                4'h9: hex_decoder = 7'b0010000;
                4'hA: hex_decoder = 7'b0001000;
                4'hB: hex_decoder = 7'b0000011;
                4'hC: hex_decoder = 7'b1000110;
                4'hD: hex_decoder = 7'b0100001;
                4'hE: hex_decoder = 7'b0000110;
                4'hF: hex_decoder = 7'b0001110;
            endcase
        end
    endfunction

    wire [2:0] index;
    wire show_real;
    wire show_timer;
    
    assign index = SW[2:0];      
    assign show_real = SW[3];    
    assign show_timer = SW[4];   
    
    wire [15:0] display_data;
    assign display_data = show_timer ? execution_cycles[15:0] : show_real ? X_real[index] : X_imag[index];

    assign HEX0 = hex_decoder(display_data[3:0]);
    assign HEX1 = hex_decoder(display_data[7:4]);
    assign HEX2 = hex_decoder(display_data[11:8]);
    assign HEX3 = hex_decoder(display_data[15:12]);
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;
endmodule