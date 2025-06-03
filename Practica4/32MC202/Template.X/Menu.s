/*
 * File:   %<%NAME%>%.%<%EXTENSION%>%
 * Author: %<%USER%>%
 *
 * Created on %<%DATE%>%, %<%TIME%>%
 */

    .include "p33fj32mc202.inc"

    ; _____________________Configuration Bits_____________________________
    ;User program memory is not write-protected
    #pragma config __FGS, GWRP_OFF & GSS_OFF & GCP_OFF
    
    ;Internal Fast RC (FRC)
    ;Start-up device with user-selected oscillator source
    #pragma config __FOSCSEL, FNOSC_FRC & IESO_ON
    
    ;Both Clock Switching and Fail-Safe Clock Monitor are disabled
    ;XT mode is a medium-gain, medium-frequency mode that is used to work with crystal
    ;frequencies of 3.5-10 MHz //Datacheet
    #pragma config __FOSC, FCKSM_CSECME & POSCMD_XT
    
    ;Watchdog timer enabled/disabled by user software
    #pragma config __FWDT, FWDTEN_OFF
    
    ;POR Timer Value
    #pragma config __FPOR, FPWRT_PWR128
   
    ; Communicate on PGC1/EMUC1 and PGD1/EMUD1
    ; JTAG is Disabled
    #pragma config __FICD, ICS_PGD1 & JTAGEN_OFF

;..............................................................................
;Program Specific Constants (literals used in code)
;..............................................................................

    .equ SAMPLES, 64         ;Number of samples



;..............................................................................
;Global Declarations:
;..............................................................................

    .global _wreg_init       ;Provide global scope to _wreg_init routine
                                 ;In order to call this routine from a C file,
                                 ;place "wreg_init" in an "extern" declaration
                                 ;in the C file.

    .global __reset          ;The label for the first line of code.

;..............................................................................
;Constants stored in Program space
;..............................................................................

    .section .myconstbuffer, code
    .palign 2                ;Align next word stored in Program space to an
                                 ;address that is a multiple of 2
ps_coeff:
    .hword   0x0002, 0x0003, 0x0005, 0x000A




;..............................................................................
;Uninitialized variables in X-space in data memory
;..............................................................................

    .section .xbss, bss, xmemory
x_input: .space 2*SAMPLES        ;Allocating space (in bytes) to variable.



;..............................................................................
;Uninitialized variables in Y-space in data memory
;..............................................................................

    .section .ybss, bss, ymemory
y_input:  .space 2*SAMPLES




;..............................................................................
;Uninitialized variables in Near data memory (Lower 8Kb of RAM)
;..............................................................................

    .section .nbss, bss, near
var1:     .space 2               ;Example of allocating 1 word of space for
                                 ;variable "var1".




;..............................................................................
;Code Section in Program Memory
;..............................................................................

.text                             ;Start of Code section
__reset:
    MOV #__SP_init, W15       ;Initalize the Stack Pointer
    MOV #__SPLIM_init, W0     ;Initialize the Stack Pointer Limit Register
    MOV W0, SPLIM
    NOP                       ;Add NOP to follow SPLIM initialization

    CALL _wreg_init           ;Call _wreg_init subroutine
                                  ;Optionally use RCALL instead of CALL




        ;<<insert more user code here>>\
opcion_menu:
	mov #100, w3 ; VALOR DE X
	mov #24, w4 ; VALOR DE Y
    
	mov #0, w2 ;VALOR OPCION DE MENU!!!!!!!!!!!!!!
	
	cp w2, #0 ;PARA DIRECCIONAR A LA RUTINA SUMA XY (0)
	    bra z, suma
	cp w2, #1 ;PARA DIRECCIONAR A LA RUTINA RESTA XY (1)
	    bra z, restaxy
	cp w2, #2 ;PARA DIRECCIONAR A LA RUTINA RESTA YX (2)
	    bra z, restayx
	cp w2, #3 ;PARA DIRECCIONAR A LA RUTINA MULTIPLICACION (3)
	    bra z, multiplicacion
	cp w2,#4 ;PARA DIRECCIONAR A LA RUTINA DIVISION XY (4)
	    bra z, divisionxy
	cp w2,#5 ;PARA DIRECCIONAR A LA RUTINA DIVISION YX (5)
	    bra z, divisionyx
	    
	bra fin ;SI NO ES NINGUNO DE LOS ANTERIORES TERMINA
	
;<<<<FUNCIONES DE OPERACION>>>>>	 
suma:
    add w3, w4, w5
    mov w5, 0x0800
    bra unidades
    
restaxy:
    subb w3, w4, w5
    mov w5, 0x0800
    bra unidades
    
restayx:
    subb w4, w3, w5
    mov w5, 0x0800
    bra unidades
    
multiplicacion:
    mul.ss w3, w4, w0
    mov w0, w5
    mov w5, 0x0800
    bra unidades
    
divisionxy:
    repeat #17
    div.u w3, w4       
    mov w0, w5
    mov w5, 0x0800      ; cociente
    mov w1, 0x0802      ; residuo
    bra unidades

divisionyx:
    repeat #17
    div.u w4, w3       
    mov w0, w5
    mov w5, 0x0800      ; cociente
    mov w1, 0x0802      ; residuo
    bra unidades
    
unidades:
    ; Centenas
    mov #100, w12
    repeat #17
    div.u w5, w12     
    mov w0, w6        ; w6 = centenas
    mov w1, w5        ; w5 = resto para siguiente división

    ; Decenas
    mov #10, w12
    repeat #17
    div.u w5, w12      
    mov w0, w7        ; w7 = decenas
    mov w1, w8        ; w8 = unidades


    ; Guardar en memoria para pruebas o visualización
    mov w6, 0x0804
    mov w7, 0x0806
    mov w8, 0x0808

    bra binario
    
    
binario:

    
hexadecimal:

    
 
    
fin:
   nop

	
	;<<no mover>>
Delay250msec:    
    
    MOV	    #1845,	    W7
    LOOP1:
    CP0	    W7			;(1 Cycle)
    BRA	    Z,	    END_DELAY	;(1 Cycle if not jump)
    DEC	    W7,	    W7		;(1 Cycle)
    
    MOV	    #100,	    W8		;(1 Cycle)
    LOOP2:
    DEC	    W8,	    W8		;(1 Cycle)
    CP0	    W8			;(1 Cycle)
    BRA	    Z,	    LOOP1	;(1 Cycle if not jump)
    BRA	    LOOP2		;(2 Cycle if jump)
    
   END_DELAY:
    NOP
    
RETURN
        



;..............................................................................
;Subroutine: Initialization of W registers to 0x0000
;..............................................................................

_wreg_init:
    CLR W0
    MOV W0, W14
    REPEAT #12
    MOV W0, [++W14]
    CLR W14
    RETURN




;--------End of All Code Sections ---------------------------------------------

.end                               ;End of program code in this file
