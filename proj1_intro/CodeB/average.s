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

		MOV r6, #0				; Sum of the two averages
		; First set of 4 numbers to be averaged
		MOV r0, #2				; r1 is 2
		MOV r1, #10				; r2 is 10
		MOV r2, #30				; r3 is 30
		MOV r3, #6				; r4 is 6
		
		BL avg					; find the average of r0-r3
		ADD r6, r6, r8			; add that average to sum average
		; Second set of 4 numbers to be averaged
		MOV r0, #9				; r1 is 9
		MOV r1, #14				; r2 is 14
		MOV r2, #15				; r3 is 15
		MOV r3, #10				; r4 is 10
		
		BL avg					; find the average of r0-r3
		ADD r6, r6, r8			; add that average to the sum average
		; find the average of the two averages, ignoring truncation errors
		LSR r6, r6, #1			; shift right to divide by 2
		
stop	B stop	                ; jump to loop forever

avg     MOV r8, #0              ; Reset sum to 0
        ADD r8, r8, r0          ; add r0 to sum
		ADD r8, r8, r1          ; add r1 to sum
		ADD r8, r8, r2          ; add r2 to sum
		ADD r8, r8, r3          ; add r3 to sum
		LSR r8, r8, #2          ; divide by 4 to get average (ignore truncation errors)
		MOV pc, lr              ; end function call

        END	;End of the program
