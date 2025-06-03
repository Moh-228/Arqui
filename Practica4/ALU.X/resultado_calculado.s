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
    
    .global __INT0Interrupt
    
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

NOP
SETM AD1PCFGL		    ;PORTA AS DIGITAL
MOV	#0XFFFF, W0	    ;PORTA<15:0> AS OUTPUTS
MOV	W0, TRISA
BCLR TRISA, #4		    ;RB4 para la indicación de número negativo

SETM AD1PCFGL		    ;PORTB AS DIGITAL
MOV	#0X00FF, W0	    ;PORTB<15:8> AS OUTPUTS
MOV	W0, TRISB	    ;PORTB<7:0> AS INPUTS

; --- Configurar RB0 como entrada (para el botón) ---
BSET TRISB, #0           ; Configura RB0 como entrada

; --- Configurar la interrupción ---
CALL CONF_INT0           ; Configura la interrupción INT0

; --- Inicializar retardo en milisegundos ---
MOV #100, W11            ; Configura el retardo inicial a 10ms (puedes ajustar este valor)

; --- Contador infinito ---
CLR W1                  ; Inicializa contador en 0

bucle_contador:
            MOV W1, LATB           ; Guarda el valor actual del contador en LATB
            CALL enviar_puerto_b   ; Enviar valor a PORTB

            CALL customDelay       ; Usa el retardo personalizado basado en W11

            INC W1, W1             ; Incrementa el contador (cuando llega a 256, reinicia automáticamente a 0)
            BRA bucle_contador     ; Repite infinitamente

; --- Subrutina para enviar a puerto B ---
enviar_puerto_b:
            MOV LATB, W0          ; Carga el valor a enviar
            SL W0, #8, W0         ; Desplaza a los bits altos (PORTB<15:8>)
            MOV W0, PORTB         ; Manda el valor al puerto B
            RETURN

; --- Función de retardo personalizado basado en W11 (milisegundos) ---
customDelay:
            PUSH W0               ; Guarda los registros que se van a modificar
            PUSH W1
            PUSH W2
            
            MOV W11, W0           ; Copia el valor de milisegundos a W0
            
delay_ms_loop:
            CP0 W0                ; Comprueba si W0 es cero
            BRA Z, delay_end      ; Si es cero, termina
            
            ; --- Generar un retardo de 1ms ---
            MOV #7, W1            ; Ajusta este valor según la frecuencia del reloj
                                   ; Asumiendo ~40 MIPS, esto crea un retardo de ~1ms
outer_loop:
            MOV #1000, W2         ; Ajusta este valor según sea necesario
            
inner_loop:
            DEC W2, W2            ; Decrementa W2
            BRA NZ, inner_loop    ; Continúa hasta que W2 sea cero
            
            DEC W1, W1            ; Decrementa W1
            BRA NZ, outer_loop    ; Continúa hasta que W1 sea cero
            
            DEC W0, W0            ; Decrementa el contador de milisegundos
            BRA delay_ms_loop     ; Repite para cada milisegundo
            
delay_end:
            POP W2                ; Restaura los registros
            POP W1
            POP W0
            RETURN

; --- Antiguo retardo de 250ms (se mantiene para uso en la interrupción) ---
Delay250msec:
    MOV	#1845, W7

    LOOP1:
    CP0	W7
    BRA	Z, END_DELAY
    DEC	W7, W7
    MOV	#100, W8

    LOOP2:
    DEC	W8, W8
    CP0	W8
    BRA	Z, LOOP1
    BRA	LOOP2

    END_DELAY:
    NOP
    RETURN

;******************************************************************
; Configuración de la interrupción INT0 (RB0)
;******************************************************************

CONF_INT0:
    BSET    INTCON1, #NSTDIS      ; Desactivar interrupciones anidadas

    ; Prioridad de la interrupción INT0: nivel 4
    BCLR    IPC0, #INT0IP0
    BCLR    IPC0, #INT0IP1
    BSET    IPC0, #INT0IP2

    ; Limpiar bandera de interrupción INT0
    BCLR    IFS0, #INT0IF

    ; Configurar INT0 para flanco positivo (cuando se presiona el botón)
    BCLR    INTCON2, #INT0EP

    ; Habilitar la interrupción INT0
    BSET    IEC0, #INT0IE

    RETURN

;******************************************************************
; Servicio de Interrupción INT0 (botón en RB0)
;******************************************************************

__INT0Interrupt:
    PUSH    W0                    ; Guardar registros utilizados
    PUSH    W1
    
    ; Incrementar el tiempo de retardo en 75ms
    MOV     W11, W0              ; Obtener el valor actual
    MOV     #750, W1              ; Valor a incrementar (75ms)
    ADD     W0, W1, W0           ; Sumar 75ms
    MOV     W0, W11              ; Actualizar el valor de retardo
    
    ; Pequeño retardo para evitar rebotes del botón
    CALL    Delay250msec
    
    POP     W1                    ; Recuperar registros
    POP     W0
    
    BCLR    IFS0, #INT0IF         ; Limpiar bandera de interrupción INT0

    RETFIE                        ; Retornar de la interrupción

_wreg_init:
    CLR W0
    MOV W0, W14
    REPEAT #12
    MOV W0, [++W14]
    CLR W14
    RETURN

.end
