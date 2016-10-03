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

        MACRO                   ; Swaps the registers if reg1 > reg2
$label  REGCMPSWP $reg1, $reg2 
$label  CMP $reg1, $reg2        ; Check if reg1 > reg2
		MOVGT r10, $reg2		; if so, store reg2 in temp
		MOVGT $reg2, $reg1		; if so, store reg1 in reg2
		MOVGT $reg1, r10        ; if so, store tmp is reg1, finishing the swap
		MEND

		; Initial values, these can be set in any way and they will be sorted
		MOV r0, #6				; r1 is 6
		MOV r1, #3				; r2 is 3
		MOV r2, #9				; r3 is 9
		MOV r3, #1				; r4 is 1
		
		MOV r8, #0				; Loop count is 0
		
		
sort    REGCMPSWP r0, r1        ; swap r1 and r2 if r1 > r2
		REGCMPSWP r1, r2		; swap r2 and r3 if r2 > r3
		REGCMPSWP r2, r3		; swap r3 and r4 if r3 > r4
		ADD r8, r8, #1			; increment loop count
		CMP r8, #3				; check if loop count is 3
		; after n-1 iterations (3) we know the sort is finished
		BNE sort				; loop again if necessary

		
		 
stop    B  stop					; loop forever

 
        END	;End of the program
