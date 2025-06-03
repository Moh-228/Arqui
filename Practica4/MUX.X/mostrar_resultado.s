.include "p33fj32mc202.inc"
    
    ;User program memory is not write-protected
    #pragma config __FGS, GWRP_OFF & GSS_OFF & GCP_OFF
    
    ;Internal Fast RC (FRC)
    ;Start-up device with user-selected oscillator source
    #pragma config __FOSCSEL, FNOSC_FRC & IESO_ON
    
    ;Both Clock Switching and Fail-Safe Clock Monitor
    ;are disabled XT mode is a medium-gain, medium-frequency 
    ;mode that is used to work with crystal
    ;frequencies of 3.5-10 MHz //Datacheet
    #pragma config __FOSC, FCKSM_CSECME & POSCMD_XT
    
    ;Watchdog timer enabled/disabled by user software
    #pragma config __FWDT, FWDTEN_OFF
    
    ;POR Timer Value
    #pragma config __FPOR, FPWRT_PWR128
   
    ;Communicate on PGC1/EMUC1 and PGD1/EMUD1 JTAG is Disabled
    #pragma config __FICD, ICS_PGD1 & JTAGEN_OFF
    
    ;Program Specific Constants (literals used in code):
    ;Number of samples
    .equ SAMPLES, 64
    
    ;Global Declarations:
    ;Provide global scope to _wreg_init routine
    ;In order to call this routine from a C file,
    ;place "wreg_init" in an "extern" declaration
    ;in the C file.
    .global _wreg_init
    ;The label for the first line of code.
    .global __reset
    
    ;Constants stored in Program space:
    ;Align next word stored in Program space to an
    ;address that is a multiple of 2
    .section .myconstbuffer, code
    .palign 2
ps_coeff:
    .hword   0x0002, 0x0003, 0x0005, 0x000A
    
    ;Uninitialized variables in X-space in data memory:
    ;Allocating space (in bytes) to variable.
    .section .xbss, bss, xmemory
x_input: .space 2*SAMPLES
    
    ;Uninitialized variables in Y-space in data memory:
    .section .ybss, bss, ymemory
y_input:  .space 2*SAMPLES
    
    ;Uninitialized variables in Near data memory (Lower 8Kb of RAM):
    ;Example of allocating 1 word of space for variable "var1".
    .section .nbss, bss, near
var1:     .space 2
     
;Code Section in Program Memory:
;Start of Code section
.text
__reset:
    ;Initalize the Stack Pointer
    MOV #__SP_init, W15
    ;Initialize the Stack Pointer Limit Register
    MOV #__SPLIM_init, W0
    MOV W0, SPLIM
    NOP
    CALL _wreg_init
    
;Inicio de lo que escribes tú

    CLR	AD1PCFGL		; Primero limpiamos el registro
    MOV #0xFFFF, W0		; Todos los pines como digitales
    MOV W0, AD1PCFGL
    MOV	#0X00FF, W0		;PORTB<15:8> AS OUTPUTS
    MOV	W0, TRISB		;PORTB<7:0> AS INPUTS
    MOV	#0X0008, W0		
    MOV	W0, TRISA		;PORTA<2:0> y <4:4> AS OUTPUTS
    MOV	#10, W6			;PORTA<3:3> AS INPUTS, ESTO PORQUE AL PARECE RA3 NO PUEDE CONFIGURARSE COMO SALIDA DIGITAL, ENTONCES LO USO COMO ENTRADA
	
    ;W0,W1 Usados para los resultados de DIV.U
    ;W14 Puntero a la tabla del Decodificador
    ;W2 Usado para la lectura de PORTB en binario
    ;W6 Usado para la constante de division /10 para obtener Unidades,Decenas,Centenas 
    ;W3, W4, W5 Usados para almacenar Unidades, Decenas, Centenas
    ;W7 Auxiliar
    ;W8 Usado como selector de Unidades, Decenas, Centenas
    ;W9 Usado como dato de salida al PORTB en la parte más significativa
    ;W10 Usado como bandera si el resultado obtenido es negativo

_Tabla_DECO:
    MOV	    #0X0800, W14 
    MOV	    #0X00FC, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14    
    MOV	    #0X0060, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X00DA, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X00F2, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X0066, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X00B6, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X00BE, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X00E0, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X00FE, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X00F6, W7
    MOV	    W7, [W14]
    ADD	    W14, #2, W14
    MOV	    #0X0002, W7
    MOV	    W7, [W14]
    MOV	    #0X0800, W14
    MOV	    #0XFFFE, W8

_Carrusel_Digitos:
    CALL    _Read_Convert
    CALL    _Is_Negative
   
    MOV	    #0XFFFE, W8
    MOV	    W3, W2
    CALL    _Display_Digit
    
    MOV     #0xFFFD, W8
    MOV     W4, W2          
    CALL    _Display_Digit
    
    MOV     #0xFFFB, W8     
    MOV     W5, W2          
    CALL    _Display_Digit
    
    CP0 W10
    BRA Z, _Carrusel_Digitos
    
    MOV     #0xFFEF, W8     
    MOV     #10, W2          
    CALL    _Display_Digit
    
    BRA _Carrusel_Digitos
    
_Display_Digit:
    MOV	    #2, W7
    MUL.UU  W2, W7, W12   
    MOV     [W14+W12], W9    
    SL      W9, #8, W9       
    MOV     W9, PORTB         
    MOV     W8, PORTA        
    CALL    Delay5msec        
    CLR     PORTB             
    RETURN
    
_Is_Negative:
    BTSC    PORTA, #3 
    GOTO    _negative
    CLR     W10         
    RETURN
    
_negative:
    MOV     #1, W10     
    RETURN

_Read_Convert:
    MOV	    PORTB,  W2
    MOV	    #0X00FF, W7
    AND	    W2, W7, W2
    
_Unidades:
    REPEAT  #17
    DIV.U   W2, W6
    MOV	    W1, W3
    
_Decenas:
    REPEAT  #17
    DIV.U   W0, W6
    MOV	    W1, W4
    
_Centenas:
    REPEAT  #17
    DIV.U   W0, W6
    MOV	    W1, W5
    RETURN 

Delay5msec:
    MOV     #180, W7        ; 1 ciclo
LOOP_EXT:
    MOV     #12, W8         ; 1 ciclo (180 veces)
LOOP_INT:
    DEC     W8, W8          ; 1 ciclo (12×180 = 2,160)
    BRA     NZ, LOOP_INT    ; 2 ciclos (11×180 = 1,980 cuando salta)
                            ; (1×180 = 180 cuando no salta)
    DEC     W7, W7          ; 1 ciclo (180)
    BRA     NZ, LOOP_EXT    ; 2 ciclos (179×2 = 358 cuando salta)
                            ; (1×2 = 2 cuando no salta)
    RETURN                  ; 3 ciclos

;Fin de lo que escribes tú

_wreg_init:
    CLR W0
    MOV W0, W14
    REPEAT #12
    MOV W0, [++W14]
    CLR W14
    RETURN

.end
