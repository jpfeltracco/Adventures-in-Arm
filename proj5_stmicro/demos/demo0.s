  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler

; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)

Reset_Handler
        ; Enable I/O port C clock
        ; This format for the ldr rX, =1234 instructions loads a constant from
        ; memory just after the code. A program counter relative load is used
        ; for this purpose. This is possible because the PC is one of the 16
        ; GPRs available in Thumb code.
        ldr r0, =0x40021018 ; RCC->apb2enr, see RM0041 p. 84
        mov r1, #0x10       ; Enable clock for I/O port C
        str r1, [r0]        ; Store instruction, see PM0056 p. 61

        ; GPIO Port C bits 8,9: push-pull low speed (2MHz) outputs
        ldr r0, =0x40011004 ; PORTC->crh, see RM0041 p. 111
        mov r1, #0x22 ; Bits 8/9, 2MHz push/pull; see RM0041 p. 112
        str r1, [r0]

        mov r0, #2 ; All of our calls to blink will have argument 2.
loop    bl blink   ; Call blink using branch-and-link; RM0056 p. 92
        b loop



        ; Takes number of blinks in r0.
blink   push {r0, r1, r3, lr} ; Push; see RM0041 p. 68
        ldr r1, =0x4001100c   ; PORTC->odr; see RM0041 p. 113

bloop   cbz r0, bfinish ; Compare and branch if zero; PM0056 p. 93

        mov r3, #0x300
        str r3, [r1]

        push {r0} ; Preserve r0 since it holds our counter.
        ldr r0, =200000
        bl delay
        pop {r0}  ; Pop; see RM0041 p. 68

        ldr r3, =0
        str r3, [r1]

        push {r0}
        ldr r0, =200000
        bl delay
        pop {r0}

        sub r0, #1
        
        b bloop
        
bfinish  ldr r0, =1000000
         bl delay

        ; We push lr and pop it into the pc as our procedure return.
        pop {r0, r1, r3, pc}

delay   push {r0}
        
dloop   cbz r0, dfinish
        sub r0, #1
        b dloop ; Unconditional jump; PM0056 p. 92
        
dfinish  pop {r0}
        bx lr

  align
  END
