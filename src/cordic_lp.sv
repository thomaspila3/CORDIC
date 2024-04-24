// CORDIC unit, pipelined implementation
// mode = 0:
//      Provide an angle in radians*32768, provide enough clocks,
//      and you get back the sin*32768 and cos*32768 of that angle.
// mode = 1:
//      Provide a value and get back the arctan of that value (in radians).
`define NUM_BITS 17
module tt_um_cordic_wrapper(
    input logic clk, rst, mode_toggle, out_toggle,
    // in_val: 1) vectoring mode: 2 5-bit x/y coordinates. 5 bit fraction
    //         2) rotation mode: 10-bit value which is radians. 3 bit decimal, 7 bit fraction
    input logic [9:0] in_val,
    // 2 bit decimal 9 bit fraction?
    output logic signed [10:0] val,
    output logic done
);

    logic [`NUM_BITS-1:0] in_val_32768;
    logic [`NUM_BITS-1:0] in_x_32768, in_y_32768;
    logic [`NUM_BITS-1:0] z_coeff[15:0];
    logic [`NUM_BITS-1:0] z_coeff_group[3:0];
    logic [2:0] step_ctr;
    logic [4:0] step_ctr_4;

    logic [`NUM_BITS-1:0] out1, out2;

    assign val = out_toggle ? out1[16:6] : out2[16:6];
    // Multiplying by 32768
    // rotation mode
    assign in_val_32768 = {in_val, 8'b0};
    // vectoring mode
    assign in_x_32768 = {2'b0, in_val[9:5], 10'b0};
    assign in_y_32768 = {2'b0, in_val[4:0], 10'b0};

    // "LUT" array that is inputted per stage
    assign z_coeff[0] = 17'd25736;
    assign z_coeff[1] = 17'd15193;
    assign z_coeff[2] = 17'd8027;
    assign z_coeff[3] = 17'd4075;
    assign z_coeff[4] = 17'd2045;
    assign z_coeff[5] = 17'd1024;
    assign z_coeff[6] = 17'd512;
    assign z_coeff[7] = 17'd256;
    assign z_coeff[8] = 17'd128;
    assign z_coeff[9] = 17'd64;
    assign z_coeff[10] = 17'd32;
    assign z_coeff[11] = 17'd16;
    assign z_coeff[12] = 17'd8;
    assign z_coeff[13] = 17'd4;
    assign z_coeff[14] = 17'd2;
    assign z_coeff[15] = 17'd1;

    // intermediate values for generate statement
    logic [`NUM_BITS-1:0] int_x[3:0], int_y[3:0], int_z[3:0];
    logic [`NUM_BITS-1:0] in_ff_x[4:0], in_ff_y[4:0], in_ff_z[4:0];
    logic [`NUM_BITS-1:0] init_z, init_y, init_x, curr_x, curr_y, curr_z, next_x, next_y, next_z;

    // mode = rotation(0) vector(1)
    assign init_z = mode_toggle ? 'b0 : in_val_32768;
    assign init_y = mode_toggle ? in_y_32768 : 'b0;
    assign init_x = mode_toggle ? in_x_32768 : 17'd19898;

    four_stages fstage_0 (.in_x(curr_x), .in_y(curr_y), .in_z(curr_z),
                               .clk(clk), .reset(rst), .mode(mode_toggle),
                               .out_x(next_x), .out_y(next_y), .out_z(next_z),
                               .z_coeff_0(z_coeff_group[0]), .z_coeff_1(z_coeff_group[1]),
                               .z_coeff_2(z_coeff_group[2]), .z_coeff_3(z_coeff_group[3]), .step_ctr(step_ctr_4));

    // calculate the shifting amount, and the z coefficient based on the ctr value
    always_comb begin
        step_ctr_4 = (step_ctr - 5'd1) << 2;
        z_coeff_group[0] = 'b0; z_coeff_group[1] = 'b0;
        z_coeff_group[2] = 'b0; z_coeff_group[3] = 'b0;
        case (step_ctr)
            3'd1: begin
                  z_coeff_group[0] = z_coeff[0];
                  z_coeff_group[1] = z_coeff[1];
                  z_coeff_group[2] = z_coeff[2];
                  z_coeff_group[3] = z_coeff[3];
            end
            3'd2: begin
                  z_coeff_group[0] = z_coeff[4];
                  z_coeff_group[1] = z_coeff[5];
                  z_coeff_group[2] = z_coeff[6];
                  z_coeff_group[3] = z_coeff[7];
            end
            3'd3: begin
                  z_coeff_group[0] = z_coeff[8];
                  z_coeff_group[1] = z_coeff[9];
                  z_coeff_group[2] = z_coeff[10];
                  z_coeff_group[3] = z_coeff[11];
            end
            3'd4: begin
                  z_coeff_group[0] = z_coeff[12];
                  z_coeff_group[1] = z_coeff[13];
                  z_coeff_group[2] = z_coeff[14];
                  z_coeff_group[3] = z_coeff[15];
            end
        endcase
    end

    // upadintg counters and x/y/z values
    always_ff @ (posedge clk, posedge rst) begin
        if (rst) begin
            step_ctr <= 'b0;
            done <= 'b0;
            curr_x <= 'b0;
            curr_y <= 'b0;
            curr_z <= 'b0;
        end else begin
            if (~done)
                step_ctr <= step_ctr + 3'b1;
            if (step_ctr == 3'd4) begin
                out1 <= mode_toggle ? next_z : next_y;
                out2 <= next_x;
                done <= 1'b1;
            end else begin
                if (step_ctr == 'b0) begin
                    curr_x <= init_x;
                    curr_y <= init_y;
                    curr_z <= init_z;
                end else begin
                    curr_x <= next_x;
                    curr_y <= next_y;
                    curr_z <= next_z;
                end
            end
        end
    end

endmodule: tt_um_cordic_wrapper


/* includes 4 stages connections */
module four_stages #(
    parameter STAGE_NUM_FOURTH=0)
(
    // in_x/y/z and z_coeffs for earlier stage
    input logic signed [`NUM_BITS-1:0] in_x, in_y, in_z,
    input logic [`NUM_BITS-1:0] z_coeff_1, z_coeff_2, z_coeff_3, z_coeff_0,
    input logic [4:0] step_ctr,
    input logic clk, reset, mode,
    // output from the later stage
    output logic signed [`NUM_BITS-1:0] out_x, out_y, out_z
);

    logic [`NUM_BITS-1:0] int_out_x[2:0], int_out_y[2:0], int_out_z[2:0];
    stage  stage_0 (.in_x(in_x), .in_y(in_y), .in_z(in_z),
                                     .z_coeff(z_coeff_0), .clk(clk), .reset(reset), .mode(mode),
                                     .out_x(int_out_x[0]), .out_y(int_out_y[0]), .out_z(int_out_z[0]),
                                     .step_ctr(step_ctr));
    stage stage_1 (.in_x(int_out_x[0]), .in_y(int_out_y[0]), .in_z(int_out_z[0]),
                                     .z_coeff(z_coeff_1), .clk(clk), .reset(reset), .mode(mode),
                                     .out_x(int_out_x[1]), .out_y(int_out_y[1]), .out_z(int_out_z[1]),
                                     .step_ctr(step_ctr + 5'd1));
    stage stage_2 (.in_x(int_out_x[1]), .in_y(int_out_y[1]), .in_z(int_out_z[1]),
                                     .z_coeff(z_coeff_2), .clk(clk), .reset(reset), .mode(mode),
                                     .out_x(int_out_x[2]), .out_y(int_out_y[2]), .out_z(int_out_z[2]),
                                     .step_ctr(step_ctr + 5'd2));
    stage  stage_3 (.in_x(int_out_x[2]), .in_y(int_out_y[2]), .in_z(int_out_z[2]),
                                     .z_coeff(z_coeff_3), .clk(clk), .reset(reset), .mode(mode),
                                     .out_x(out_x), .out_y(out_y), .out_z(out_z),
                                     .step_ctr(step_ctr + 5'd3));

endmodule: four_stages


/* Single stage that does the additions */
module stage
(
    input logic signed [`NUM_BITS-1:0] in_x, in_y, in_z, z_coeff,
    input logic clk, reset, mode,
    input logic [4:0] step_ctr,
    output logic signed [`NUM_BITS-1:0] out_x, out_y, out_z
);

    logic [`NUM_BITS-1:0] z_coeff_n, neg_z, z_coeff_d;
    logic [`NUM_BITS-1:0] x_coeff, x_coeff_n, neg_x, x_coeff_d;
    logic [`NUM_BITS-1:0] y_coeff, y_coeff_n, neg_y, y_coeff_d;
    logic to_case; // <- case on the sign of z(mode 0) or y(mode 1)

    assign to_case = mode ? ~in_y[`NUM_BITS-1] : in_z[`NUM_BITS-1];
    subtractor_ripple #(17) subz (.in_a(in_z), .in_b(z_coeff), .sub(~to_case),
                                  .out(out_z));

    // assign y_coeff = {{STAGE_NUM{in_y[`NUM_BITS-1]}}, in_y[`NUM_BITS-1:STAGE_NUM]};
    assign y_coeff = in_y >>> step_ctr;
    subtractor_ripple #(17) subx (.in_a(in_x), .in_b(y_coeff), .sub(~to_case),
                                  .out(out_x));
    // assign x_coeff = {{STAGE_NUM{in_x[`NUM_BITS-1]}}, in_x[`NUM_BITS-1:STAGE_NUM]};
    assign x_coeff = in_x >>> step_ctr;
    subtractor_ripple #(17) suby (.in_a(in_y), .in_b(x_coeff), .sub(to_case),
                                  .out(out_y));
endmodule: stage


// Subtractor that is based on a ripple full adder, just adds extra
// layer of subtraction decision logic. Subtract if sub=1, add if sub=0
module subtractor_ripple # (
    WIDTH=16)
    (input logic [WIDTH-1:0] in_a, in_b,
     input logic             sub,
     output logic [WIDTH-1:0] out);

    logic [WIDTH-1:0] modified_b, sub_extended;

    assign sub_extended = {(WIDTH){sub}};
    assign modified_b = sub_extended ^ in_b;

    adder_ripple #(WIDTH) inside_add (.in_a(in_a), .in_b(modified_b),
                          .c_in(sub), .out(out));

endmodule: subtractor_ripple

/* parametrized ripple carry adder */
module adder_ripple #(
    WIDTH=16)
    (input logic [WIDTH-1:0] in_a, in_b,
     input logic             c_in,
     output logic [WIDTH-1:0] out);

    assign out = in_a + in_b + c_in;

endmodule: adder_ripple

