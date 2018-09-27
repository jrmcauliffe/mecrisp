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

; Extended memory access involving 20 bit values

  cpu msp430x

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "cx@" ; ( d -- c ) Fetch byte from double-address location
;------------------------------------------------------------------------------
  pushm.a #1, r10

    push @r4+
    push @r4
    mova @r1+, r10

    mov.b @r10, r10
    mov r10, @r4

  popm.a #1, r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "x@" ; ( d -- x ) Fetch from double-address location
;------------------------------------------------------------------------------
  pushm.a #1, r10

    push @r4+
    push @r4
    mova @r1+, r10

    mov @r10, @r4

  popm.a #1, r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "xx@" ; ( d -- d ) Fetch double-value from double-address location
;------------------------------------------------------------------------------
  pushm.a #1, r10

    push @r4
    push 2(r4)
    mova @r1+, r10

    movx.a @r10, @r4

  popm.a #1, r10
  br #swap_sprung

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "cx!" ; ( c d -- ) Store byte to double-address location
;------------------------------------------------------------------------------
  pushm.a #1, r10

    push @r4+
    push @r4+
    mova @r1+, r10

    mov.b @r4, @r10
    drop

  popm.a #1, r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "x!" ; ( x d -- ) Store to double-address location
;------------------------------------------------------------------------------
  pushm.a #1, r10

    push @r4+
    push @r4+
    mova @r1+, r10

    mov @r4+, @r10

  popm.a #1, r10
  ret

;------------------------------------------------------------------------------
  Wortbirne Flag_visible, "xx!" ; ( d d -- ) Store double-value to double-address location
;------------------------------------------------------------------------------
  pushm.a #1, r10

    push @r4+
    push @r4+
    mova @r1+, r10

    push @r4+
    push @r4+
    movx.a @r1+, @r10

  popm.a #1, r10
  ret

  cpu msp430
