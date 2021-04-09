/*-------------------------------------------------------------------------
 *
 *  Copyright (c) 2018 by Hyoung Bok Min, All rights reserved.
 *  For license information, please refer to
 *      http://class.icc.skku.ac.kr/~min/ds/license.html
 *
 *  File name  : dclock.v
 *  Written by : Min, Hyoung Bok
 *               Professor (Students write her/his student-id number)
 *               School of Electrical Engineering
 *               Sungkyunkwan University
 *  Written on : July 11, 2018
 *  Design     : Homework #4
 *               Digital Clock Design Project
 *               This is top level model
 *
 *  Modification History:
 *      * July 11, 2018  by Hyoung Bok Min
 *        v1.0 released.
 *
 *-------------------------------------------------------------------------*/

`timescale 1ns/1ps

/*----------------------
 * MODULE : DIGITAL_CLOCK
 *
 * Description:
 *   DIGITAL_CLOCK is top level model of the digital clock.
 *
 * Implementation:
 *   DIGITAL_CLOCK is a collection of all the components such as MODE_GEN,
 *   TIME, DATE, TIMER, etc.
 *
 *--------------------*/

module DIGITAL_CLOCK
    // CLOCKS4SEC : number of clocks in order to measure a second
    #(parameter CLOCKS4SEC = 100) (
    input clk,       // system clock and time base
    input set,       // adjust time/date/alarm time
    input sw1,       // choose 4 major modes (TIME, DATE, TIMER, ALARM)
    input sw2,       // choose minor modes depending on major mode
    input reset_n,   // master reset, active low

    output [6:0] seg_hh,   // higher digit of 7-segments for hours/months, etc
    output [6:0] seg_hl,   // lower digit of 7-segments for hours/months, etc
    output [6:0] seg_mh,   // higher digit of 7-segments for minutes/days, etc
    output [6:0] seg_ml,   // lower digit of 7-segments for minutes/days, etc
    output [6:0] seg_sh,   // higher digit of 7-segments for seconds, etc
    output [6:0] seg_sl,   // lower digit of 7-segments for seconds, etc
    output alarm           // alarm rings if 1
);

/*-------------------------------------------
 *  Internal signals
 *-------------------------------------------*/
// Operating Modes (states)
wire [1:0] mode1, mode2;
wire increase;

// TIME block outputs : hours / mins / secs
wire [4:0] hours;
wire [5:0] mins, secs;
wire hour_carry;

// DATE block outputs : mon / day
wire [3:0] mon;
wire [4:0] day;

// TIMER block outputs : min_sw / sec_sw / secc_sw
wire [5:0] min_sw, sec_sw;
wire [3:0] secc_sw;

// Binary value of hours/mins/secs, etc
wire [5:0] out_h, out_m, out_s;

// BCD display of hours/mins/secs, mon/DATE/0000, ...
wire [3:0] bcd_hh, bcd_hl;
wire [3:0] bcd_mh, bcd_ml;
wire [3:0] bcd_sh, bcd_sl;


/*-------------------------------------------
 *  Instantiations
 *-------------------------------------------*/
// MODE generator
MODE_GEN  U01 (
    .clk(clk),           // input: system clock and time base
    .sw1(sw1),           // input: cycle thru TIME/DATE/TIMER/ALARM
    .sw2(sw2),           // input: minor mode depending on the above
    .set(set),           // input: increase values of time, date, etc
    .reset_n(reset_n),   // input: master reset, active low
    .mode1(mode1),       // output: the mode chosen by sw1
    .mode2(mode2),       // output: the mode chosen by sw2
    .increase(increase)  // output: 1 if increase by set is needed
);

// Time block
TIME #(.CLOCKS4SEC(CLOCKS4SEC)) U02 (

    .clk(clk),               // input: system clock
    .increase(increase),     // input: 1 if need increasing hours, mins,secs 
    .reset_n(reset_n),       // input: master reset, active low
    .mode1(mode1),           // input: major mode, one of TIME/DATE/TIMER/...
    .mode2(mode2),           // input: minor mode, one of GEN/TIME_HOUR/...
    .hours(hours),           // output: current hours of day
    .mins(mins),             // output: current minutes
    .secs(secs),             // output: current seconds
    .hour_carry(hour_carry)  // output: 1 if day should be increased
);

// Date block
DATE  U03 (
    .clk(clk),                 // input: system clock
    .hour_carry(hour_carry),   // input: 1 if time is 23:59:59 => 00:00:00
    .increase(increase),       // input: 1 if increased mon/day by set button
    .reset_n(reset_n),         // input: master reset, active low
    .mode1(mode1),             // input: one of 4 major modes
    .mode2(mode2),             // input: minor mode depending on mode1
    .mon(mon),                 // output: month
    .day(day)                  // output: day
);

// Timer block
TIMER  U04 (
    .clk(clk),           // input: system clock
    .reset_n(reset_n),   // input: master reset, active low
    .mode1(mode1),       // input: major mode, one of TIME/DATE/TIMER/ALARM
    .mode2(mode2),       // input: minor mode, GEN/START/STOP for TIMER
    .min_sw(min_sw),     // output: timer minutes
    .sec_sw(sec_sw),     // output: timer seconds
    .secc_sw(secc_sw)    // output: timer 1/10 seconds
);

// Display selector and ALARM generator
SELECTOR  U05 (
    .clk(clk),            // input: system clock
    .increase(increase),  // input: increase alarm hours/minutes if this is 1
    .set(set),            // input: snooze button
    .reset_n(reset_n),    // input: asynchronous reset, active low
    .mode1(mode1),        // input: major modes
    .mode2(mode2),        // input: inputs // minor modes
    .hours(hours),        // input: current hours
    .mins(mins),          // input: current minutes 
    .secs(secs),          // input: inputs // current seconds
    .mon(mon),            // input: month of this day
    .day(day),            // input: day of this day
    .min_sw(min_sw),      // input: timer minutes
    .sec_sw(sec_sw),      // input: timer seconds
    .secc_sw(secc_sw),    // input: timer 1/10 seconds
    .out_h(out_h),        // output: 4-to-1 mux output for hours/mon/alarm_h
    .out_m(out_m),        // output: 4-to-1 mux output for mins/day/alarm_m
    .out_s(out_s),        // output: 4-to-1 mux output for secs/0/0
    .alarm(alarm)         // outpyt: 1 if alarm rings
);

// Binary to BCD converters
DIVIDER  U06 (.binary(out_h), .bcd_h(bcd_hh), .bcd_l(bcd_hl));
DIVIDER  U07 (.binary(out_m), .bcd_h(bcd_mh), .bcd_l(bcd_ml));
DIVIDER  U08 (.binary(out_s), .bcd_h(bcd_sh), .bcd_l(bcd_sl));

// LED display drivers (BCD to 7-segment converters)
LED_DRIVER  U09 (.led_in(bcd_hh), .led_out(seg_hh));
LED_DRIVER  U10 (.led_in(bcd_hl), .led_out(seg_hl));
LED_DRIVER  U11 (.led_in(bcd_mh), .led_out(seg_mh));
LED_DRIVER  U12 (.led_in(bcd_ml), .led_out(seg_ml));
LED_DRIVER  U13 (.led_in(bcd_sh), .led_out(seg_sh));
LED_DRIVER  U14 (.led_in(bcd_sl), .led_out(seg_sl));

endmodule

/*--- DIGITAL_CLOCK ---*/
