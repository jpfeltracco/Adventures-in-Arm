; ECE 3056 Homework Code


;;; Directives
    PRESERVE8
    THUMB

; Vector Table Mapped to Address 0 at Reset
; Linker requires __Vectors to be exported

    AREA    RESET, DATA, READONLY
    EXPORT  __Vectors

__Vectors
    DCD  0x20001000     ; stack pointer value when stack is empty
    DCD  Reset_Handler  ; reset vector

    ALIGN
; The program
; Linker requires Reset_Handler
    AREA    MYCODE, CODE, READONLY
    ENTRY
    EXPORT Reset_Handler

Reset_Handler
;;;;;;;;;;User Code Starts from the next line;;;;;;;;;;;;

array_declaration
	ldr r0,init_addr
	ldr r1,=data
	ldr r2,num_elements
cp	cmp r2,#0
	beq sort_start
	ldr r3,[r1],#4
	str r3,[r0],#4
	sub r2,#1
	b 	cp
sort_start
	mov r1,r0					; r1 points to end of array
    mov r2,#1                   ; non-zero value to not trip next cond
sort_outer
    cmp r2,#0                   ; r2 == 0 means we didn't change
    beq quit
    mov r2,#0                   ; r2 was 1, reset it to 0
    ldr r0,init_addr          ; reset r0 to beginning of array
    ldr r3,[r0],#4
sort_inner
    ldr r4,[r0],#4
    ; r3 and r4 are array vals
    sub r5,r3,r4                ; check if r3 < r4
    cmp r5,#0
    ble sort_shift              ; if so, skip swap
    mov r2,#1                   ; otherwise specify that we had to swap
    str r4,[r0, #-8]			; b/c already incremented r0, r3 is in -8
    str r3,[r0, #-4]			; and r4 is in -4, so swap those
	b sort_fin
sort_shift
    mov r3,r4
sort_fin
    cmp r0,r1                   ; check if cur pointer has reached end
    beq sort_outer              ; if so, loop up to outer level
    b sort_inner                ; else do another inner loop

quit b quit

	AREA 	CONSTANT, DATA, READONLY
num_elements 	DCD 9
	ALIGN
init_addr 		DCD 0x200000f0
	ALIGN
data			DCD 0x94ff3e02, 0x000c0001, 0x36fbaaaa, 0x21211212, 0x0004bff2, 0x00382159, 0x77777777, 0x44444443, 0x00889900
	END