// CMU ECE 18-340 - Spring 2014
// Project 4: CORDIC Implementation
//
// This file contains a number of Verilog defines for use in your project.

// You can implement the optional "Vectoring mode" for extra credit
`define MODE_ROTATION   1'b0
`define MODE_VECTORING  1'b1

// We store angles in radians, in units of radians/32768
// Here are some common angles that you can use for testing:
`define ANGLE_PI_OVER_2_RAD     17'd51472   // 90 degrees
`define ANGLE_PI_OVER_3_RAD     17'd34315   // 60 degrees
`define ANGLE_PI_OVER_4_RAD     17'd25736   // 45 degrees
`define ANGLE_PI_OVER_6_RAD     17'd17157   // 30 degrees

// We do 16 CORDIC iterations, which requires four bits to count
`define NUM_ITER        16
`define NUM_ITER_BITS   4

// It's generally a good idea to match the number of iterations with
// the number of bits you use. Since 2C has effectively one bit for the
// sign, we use 17 bits total for both the X- and Y-coordinates, as well
// as the angles.
`define NUM_BITS        17

// Because the CORDIC doesn't do true circular rotations (only linear pseudo-
// rotations) the length of the vector changes by small amount with each
// rotation. For a given set of CORDIC rotation angles we can compute this
// value (usually denoted K) with this product:
// K = PRODUCT( SQRT(1 + tan^2 alpha_i) )
// This depends on the rotation angles alpha_i, and converges to ~1.646760.
// The CORDIC gain is used to scale or pre-set the hardware for operation.
`define CORDIC_GAIN         17'd53961
`define CORDIC_GAIN_INV     17'd19898

// These are the values rotation angles for each iteration. Each
// angle is atan(2^(-i)) for i = 0:15, converted to our number format by
// multiplying by 32768, and then rounding it off.
`define CORDIC_ANGLE_00     17'd25736
`define CORDIC_ANGLE_01     17'd15193
`define CORDIC_ANGLE_02     17'd8027
`define CORDIC_ANGLE_03     17'd4075
`define CORDIC_ANGLE_04     17'd2045
`define CORDIC_ANGLE_05     17'd1024
`define CORDIC_ANGLE_06     17'd512
`define CORDIC_ANGLE_07     17'd256
`define CORDIC_ANGLE_08     17'd128
`define CORDIC_ANGLE_09     17'd64
`define CORDIC_ANGLE_10     17'd32
`define CORDIC_ANGLE_11     17'd16
`define CORDIC_ANGLE_12     17'd8
`define CORDIC_ANGLE_13     17'd4
`define CORDIC_ANGLE_14     17'd2
`define CORDIC_ANGLE_15     17'd1

