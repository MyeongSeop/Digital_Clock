/*-------------------------------------------------------------------------
 *
 * This top comment is reproduced from Min, Hyoung Bok's 
 * adder2.v file's module comment. 
 * Source: adder2.v, http://class.icc.skku.ac.kr/di/,
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 *  Copyright (c) 2020 by Myeong Seop Lim, All rights reserved.
 *
 *  File name  : mode_gen.v
 *  Written by : Lim, Myeong Seop
 *               Student (2016313035)
 *               School of Software
 *               Sungkyunkwan University
 *  Written on : November 2, 2020
 *  Version    : 1.0
 *  Design     : Mode Generator for Digital Clock Chip:
 *               Time, Date, Timer, Alarm
 *
 *  Modification History:
 *      * November 2, 2020  by Myeong Seop Lim
 *        v1.0 released.
 *
 *-------------------------------------------------------------------------*/

`timescale 1ns/1ps

/*---------------------------
 *
 * This module comment is reproduced from Min, Hyoung Bok's 
 * adder2.v file's module comment. 
 * Source: adder2.v, http://class.icc.skku.ac.kr/di/,
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 * Module: MODE_GEN
 *
 * Description:
 *   This is an implementation of a Mode Generator for Digital Clock.
 *   4 Major modes: TIME, DATE, TIMER, ALARM mode exists.
 *   3 or 4 Minor modes exists for each Major mode.
 *   Changes mode when input signal comes in.
 *
 *--------------------------*/
module MODE_GEN (
    input clk,
    input sw1,
    input sw2,
    input set,
    input reset_n,

    output [1:0] mode1,
    output [1:0] mode2,
    output increase
);

/*---------------------------
 *
 * This comment is reproduced from Min, Hyoung Bok's 
 * adder2.v file comment. 
 * Source: adder2.v, http://class.icc.skku.ac.kr/di/,
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 *
 * Include File: dclockshare.v
 *
 * dclockshare.v file is reproduced from Min, Hyoung Bok
 * Source: http://class.icc.skku.ac.kr/di/
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 * Description & Usage:
 *   Contains Constants, tasks, etc for design and testbench
 *   Use Constants for mode1 and mode2 :
 *       M1_TIME, M1_DATE, M1_TIMER, M1_ALARM
 *       M2_TIME_G, M2_TIME_HOUR, M2_TIME_MIN, M2_TIME_SEC
 *       M2_DATE_G, M2_DATE_MON, M2_DATE_DAY
 *       M2_TIMER_G, M2_TIMER_START, M2_TIMER_STOP
 *       M2_ALARM_G, M2_ALARM_HOUR, M2_ALARM_MIN
 *
 *--------------------------*/
`include "dclockshare.v"

/**
 * Registers for save values of current mode
 * mode1_get saves 4 major modes
 * mode2_get saves 3 or 4 minor modes
 * M1_TIME and M2_TIME_G is initial mode for Digital Clock
 */
reg [1:0] mode1_get = M1_TIME;
reg [1:0] mode2_get = M2_TIME_G;

// Register for save value of increase
reg increase_get = 1'b0;

/** 
 * Register for determine increase value.
 * Update to 1 when increase need to be changed to 1.
 * Else, update to 0.
 */
reg flag = 1'b0;

/**
 * On rising clock edge or falling reset_n edge check input
 * and update Major mode and Minor mode.
 * Also update flag register to determine increase
 */
always @(posedge clk or negedge reset_n) begin
    // Asynchronous reset to initial Major and minor mode
    if (~reset_n) begin
        mode1_get <= M1_TIME;
        mode2_get <= M2_TIME_G;
    end else begin
        // Upadte Major and Minor mode when sw1 signal comes in
        if (sw1 === 1'b1 && sw2 === 1'b0) begin

            // Update Major mode to DATE mode
            if ( mode1_get === M1_TIME ) begin   
                mode1_get <= M1_DATE;
                mode2_get <= M2_DATE_G;

            // Update Major mode to TIMER mode
            end else if (mode1_get === M1_DATE) begin
                mode1_get <= M1_TIMER;
                mode2_get <= M2_TIMER_G;

            // Update Major mode to ALARM mode
            end else if (mode1_get === M1_TIMER) begin
                mode1_get <= M1_ALARM;
                mode2_get <= M2_ALARM_G;

            // Update Major mode to TIME mode
            end else begin
                mode1_get <= M1_TIME;
                mode2_get <= M2_TIME_G;
            end

        // Update Minor mode when sw2 signal comes in
        end else if (sw1 === 1'b0 && sw2 === 1'b1) begin
            // If Major mode is TIME
            if (mode1_get === M1_TIME) begin
                if (mode2_get === M2_TIME_G)         // to TIME_HOUR mode
                    mode2_get <= M2_TIME_HOUR; 
                else if (mode2_get === M2_TIME_HOUR) // to TIME_MIN mode
                    mode2_get <= M2_TIME_MIN;
                else if (mode2_get === M2_TIME_MIN)  // to TIME_SEC mode
                    mode2_get <= M2_TIME_SEC;
                else 
                    mode2_get <= M2_TIME_G;           // to TIME_G mode

            // If Major mode is DATE
            end else if (mode1_get === M1_DATE) begin
                if (mode2_get === M2_DATE_G)         // to DATE_MON mode
                    mode2_get <= M2_DATE_MON;
                else if (mode2_get === M2_DATE_MON)  // to DATE_DAY mode
                    mode2_get <= M2_DATE_DAY;
                else 
                    mode2_get <= M2_DATE_G;           // to DATE_G mode

            // If Major mode is TIMER
            end else if (mode1_get === M1_TIMER) begin
                if (mode2_get === M2_TIMER_G)          // to TIMER_START mode
                    mode2_get <= M2_TIMER_START;
                else if (mode2_get === M2_TIMER_START) // to TIMER_STOP mode
                    mode2_get <= M2_TIMER_STOP;
                else 
                    mode2_get <= M2_TIMER_G;            //  to TIMER_G mode

            // If Major mode is ALARM
            end else begin
                if (mode2_get === M2_ALARM_G)          // to ALARM_HOUR mode
                    mode2_get <= M2_ALARM_HOUR;
                else if (mode2_get === M2_ALARM_HOUR)   // to ALARM_MIN mode
                    mode2_get <= M2_ALARM_MIN;
                else 
                    mode2_get <= M2_ALARM_G;            // to ALARM_G mode
            end

        // If both signal is 1 or 0, remain current mode
        end else begin
            mode1_get <= mode1_get;
            mode2_get <= mode2_get;
        end

        /** 
         * Check current mode when set is 1 and increase is 0 and flag is 0
         * If Major mode is TIME or DATE ro ALARM and
         * Minor mode is not General (*_G mode) update flag to 1.
         * Else update flag to 0
         */
        if (set === 1'b1 && sw1 === 1'b0 && sw2 === 1'b0) begin
            if (mode1_get === M1_TIME && mode2_get !== M2_TIME_G) 
                flag <= 1'b1;
            else if (mode1_get === M1_DATE && mode2_get !== M2_DATE_G) 
                flag <= 1'b1;
            else if (mode1_get === M1_ALARM && mode2_get !== M2_ALARM_G) 
                flag <= 1'b1;
            else 
                flag <= 1'b0;
        end else begin
            flag <= 1'b0;
        end
    end
end

/**
 * On falling clock edge,
 * update increase value to 1 when flag is 0 and increase is 0,
 * update increase value to 0 when increase is 1.
 */
always @(negedge clk) begin
    // Upadte increase_get to 1
    if (flag === 1'b1 && increase_get === 1'b0)
        increase_get <= 1'b1;

    // Ipdate increase get to 0
    else 
        increase_get <= 1'b0;
end

/**
 * Assign stored Major mode and Minor mode value to the mode1 and mode 2
 * Assign stored increase value to increase
 */
assign mode1 = mode1_get;
assign mode2 = mode2_get;
assign increase = increase_get;

endmodule
