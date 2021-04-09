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
 *  File name  : timer.v
 *  Written by : Lim, Myeong Seop
 *               Student (2016313035)
 *               School of Software
 *               Sungkyunkwan University
 *  Written on : November 17, 2020
 *  Version    : 1.0
 *  Design     : Homework #3
 *               Design Timer Block for time mode of Digital Clock
 *
 *  Modification History:
 *      * November 17, 2020  by Myeong Seop Lim
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
 * MODULE : TIMER
 *
 * Description:
 *   Timer mesures certain time by using set switch. 
 *   Timer generates time as mins, sec, 0.1sec (secc).
 *
 * Implementation:
 *   Timer have to use counter for clock system to increase time.
 *   Timer's initial value is 00:00:00. 
 *   When Timer starts, time keep increases until 59:59:09.
 *   When Timer stops, time stops increasing. 
 *   At General mode, time resets to 00:00:00.
 *
 * Notes:
 *   (1) Initial state 00:00:00 is guaranteed by an active low
 *       asynchronous reset input: reset_n
 *   (2) Maximum time of timer is 59:59:09
 *   (3) Low bound of timer's time measurement is 0.1 second
 *
 *-------------------------------------------------------------------*/

module TIMER (
    input clk,
    input reset_n,
    input [1:0] mode1,
    input [1:0] mode2,

    output [5:0] min_sw,
    output [5:0] sec_sw,
    output [3:0] secc_sw
);

/*-------------------------------------------------------
 *
 * dclockshare.v file is reproduced from Min, Hyoung Bok
 * Source: http://class.icc.skku.ac.kr/di/
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 * Description & Usage:
 *   Definition of mode1 and mode2 values
 *
 *-----------------------------------------------------*/
`include "dclockshare.v"

/*------------------------------------------------------
 * Function 'bits_required' returns number of bits
 * for given integer number.
 * If input integer value is N, returns lg(N+1).
 * 
 * This function code was written by modifying
 * "time.v" file written by Min, Hyoung Bok.
 * Source: time.v, http://class.icc.skku.ac.kr/di/
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 *----------------------------------------------------*/
function integer bits_required (
    input integer val
);
integer result, remainder;
begin
    result = 0;
    remainder = val;
    while (remainder > 0) begin    // loop for calculating number of bits
        result = result + 1;
        remainder = remainder / 2; // decreasing number
    end
    bits_required = result;
end
endfunction

/**
 * CLOCK4SECC means required system clock count for 0.1 second
 * Because of using 100Hz system, 10 clock count is same as 0.1 second
 */parameter  CLOCKS4SECC = 10;

/**
 * local parameters
 * MAX_COUNT means needed MAX_COUNT for updating time.
 * NUM_BITS means required bits to store count clock.
 */
localparam MAX_COUNT = CLOCKS4SECC-1;
localparam NUM_BITS = bits_required(CLOCKS4SECC-1);

// regisger for counting clock
reg [NUM_BITS-1:0] count10;

// Outputs for SET_GEN
reg inc_start, inc_init;

//Outputs for TIMER_GEN
reg [5:0] cur_min; 
reg [5:0] cur_sec;
reg [3:0] cur_secc;

/*--------------------------------------------------------
 * SET_GEN for Design spec.
 * Consider when to update time by checking mode1, mode2
 * When inc_start is 1, time increases.
 * When inc_init is 1, time initialized to 00:00:00.
 *-------------------------------------------------------*/
always @ (mode1 or mode2) 
begin : SET_GEN
    if (mode1 == M1_TIMER) begin
        if (mode2 == M2_TIMER_G) begin              // initialize
            inc_start <= 0;
            inc_init <= 1;
        end else if (mode2 == M2_TIMER_START) begin // time increase
            inc_start <= 1;
            inc_init <= 0;
        end else begin                              // do nothing
            inc_start <= 0;
            inc_init <= 0;
        end
    end else begin       // initialize when mode1 is not TIMER
        inc_start <= 0;
        inc_init <= 1;
    end
end

/*--------------------------------------------------------
 * TIMER_GEN for Design spec.
 * Works on rising edge of clk, and falling edge of reser_n
 * Increase time and initialize time:
 *     Count using count10 for increase 0.1 second (secc).
 *     Count 10 secc to increase second.
 *     Count 60 second to increase min.
 *-------------------------------------------------------*/
always @ (posedge clk, negedge reset_n) 
begin : TIMER_GEN
    /**
     * Asynchronous reset, active low.
     * Initialize all value to 0.
     */
    if (~reset_n) begin
        cur_min <= 0;
        cur_sec <= 0;
        cur_secc <= 0;
        count10 <= 0;
    end else begin
        /**
         * When inc_init is 1, initialize
         */
        if (inc_init == 1) begin
           cur_min <= 0;
           cur_sec <= 0;
           cur_secc <= 0; 
           count10 <= 0;
        /**
         * When inc_start is 1, start increasing time
         */
        end else if (inc_start == 1) begin
            
            /**
             * If count10 is MAX_COUNT, add 0.1second (secc)
             */
            if (count10 == MAX_COUNT) begin
                count10 <= 0;  // initialize count register
                if (cur_secc == 9) begin
                    cur_secc <= 0;
                    if (cur_sec == 59) begin
                        cur_sec <= 0;
                        if (cur_min == 59) begin // Initialize overflow
                            cur_min <= 0;
                        end else begin // min < 59
                            cur_min <= cur_min + 1'b1;
                        end
                    end else begin // sec < 59
                        cur_sec <= cur_sec + 1'b1;
                    end
                end else begin // secc < 9
                    cur_secc <= cur_secc + 1'b1;
                end
            end else if (count10 < MAX_COUNT) begin // update count
                count10 <= count10 + 1'b1;
            end
        end 
    end

end

// Connect output and stored register
assign min_sw = cur_min;
assign sec_sw = cur_sec;
assign secc_sw = cur_secc;

endmodule
