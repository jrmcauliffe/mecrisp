;
;    Mecrisp - A native code Forth implementation for MSP430 microcontrollers
;    Copyright (C) 2011  Matthias Koch
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

; Main file for Mecrisp for MSP430FR2355.

;------------------------------------------------------------------------------
; Base Definitions
;------------------------------------------------------------------------------
  cpu msp430
  include "../common/mspregister.asm"
  include "../common/datastack.asm"

;------------------------------------------------------------------------------
; Memory map
;------------------------------------------------------------------------------

RamAnfang   equ  2000h ; Start of RAM
RamEnde     equ  3000h ; End of RAM, 4 kb
FlashAnfang equ 08000h ; Start of Flash, 32 kb, Flash end always is $FFFF.

  org 0D200h          ; Start of Forth kernel. Needs to be on a 512 byte boundary !

;------------------------------------------------------------------------------
; Prepare Dictionary
;------------------------------------------------------------------------------

  include "../common/forth-core.asm"  ; Include everything of Mecrisp

;------------------------------------------------------------------------------
; Include chip specific terminal & interrupt hooks code
;------------------------------------------------------------------------------

  include "terminal.asm"
  include "fram.asm"
  include "interrupts.asm"

;------------------------------------------------------------------------------
Reset: ; Main entry point. Chip specific initialisations go here.
;------------------------------------------------------------------------------

  mov #5A80h, &WDTCTL ; Watchdog off

  include "../common/catchflashpointers.asm" ; Setup stacks and catch dictionary pointers

  ; Now it is time to initialize hardware. (Porting: Change this !)

  ; Backchannel UART communication over
  ; P4.3: UCA1TXD TXD
  ; P4.2: UCA1RXD RXD
  ; with 115200 Baud and 8 MHz clock

  ;------------------------------------------------------------------------------
  ; Init Clock

  mov.w #0A520h, &01A0h             ; Enable FRCTL0 and set NWAITS to 2 (24mhz)
  mov.b #0Fh, &01A1h                ; Disable FRCTL0 access (upper byte w)

  bis.w #40h, r2
  mov.b #3Fh, &205h                 ; P2.6 & 2.7 DIR
  mov.b #0C0h, &20Dh                ; P2.6 & 2.7 P1SEL
  mov.w #08ECh, &18Ch               ; Configure XT1 settings in CSCTL6
  bis.w #2, &188h                   ; Enable XT1CLK for MCLK src in CSCTL4

- bic.w #03h, &18Eh                 ; clear dco and xtal fault in CSCTL7
  bic.w #02h, &102h                 ; clear xtal intr fault in SFRIFG1
  bit.w #02h, &102h                 ; check xtal intr fault in SFTIFG1
  jnz -

  ;------------------------------------------------------------------------------
  ; Init IO

  bic   #LOCKLPM5, &PM5CTL0         ; Unlock I/O pins
  mov.b #8+4, &P4SEL0               ; Configure UART pins P4.2, P4.3
  ;------------------------------------------------------------------------------
  ; Init serial communication

  mov #UCSWRST, &UCA1CTLW0          ; **Put state machine in reset**
  bis #UCSSEL__SMCLK, &UCA1CTLW0    ; SMCLK

  mov #0Dh, &UCA1BRW                ; 24 MHz 115200 Baud
  mov #2501h, &UCA1MCTLW            ; Modulation UCBRSx=25h, UCBRFx=0, UCOS16

  bic #UCSWRST, &UCA1CTLW0          ; **Initialize USCI state machine**
  ;------------------------------------------------------------------------------

  welcome " for MSP430FR2355 by Matthias Koch"

  ; Initialisation is complete. Ready to fly ! Prepare to enter Forth:

  include "../common/boot.asm"
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;           Interrupt vectors of FR2355
;------------------------------------------------------------------------------

 org 0FF80h ; Protection Signatures

  .word   0FFFFh  ; JTAG-Signature 1
  .word   0FFFFh  ; JTAG-Signature 2
  .word   0FFFFh  ; BSL-Signature 1
  .word   0FFFFh  ; BSL-Signature 2
  .word   0FFFFh  ; BSL Config Signature
  .word   0FFFFh  ; BSL Config
  .word   0FFFFh  ; BSL I2C Address


 org 0FFCEh ; Interrupt table with hooks

  .word   irq_vektor_port4     ; 39: 0FFCE  Port 4
  .word   irq_vektor_port3     ; 40: 0FFD0  Port 3
  .word   irq_vektor_port2     ; 41: 0FFD2  Port 2
  .word   irq_vektor_port1     ; 42: 0FFD4  Port 1
  .word   irq_vektor_sac13     ; 43: 0FFD6  SAC1, SAC3
  .word   irq_vektor_sac02     ; 44: 0FFD8  SAC0, SAC2
  .word   irq_vektor_comp      ; 45: 0FFDA  Comp
  .word   irq_vektor_adc       ; 46: 0FFDC  ADC
  .word   irq_vektor_uscib1    ; 47: 0FFDE  USCIB1
  .word   irq_vektor_uscib0    ; 48: 0FFE0  USCIB0
  .word   irq_vektor_uscia1    ; 49: 0FFE2  USCIA1
  .word   irq_vektor_uscia0    ; 50: 0FFE4  USCIA0
  .word   irq_vektor_watchdog  ; 51: 0FFE6  Watchdog
  .word   irq_vektor_rtc       ; 52: 0FFE8  RTC
  .word   irq_vektor_timerd1   ; 53: 0FFEA  Timer 3 CCR1, TAIV
  .word   irq_vektor_timerd0   ; 54: 0FFEC  Timer 3 CCR0
  .word   irq_vektor_timerc1   ; 55: 0FFEE  Timer 2 CCR1, TAIV
  .word   irq_vektor_timerc0   ; 56: 0FFF0  Timer 2 CCR0
  .word   irq_vektor_timerb1   ; 57: 0FFF2  Timer 1 CCR1, CCR2, TAIV
  .word   irq_vektor_timerb0   ; 58: 0FFF4  Timer 1 CCR0
  .word   irq_vektor_timera1   ; 59: 0FFF6  Timer 0 CCR1, CCR2, TAIV
  .word   irq_vektor_timera0   ; 60: 0FFF8  Timer 0 CCR0
  .word   null_handler         ; 61: 0FFFA  User NMI. Unused.
  .word   null_handler         ; 62: 0FFFC  System NMI. Unused.
  .word   Reset                ; 63: 0FFFE  Main entry point

end
