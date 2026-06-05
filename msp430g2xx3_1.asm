; --COPYRIGHT--,BSD_EX
;  Copyright (c) 2012, Texas Instruments Incorporated
;  All rights reserved.
; 
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
; 
;  *  Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
; 
;  *  Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
; 
;  *  Neither the name of Texas Instruments Incorporated nor the names of
;     its contributors may be used to endorse or promote products derived
;     from this software without specific prior written permission.
; 
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
;  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; 
; ******************************************************************************
;  
;                        MSP430 CODE EXAMPLE DISCLAIMER
; 
;  MSP430 code examples are self-contained low-level programs that typically
;  demonstrate a single peripheral function or device feature in a highly
;  concise manner. For this the code may rely on the device's power-on default
;  register values and settings such as the clock configuration and care must
;  be taken when combining code from several examples to avoid potential side
;  effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
;  for an API functional library-approach to peripheral configuration.
; 
; --/COPYRIGHT--
;******************************************************************************
;   MSP430G2xx3 - Software Toggle P1.0
;
;   Description: Toggle P1.0 by xor'ing P1.0
;   ACLK = n/a, MCLK = SMCLK = default DCO ~800kHz
;
;                MSP430G2xx3
;             -----------------
;         /|\|              XIN|-
;          | |                 |
;          --|RST          XOUT|-
;            |                 |
;            |             P1.0|-->LED
;
;   D. Dang
;   Texas Instruments Inc.
;   December 2010
;   Built with Code Composer Essentials Version: 4.2.0
;******************************************************************************
 .cdecls C,LIST,  "msp430.h"
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

;------------------------------------------------------------------------------
            .text                           ; Progam Start
;------------------------------------------------------------------------------
RESET       mov.w   #0280h,SP               ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT

;------------------------------------------------------------------------------
; Main loop here
;------------------------------------------------------------------------------

            bis.b   #1,&P1DIR               ; Set GPIO P1.0 (GREEN) to be an output
            bis.b   #64,&P1DIR              ; Set GPIO P1.6 (RED) to be an output

            bic.b   #1,&P1OUT               ; Clear P1.0 (GREEN)
            bic.b   #64,&P1OUT              ; Clear P1.6 (RED)

            bic.b   #8,&P1DIR               ; Set GPIO P1.3 to be an input

;                                            ; Configure GPIO resistors...
;            bis.b   #8,&P1REN               ; Set P1.3 to connect to pull-up/pull-down resistors
;            bis.b   #8,&P1OUT               ; Set P1.3 to pull up
; Seems not required - switch is pulled up by default.

                                            ; Configure GPIO interrupts...
            bis.b   #8,&P1IES               ; Set P1.3 to interrupt on high-to-low (button pressed)
            bic.b   #8,&P1IFG               ; Clear P1.3 interrupt flag
            bis.b   #8,&P1IE                ; Set P1.3 interrupts enabled

                                            ; Configure timers...
            bis     #TASSEL_1,&TA0CTL       ; TA0 source to ACLK (32 768 Hz)
            bis     #ID_0,&TA0CTL           ; TA0 divider to /1
            bis     #MC_1,&TA0CTL           ; TA0 mode to 1 (up to TA0CCR0)
            clr     &TA0CCR0                ; Clear TA0CCR0 (halt timer)
            bis     #TAIE,&TA0CTL           ; TA0 interrupt enable

            clr.b   R4                      ; Clear R4
            bis.b   #1,R4                   ; Set R4.0

            bis     #GIE,SR                 ; General interrupt enable

MainLoop    bit.b   #8,P1IN                 ; Is P1.3 closed (zero)?
            jz      Closed                  ; If yes, jump to Closed
                                            ; If no...
            bic.b   #64,&P1OUT              ; Clear P1.6 (RED)
            jmp     MainLoop                ; Again
                                            ;
Closed      bis.b   #64,&P1OUT              ; Set P1.6 (RED)
            jmp     MainLoop                ; Again

            ; P1 interrupt
P1_ISR      bic.b   #8,&P1IFG               ; Clear P1.3 interrupt flag
            xor.b   #1,R4                   ; XOR R4 bit 0
            jz      TimerOn                 ; If zero, timer on

            clr     &TA0CCR0                ; Clear TA0CCR0 (halt timer)
            RETI                            ; Return interrupt
            
TimerOn     bis     #0x7FFF, &TA0CCR0       ; TA0CCR0 to 32 767 (~1 second)
            RETI                            ; Return interrupt

            ; TA0 interrupt
TA0_ISR     bic     #TAIFG,&TA0CTL          ; TA0 interrupt flag clear
            xor.b   #1,&P1OUT               ; P1.0 (GREEN) toggle
            bic.b   R4,&P1OUT               ; If timer off, P1.0 (GREEN) off
            RETI

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET                   ;

            .sect   ".int02"                ; Interrupt vector PORT1 for GPIO P1 - see linker file "lnk_msp430g2553.cmd"
            .short  P1_ISR                  ;

            .sect   ".int08"                ; Interrupt vector for TAIFG, address 0FFE4h - see linker file "lnk_msp430g2553.cmd"
            .short  TA0_ISR                 ;

            .end                            ; Program end
