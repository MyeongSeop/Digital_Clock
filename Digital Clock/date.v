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
 *  File name  : date.v
 *  Written by : Lim, Myeong Seop
 *               Student (2016313035)
 *               School of Software
 *               Sungkyunkwan University
 *  Written on : November 17, 2020
 *  Version    : 1.0
 *  Design     : Homework #3
 *               Design Date Block for time mode of Digital Clock
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
 * MODULE : DATE
 *
 * Description:
 *   Date show current month, day using input hour_carry.
 *   Also there exists DATE_MON, DATE_DAY mode which 
 *   sets month and day of date.
 *
 * Implementation:
 *   Date is updated automatically by using hour_carry as input,
 *   which is made from TIME mode.
 *   Date can represent month and date, and it dowsn't supports
 *   leap year. 
 *   Initial state of date is 01:01
 *
 * Notes:
 *   (1) Initial state 01:01 is guaranteed by an active low
 *       asynchronous reset input: reset_n
 *
 *-------------------------------------------------------------------*/

module DATE (
    input clk,
    input hour_carry,
    input increase,
    input reset_n,
    input [1:0] mode1,
    input [1:0] mode2,

    output [3:0] mon,
    output [4:0] day
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

// local parameters for January, February, August and December
localparam [3:0] Jan = 4'b0001,
                 Feb = 4'b0010,
                 Aug = 4'b1000,
                 Dec = 4'b1100;  
           
// Outputs for DATE_GEN block
reg [3:0] cur_mon;
reg [4:0] cur_day;

// Outputs for SET_GEN block
reg inc_mon, inc_day;
reg elapse_date;

/*------------------------------------------
 * SET_GEN block for Design spec.
 * Consider when to increase month and day
 * by checking current mode1, mode2
 *-----------------------------------------*/
always @ (mode1 or mode2 or increase) 
begin : SET_GEN
    /** 
     * Date modification act by sw2 and set switches
     */
    if ((mode1 == M1_DATE) && (increase == 1)) begin
        if (mode2 == M2_DATE_MON) begin           // modify month
            inc_mon <= 1;
            inc_day <= 0;
        end else if (mode2 == M2_DATE_DAY) begin  // modify day
            inc_mon <= 0;
            inc_day <= 1;
        end else begin                            // do nothing in general mode
            inc_mon <= 0;
            inc_day <= 0;
        end
    end else begin     // do nothing when its not TIME mode
        inc_mon <= 0;
        inc_day <= 0;
    end
    /**
     * Date modification act by time(clock) flow
     */
    if (mode1 == M1_DATE) begin
        if (mode2 == M2_DATE_G) 
            elapse_date <= 1;
        else
            elapse_date <= 0;
    end else begin 
        elapse_date <= 1;
    end
end

/*---------------------------------------------------
 * DATE_GEN block for Design spec.
 * Works on rising clock edge and falling edge of reset_n,
 * modify month and day by using inc_mon and inc_day.
 *--------------------------------------------------*/
always @ (posedge clk or negedge reset_n) 
begin : DATE_GEN
    /**
     * Asynchronous reset, active low. 
     * Initialize to 1, both month and day.
     */
    if (~reset_n) begin
        cur_mon <= 1;
        cur_day <= 1;
    end else begin
        /**
         * When mode2 is general mode and hour_carry is 1,
         * update month and day
         * While updating the month and day, have to consider
         * numbers of days are different for each month.
         */
        if ((elapse_date == 1) && (hour_carry == 1)) begin
            /*------------------------------------------------------
             * NOTE : Days of Month
             *
             * There is 2 exceptional case February and August.
             * The other month's days can be divided like......
             *     In February, number of days is 28.
             *     In August, number of days is 31.
             *     Before August, odd number month (1,3,5,7) -> 31days
             *                    even number month (4,6) -> 30 days
             *     After August, odd number month (9,11) -> 30 days
             *                   even number month (10,12) -> 31 days
             * In December, next month is Janurary. 
             *-----------------------------------------------------*/
            if (cur_mon == Feb) begin             // February
                if (cur_day == 28) begin          // last day of month
                    cur_mon <= cur_mon + 1'b1;
                    cur_day <= 1;
                end else begin                    // not last day of month
                   cur_day <= cur_day + 1'b1;
                end
            end else if (cur_mon == Aug) begin    // August
                if (cur_day == 31) begin          // last day of month
                    cur_mon <= cur_mon + 1'b1;
                    cur_day <= 1;
                end else begin                    // not last day of month
                   cur_day <= cur_day + 1'b1;
                end
            end else if (cur_mon == Dec) begin    // December
                if (cur_day == 31) begin          // last day of month
                    cur_mon <= 1;                 // Update to January
                    cur_day <= 1;
                end else begin
                   cur_day <= cur_day + 1'b1;     // not last day of month
                end
            end else if (cur_mon < 8) begin       // Before August
                if(cur_mon[0] == 1) begin         // odd number month(1,3,5,7)
                    if (cur_day == 31) begin
                        cur_day <= 1;
                        cur_mon <= cur_mon + 1'b1;
                    end else begin
                        cur_day <= cur_day + 1'b1;
                    end
                end else begin                    // even number month(4,6)
                    if (cur_day == 30) begin
                        cur_day <= 1;
                        cur_mon <= cur_mon + 1'b1;
                    end else begin
                        cur_day <= cur_day + 1'b1;
                    end
                end
            end else if (cur_mon > 8) begin       // After August
                if(cur_mon[0] == 0) begin         // even number month(10)
                    if (cur_day == 31) begin
                        cur_day <= 1;
                        cur_mon <= cur_mon + 1'b1;
                    end else begin
                        cur_day <= cur_day + 1'b1;
                    end
                end else begin                    // odd number month(9, 11)
                    if (cur_day == 30) begin
                        cur_day <= 1;
                        cur_mon <= cur_mon + 1'b1;
                    end else begin
                        cur_day <= cur_day + 1'b1;
                    end
                end
            end
        /**
         * DATE_MON mode(inc_mon is 1). update month
         */
        end else if (inc_mon == 1) begin
            if (cur_mon == Dec)
                cur_mon <= 1;
            else
                cur_mon <= cur_mon + 1'b1;
        /**
         * DATE_DAY mode(inc_day is 1). update day
         */
        end else if (inc_day == 1) begin
            if (cur_mon == Aug) begin             // August
                if (cur_day == 31) 
                    cur_day <= 1;
                else 
                    cur_day <= cur_day + 1'b1;
            end else if (cur_mon == Feb) begin    // February
                if (cur_day == 28) 
                    cur_day <= 1;
                else 
                    cur_day <= cur_day + 1'b1;
            end else if (cur_mon < 8) begin       // Before August
                if(cur_mon[0] == 1) begin         // odd number month(1,3,5,7)
                    if (cur_day == 31) 
                        cur_day <= 1;
                    else 
                        cur_day <= cur_day + 1'b1;
                end else begin                    // even number month(4,6)
                    if (cur_day == 30) 
                        cur_day <= 1;
                    else 
                        cur_day <= cur_day + 1'b1;
                end
            end else if (cur_mon > 8) begin        // After August
                if(cur_mon[0] == 0) begin          // even number month(10,12)
                    if (cur_day == 31) 
                        cur_day <= 1;
                    else 
                        cur_day <= cur_day + 1'b1;
                end else begin                     // odd number month(9,11)
                    if (cur_day == 30) 
                        cur_day <= 1;
                    else 
                        cur_day <= cur_day + 1'b1;
                end
            end
        end
    end
end

// Connect output and stored register
assign mon = cur_mon;
assign day = cur_day;

endmodule
