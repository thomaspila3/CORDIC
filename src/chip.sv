`default_nettype none

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    
    tt_um_cordic_wrapper c_wrapper (.clk(clock), .rst(reset), .in_val(io_in[9:0]), .mode_toggle(io_in[10]),
                                    .out_toggle(io_in[11]), .val(io_out[10:0]), .done(io_out[11]));

endmodule
