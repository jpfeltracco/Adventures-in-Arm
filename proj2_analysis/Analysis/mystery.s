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
_start
              mov r0, #10
              bl _func
              sub r1, r1
              sub r2, r2
              sub r3, r3
              mov r7, #1
              swi #0
_func
              str lr, [sp], #-4   ; immediate post-indexed (updates sp), original sp gets lr
              cmp r0, #2
              movle r0, #1        ; if r0 < 2, r0 = 1
              ldrle pc, [sp, #4]! ; if r0 < 2, pc = sp + 4 -- no matter what, base pointer will update, new sp gets pc
              mov r3, r0          ; r3 = r0
              mov r0, #0          ; r0 = 0
              mov r1, #1          ; r1 = 1
              mov r2, #1          ; r2 = 1
__loop__
              cmp r3, #2
              movle r0, r2
              ldrle pc, [sp, #4]!
              add r0, r1
              add r0, r2
              mov r1, r2
              mov r2, r0
              sub r0, r0
              sub r3, #1
              b __loop__
              END
