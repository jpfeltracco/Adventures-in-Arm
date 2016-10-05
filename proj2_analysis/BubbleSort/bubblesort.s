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
    ldr r0,=0x200000f0          ; reset r0 to beginning of array
    ldr r1,=0x94ff3e02
    str r1,[r0],#4
    ldr r1,=0x000c0001
    str r1,[r0],#4
    ldr r1,=0x36fbaaaa
    str r1,[r0],#4
    ldr r1,=0x21211212
    str r1,[r0],#4
    ldr r1,=0x0004bff2
    str r1,[r0],#4
    ldr r1,=0x00382159
    str r1,[r0],#4
    ldr r1,=0x77777777
    str r1,[r0],#4
    ldr r1,=0x44444443
    str r1,[r0],#4
    ldr r1,=0x00889900
    str r1,[r0],#4
    mov r1,r0                   ; r1 is end of array
    mov r2,#1                   ; non-zero value to not trip next cond
sort_outer
    cmp r2,#0                   ; r2 == 0 means we didn't change
    beq quit
    mov r2,#0                   ; r2 was 1, reset it to 0
    ldr r0,=0x200000f0          ; reset r0 to beginning of array
    ldr r3,[r0],#4
sort_inner
    ldr r4,[r0],#4
    ; r3 and r4 are array vals
    sub r5,r3,r4                ; check if r3 < r4
    cmp r5,#0
    ble sort_in_fin             ; if so, skip swap
    mov r2,#1                   ; otherwise specify that we had to swap
    str r4,[r0, #-8]
    str r3,[r0, #-4]
sort_in_fin
    mov r4,r3
    cmp r0,r1                   ; check if cur pointer has reached end
    beq sort_outer              ; if so, loop up to outer level
    b sort_inner                ; else do another inner loop

quit b quit

; start_sort
		; LDR r5,=(end_ram - 4)		
; loop_sort_outer 						; r2 is our counter, it goes from 1 to item_count
		; MOV r1, #1 						; has_changed = false (0 is true, i is false)
		; LDR r2,=datastart 				; start of data in ram goes into r2
; loop_sort_inner ; 
		; LDR r3,[r2],#4
		; LDR r4,[r2],#0 
		; ;CMP r4,r3						; compre r3 and r4 by r3 - r4
		; BL	subroutine_swap 		; swaps the last two and sets has_changed, 'blhi' branch with link
		; CMP r2,r5
		; BNE loop_sort_inner
		; SUB r5,r5,#4 					; the last item is in order, so we don't need to check it again.
		; CMP r1,#1
		; BNE loop_sort_outer					
; stop 	B stop1

; subroutine_swap 						; swaps the contents of the addresses held in
										; ; r2 and r2 -4 (the previous address)
										; ; has_changed is r1 and it sets it to 0 (true)
		; ;STMFD sp!, {r0,r2-r4,lr}		; push onto a full descending stack
		; ;MOV r1,#0 ; setting the has_changed to true.
		; ;LDR r0,[r2],#-4  ; swapping data
		; ;LDR r3,[r2]
		; ;STR r0,[r2],#4
		; ;STR r3,[r2]		
		; ;LDMFD sp!, {r0,r2-r4,pc}		; pop from a full descending stack
		; ;check whether it needs to swap
		; SUB r10, r3, r4
		; CMP r10, #0
		; BLE endswap

		; ;if it need swapping, then swap
		; MOV r1,#0
		; LDR r0,[r2],#-4
		; LDR r3,[r2]
		; STR r0,[r2],#4
		; STR r3,[r2]
; endswap
		; BX lr


	
	; AREA Thedata, DATA, READWRITE
; data	DCD 0x94ff3e02, 0x000c0001, 0x36fbaaaa, 0x21211212, 0x0004bff2, 0x00382159, 0x77777777, 0x44444443, 0x00889900
; ; end_of_list

; ram		SPACE 36
	END



; _start
          ; mov r0, #10
          ; bl _func
          ; sub r1, r1
          ; sub r2, r2
          ; sub r3, r3
          ; mov r7, #1
          ; swi #0
; _func
          ; str lr, [sp], #-4   ; immediate post-indexed (updates sp), original sp gets lr
          ; cmp r0, #2
          ; movle r0, #1        ; if r0 < 2, r0 = 1
          ; ldrle pc, [sp, #4]! ; if r0 < 2, pc = sp + 4 -- no matter what, base pointer will update, new sp gets pc
          ; mov r3, r0          ; r3 = r0
          ; mov r0, #0          ; r0 = 0
          ; mov r1, #1          ; r1 = 1
          ; mov r2, #1          ; r2 = 1
; __loop__
          ; cmp r3, #2
          ; movle r0, r2
          ; ldrle pc, [sp, #4]!
          ; add r0, r1
          ; add r0, r2
          ; mov r1, r2
          ; mov r2, r0
          ; sub r0, r0
          ; sub r3, #1
          ; b __loop__
          ; END
		  
		  
		  
		  
; start_sort
		; LDR r5,=(end_ram - 4)		
; loop_sort_outer 						; r2 is our counter, it goes from 1 to item_count
		; MOV r1, #1 						; has_changed = false (0 is true, i is false)
		; LDR r2,=datastart 				; start of data in ram goes into r2
; loop_sort_inner ; 
		; LDR r3,[r2],#4
		; LDR r4,[r2],#0 
		; ;CMP r4,r3						; compre r3 and r4 by r3 - r4
		; BL	subroutine_swap 		; swaps the last two and sets has_changed, 'blhi' branch with link
		; CMP r2,r5
		; BNE loop_sort_inner
		; SUB r5,r5,#4 					; the last item is in order, so we don't need to check it again.
		; CMP r1,#1
		; BNE loop_sort_outer					
; stop 	B stop1
; stop1
		; LDR r0, =datastart
		; LDR r1, [r0],#4
		; LDR r2, [r0],#4
		; LDR r3, [r0],#4
		; LDR r4, [r0],#4
		; LDR r5, [r0],#0

		; B stop3
; stop3	B stop3

; subroutine_swap 						; swaps the contents of the addresses held in
										; ; r2 and r2 -4 (the previous address)
										; ; has_changed is r1 and it sets it to 0 (true)
		; ;STMFD sp!, {r0,r2-r4,lr}		; push onto a full descending stack
		; ;MOV r1,#0 ; setting the has_changed to true.
		; ;LDR r0,[r2],#-4  ; swapping data
		; ;LDR r3,[r2]
		; ;STR r0,[r2],#4
		; ;STR r3,[r2]		
		; ;LDMFD sp!, {r0,r2-r4,pc}		; pop from a full descending stack
		; ;check whether it needs to swap
		; SUB r10, r3, r4
		; CMP r10, #0
		; BLE endswap

		; ;if it need swapping, then swap
		; MOV r1, #0
		; LDR r0, [r2],#-4
		; LDR r3, [r2]
		; STR r0,[r2],#4
		; STR r3,[r2]
; endswap
		; BX lr
		
	; ALIGN
	
; ; List of numbers need to be sorted
; begin
	; DCD 0x8fffffff, 0x55555555, 0x44444444, 0x77777777, 0xffffffff
; end_of_list

   ; AREA Thedata, DATA, NOINIT, READWRITE
; ;   DCB     255         ; Now misaligned ...
; ;data3   DCDU    1,5,20      ; Defines 3 words containing
                            ; ; 1, 5 and 20, not word aligned
; datastart SPACE 20
; ;	ALIGN
; ;datastart	DCD 2,7,1,3,9,5,4,0,11,31,21
	
	; ; END 
