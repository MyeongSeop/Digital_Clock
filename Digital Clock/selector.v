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
 *  File name  : selector.v
 *  Written by : Lim, Myeong Seop
 *               Student (2016313035)
 *               School of Software
 *               Sungkyunkwan University
 *  Written on : December 1, 2020
 *  Version    : 1.0
 *  Design     : Homework #4
 *               Design Selector Block for Digital Clock
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
 * MODULE : ALARM_SET
 *
 * Description:
 *   Alarm Set module works as alarm on Digital Clock.
 *   Alarm rings when user set's hour and minutes of time. 
 *   User can set hour and minutes of time by using ALARM_HOUR,
 *   ALARM_MIN mode. 
 *
 * Implementation:
 *   Alarm rings when Digital Clock's time is same as user's 
 *   managed clock. Alarm doesn't stops until user press set button.
 *   Also alarm doesn't start ring until user set's alarm time.
 *   Alarm rings again when alarm time comes again after 24 hours.
 *
 * Notes:
 *   (1) Initial state 00:00 is guaranteed by active low 
 *       asynchronous reset button: reset_n
 *   (2) After reset, alram doesn't work until user sets alarm time.
 *
 *-------------------------------------------------------------------*/

module ALARM_SET (
    input       clk, increase, set, reset_n,
    input [1:0] mode1, mode2,
    input [4:0] hours,
    input [5:0] mins, 

    output [4:0] alarm_h,
    output [5:0] alarm_m,
    output       alarm
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

// Outputs for SET_GEN block
reg inc_hour, inc_min;

// Outputs for ALARM_GEN block and module
reg [4:0] cur_alarm_h;
reg [5:0] cur_alarm_m;
reg cur_alarm;

/**
 * Registers used to decide alarm to run
 * is_set : 0 when alarm reset
 *          1 when alarm time set
 * is_on  : 0 when alarm doesn't start run
 *          1 when alarm start running
 */
reg is_set, is_on;

/*------------------------------------------
 * SET_GEN block for Design spec.
 * Consider when to increase hour and minute
 * by checking current mode1, mode2
 *-----------------------------------------*/
always @ (mode1 or mode2 or increase)
begin : SET_GEN
    /**
     * Set inc_hour, inc_min for alarm time modification
     */
    if ((mode1 == M1_ALARM) && (increase == 1)) begin
        if (mode2 == M2_ALARM_G) begin              // do nothing
            inc_hour = 0;
            inc_min = 0;
        end else if (mode2 == M2_ALARM_HOUR) begin // modify hour
            inc_hour = 1;
            inc_min = 0;
        end else begin                             // modify min
            inc_hour = 0;
            inc_min = 1;
        end
    end else begin // do nothing when its not ALARM mode
        inc_hour = 0;
        inc_min = 0;
    end
end

/*---------------------------------------------------
 * ALARM_GEN block for Design spec.
 * Works on rising clock edge and falling edge of reset_n,
 * modify alarm time and run alarm at alarm time
 *--------------------------------------------------*/
always @ (posedge clk, negedge reset_n)
begin : ALARM_GEN
    /**
     * Asynchronous reset, active low. 
     * Initialize alarm time to 00:00
     * Initialize is_set and is_on to 0.
     */
    if (~reset_n) begin
        cur_alarm_h <= 0;
        cur_alarm_m <= 0;
        cur_alarm <= 0;
        is_set <= 0;
        is_on <= 0;
    end else begin
        /**
         * When alarm time has been set, set is_set to 1 
         */
        if (mode1 == M1_ALARM && (mode2 == M2_ALARM_HOUR || 
                                     mode2 == M2_ALARM_MIN)) 
            is_set <= 1;
        /**
         * ALARM_HOUR mode. Update hour of alarm time.
         */
        if (inc_hour == 1) begin
            if (cur_alarm_h == 23) // If hour is 23, next hour is 0
                cur_alarm_h <= 0;
            else
                cur_alarm_h <= cur_alarm_h + 1'b1; // update hour
        /**
         * ALARM_MIN mode. Update min of alarm time.
         */
        end else if (inc_min == 1) begin
            if (cur_alarm_m == 59) // If min is 59 next min is 0
                cur_alarm_m <= 0;
            else 
                cur_alarm_m <= cur_alarm_m + 1'b1; // update min
        /**
         * Not alarm time modification mode and 'time == alarm time'
         */
        end else if (hours == cur_alarm_h && 
                         mins == cur_alarm_m) begin
            // If alarm time is set
            if (is_set == 1) begin
                if (is_on == 0) begin // Turn on alarm
                    cur_alarm <= 1;
                    is_on <= 1;
                /**
                 * If set switch is on, turn of alarm. 
                 * Else keep running the alarm.
                 */
                // set switch is off
                end else if (set == 0 && cur_alarm == 1) begin 
                    cur_alarm <= 1;    
                end else begin         // set switch is on
                    cur_alarm <= 0;
                end
            // If alarm time haven't set yet
            end else begin
                cur_alarm <= 0;
            end
        /**
         * After the alarm time, if alarm keeps running because 
         * set switch is not pushed, keep alarm runs until set is on. 
         */
        end else if (cur_alarm == 1 && is_set == 1) begin
            if (set == 0) begin  // set switch is off
                cur_alarm <= 1;
            end else begin       // set switch is on
                cur_alarm <= 0;
                is_on <= 0;
            end
        // If alarm is off, keep is off
        end else begin
            cur_alarm <= 0;
            is_on <= 0;
        end
    end
end

// Connect output and stored register
assign alarm_h = cur_alarm_h;
assign alarm_m = cur_alarm_m;
assign alarm = cur_alarm;

endmodule 

/*----------------------------------------------------------------------
 *
 * This module comment is reproduced from Min, Hyoung Bok's 
 * time.v file's module comment. 
 * Source: time.v, http://class.icc.skku.ac.kr/di/,
 * license: At web page above's homework submit board, 
 *          it is permitted for conditional resuse.
 *
 * MODULE : SELECTOR
 *
 * Description:
 *   Determines Alarm mode of Digital Clock.
 *   Decide output of the Digital Clock by clock's mode.
 *
 * Implementation:
 *   Call ALARM_SET module to do alarm mode in Digital Clock.
 *   Have 4 outputs since clock has 3 output and one for alarm.
 *   By checking current mode, decide output of the clock:
 *       TIME -> hours, mins, secs
 *       DATE -> mon, day, 00
 *       TIMER -> min_sw, sec_sw, secc_sw
 *       Alarm -> alarm_h, alarm_m, 00
 *
 * Notes:
 *   (1) Just need to represent output by current mode,
 *       clk, and reset_n is not necessary to decide output.
 *
 *-------------------------------------------------------------------*/
module SELECTOR (
    input       clk, increase, set, reset_n,
    input [1:0] mode1, mode2,
    input [4:0] hours,
    input [5:0] mins, secs,
    input [3:0] mon,
    input [4:0] day,
    input [5:0] min_sw, sec_sw,
    input [3:0] secc_sw,

    output [5:0] out_h, out_m, out_s,
    output       alarm
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

// wires need to get output from ALARM_SET module
wire [4:0] alarm_h;
wire [5:0] alarm_m;

// Registers to store outputs of module
reg [5:0] cur_out_h, cur_out_m, cur_out_s;

/**
 * Call ALARM_SET module to do alarm mode in Digital Clock.
 * Get output of alarm mode by using wire.
 * One fo the output 'alarm' is determined by this module.
 */
ALARM_SET alarm_set (
    .clk(clk),
    .increase(increase),
    .set(set),
    .reset_n(reset_n),
    .mode1(mode1),
    .mode2(mode2),
    .hours(hours),
    .mins(mins),
    .alarm_h(alarm_h),
    .alarm_m(alarm_m),
    .alarm(alarm)
);

/*---------------------------------------------------
 * Always block for deciding output of the Digital Clock.
 * Works on change in every inputs
 * Decide output by current mode (Major mode)
 *--------------------------------------------------*/
always @ (*) begin
    if (mode1 == M1_TIME) begin            // When TIME mode
        cur_out_h = hours;
        cur_out_m = mins;
        cur_out_s = secs;
    end else if (mode1 == M1_DATE) begin  // When DATE mode
        cur_out_h = mon;
        cur_out_m = day;
        cur_out_s = 2'b00;
    end else if (mode1 == M1_TIMER) begin // When TIMER mode
        cur_out_h = min_sw;
        cur_out_m = sec_sw;
        cur_out_s = secc_sw;
    end else begin                        // When ALARM mode
        cur_out_h = alarm_h;
        cur_out_m = alarm_m;
        cur_out_s = 2'b00;
    end
end

// Connect output to the stored register
assign out_h = cur_out_h;
assign out_m = cur_out_m;
assign out_s = cur_out_s;

endmodule