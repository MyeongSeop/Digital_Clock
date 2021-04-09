/*-------------------------------------------------------------------------
 *
 * This top comment is reproduced from Min, Hyoung Bok's 
 * time.v file's top comment. 
 * Source: time.v, http://class.icc.skku.ac.kr/di/,
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 *  Copyright (c) 2020 by Myeong Seop Lim, All rights reserved.
 *
 *  File name  : divider.c
 *  Written by : Lim, Myeong Seop
 *               Student (2016313035)
 *               School of Software
 *               Sungkyunkwan University
 *  Written on : December 1, 2020
 *  Version    : 1.0
 *  Design     : Homework #4
 *               Design Divider Block for Digital Clock
 *
 *  Modification History:
 *      * December 1, 2020  by Myeong Seop Lim
 *        v1.0 released.
 *
 *-------------------------------------------------------------------------*/

`timescale 1ns/1ps

/*----------------------------------------------------------------------
 *
 * This module comment is reproduced from Min, Hyoung Bok's 
 * time.v file's module comment. 
 * Source: time.v, http://class.icc.skku.ac.kr/di/,
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 * MODULE : DIVIDER
 *
 * Description:
 *   Make BCD (Binary Coded Decimal) to represent number into decimal.
 *   Need 2 digit for decimal number. (0 ~ 59)
 *
 * Implementation:
 *   Get single binary numer stored register and convert into decimal.
 *   Since largest number is 59 and smallest number is 0, 
 *   decimal is composed of 2 digit. 
 *   2 outputs: 
 *       bcd_h -> high digit of decimal number.
 *       bcd_l -> low digit of decimal number.
 *
 * Notes:
 *   (1) Since we just have to convert binary to decimal, 
 *       we don't need to care about clk, and asynchronous reset.
 *   (2)  0 <= binary <= 59
 *
 *-------------------------------------------------------------------*/
module DIVIDER (
    input  [5:0] binary,

    output [3:0] bcd_h,
    output [3:0] bcd_l
);

// Registers used to store output of module
reg [3:0] bcd_h_val;
reg [5:0] bcd_l_val;

/*---------------------------------------------------
 * Always block for changing bianry to decimal
 * Works on when binary number changes
 *--------------------------------------------------*/
always @ (*) begin
    if (binary >= 50) begin              // number: 50~59
        bcd_h_val = 5;
        bcd_l_val = binary - 6'b110010;
    end else if (binary >= 40) begin     // number: 40~49
        bcd_h_val = 4;
        bcd_l_val = binary - 6'b101000;
    end else if (binary >= 30) begin     // number: 30~39
        bcd_h_val = 3;
        bcd_l_val = binary - 5'b11110;
    end else if (binary >= 20) begin     // number: 20~29
        bcd_h_val = 2;
        bcd_l_val = binary - 5'b10100;
    end else if (binary >= 10) begin     // number: 10~19
        bcd_h_val = 1;
        bcd_l_val = binary - 4'b1010;
    end else begin                       // number: 0~9
        bcd_h_val = 0;
        bcd_l_val = binary;
    end
end

// Connect output values to stored register
assign bcd_h = bcd_h_val;
assign bcd_l = bcd_l_val[3:0];

endmodule