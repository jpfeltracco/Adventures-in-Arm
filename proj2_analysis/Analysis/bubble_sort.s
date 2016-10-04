; ECE 3056 Homework Code


;;; Directives
    PRESERVE8
    THUMB

; Vector Table Mapped to Address 0 at Reset
; Linker requires __Vectors to be exported

    area    RESET, DATA, READONLY
    EXPORT  __Vectors

__Vectors
    dcd  0x20001000     ; stack pointer value when stack is empty
    dcd  Reset_Handler  ; reset vector

    align
; The program
; Linker requires Reset_Handler
    area    MYCODE, CODE, READONLY
    ENTRY
    EXPORT Reset_Handler

Reset_Handler
;;;;;;;;;;User Code Starts from the next line;;;;;;;;;;;;
; equ statements must be at the beginning of the program.
; equ gives a symbolic name to a numeric constant
stack_start equ 0x40001000; assign addr 0x40001000 to 'stack_start'
length equ (end_of_list - begin); assign value length of the number list to 'length'
end_ram equ (datastart + length); define the end of the list

   area Subroutine_Example, CODE; Name this block of code Subroutine_Bubble

   ENTRY; Mark first instruction to execute


   ; Copy list to RAM
   ldr sp, =stack_start
   ldr R9, =begin
   ldr R7, =end_of_list
   ldr r6, =datastart

loop
   ldr r8,[r9],#4; Word -- 32 bits
   str r8,[r6],#4
   cmp r9,r7
   bne loop

   ; End copy to RAM


;Sort from the end of the list
start_sort
    ldr r5,=(end_ram - 4)
loop_sort_outer ; r2 is our counter, it goes from 1 to item_count
    mov r1, #1 ; has_changed = false (0 is true, i is false)
    ldr r2,=datastart ; start of data in ram goes into r2
loop_sort_inner ;
    ldr r3,[r2],#4
    ldr r4,[r2],#0
;cmp r4,r3; compre r3 and r4 by r3 - r4
blsubroutine_swap ; swaps the last two and sets has_changed, 'blhi' branch with link
    cmp r2,r5
    bne loop_sort_inner
    sub r5,r5,#4 ; the last item is in order, so we don't need to check it again.
    cmp r1,#1
    bne loop_sort_outer
    stop b stop1
stop1
    ldr r0, =datastart
    ldr r1, [r0],#4
    ldr r2, [r0],#4
    ldr r3, [r0],#4
    ldr r4, [r0],#4
    ldr r5, [r0],#0

    b stop3
    stop3b stop3

subroutine_swap ; swaps the contents of the addresses held in
    ; r2 and r2 -4 (the previous address)
    ; has_changed is r1 and it sets it to 0 (true)
    ;STMFD sp!, {r0,r2-r4,lr}; push onto a full descending stack
    ;mov r1,#0 ; setting the has_changed to true.
    ;ldr r0,[r2],#-4  ; swapping data
    ;ldr r3,[r2]
    ;str r0,[r2],#4
    ;str r3,[r2]
    ;LDMFD sp!, {r0,r2-r4,pc}; pop from a full descending stack
    ;check whether it needs to swap
    sub r10, r3, r4
    cmp r10, #0
    ble endswap

;if it need swapping, then swap
    mov r1, #0
    ldr r0, [r2],#-4
    ldr r3, [r2]
    str r0,[r2],#4
    str r3,[r2]
endswap
    bx lr

align

; List of numbers need to be sorted
begin
dcd 0x8fffffff, 0x55555555, 0x44444444, 0x77777777, 0xffffffff
end_of_list
    area Thedata, DATA, NOINIT, READWRITE
;   DCb     255         ; Now misaligned ...
;data3   dcdU    1,5,20      ; Defines 3 words containing
                            ; 1, 5 and 20, not word aligned
datastart space 20
;align
;datastartdcd 2,7,1,3,9,5,4,0,11,31,21

    end
