  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler
        
; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)

Reset_Handler
        ; Enable I/O port C clock
        ldr r0, =0x40021018 ; RCC->apb2enr, see RM0041 p. 84
        ; See PM0056 p. 79 for mov instruction
        mov r1, #0x14       ; Enable clock for I/O ports A and C
        str r1, [r0]        ; Store instruction, see PM0056 p. 61

        ; GPIO Port C bits 8,9: push-pull low speed (2MHz) outputs
        ldr r0, =0x40011004 ; PORTC->crh, see RM0041 p. 111
        mov r1, #0x22 ; Bits 8/9, 2MHz push/pull; see RM0041 p. 112
        str r1, [r0]

        ; GPIO Port A: all bits: inputs with no pull-up/pull down
        ; This step is technically unnecessary, since the initial state of all
        ; GPIOs is to be floating inputs.
        ldr r0, =0x40010800 ; PORTA->crl, see RM0041 p. 111
        ldr r1, =0x44444444 ; All inputs; RM00r1 p. 112
        str r1, [r0]

loop    ldr r0, =0x40010808 ; PORTA->idr, read from port A ; RM0041 p. 111
        ldr r0, [r0]
        and r0, #1 ; We only care about the value in bit 0
        add r0, #2 ; 2 blinks for 0 (not pressed), 3 blinks for 1
        bl blink   ; Call blink using branch-and-link; RM0056 p. 92
        b loop

        ; Takes number of blinks in r0.
blink   push {r0, r1, r3, lr} ; Push; see RM0041 p. 68
        ldr r1, =0x4001100c ; PORTC->odr; see RM0041 p. 113

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

        ; Takes number of delay iterations in r0.
delay   push {r0}
        
dloop   cbz r0, dfinish
        sub r0, #1
        b dloop     ; Unconditional jump; PM0056 p. 92
        
dfinish  pop {r0}
         bx lr

  align
  END
