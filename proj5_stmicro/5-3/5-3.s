  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler
        
; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)
  SPACE 80
  DCD ext0_handler + 1

Reset_Handler
GREEN EQU 0x200
BLUE  EQU 0x100
BOTH  EQU 0x300

SHORT EQU 0xF000
LONG  EQU 0x400000
LETTERPAUSE EQU 0x600000
  ; Clock enable
  ldr r0, =0x40021018    ; RCC_APB2ENR register
  mov r1, #0x14          ; Enable clock for I/O ports A and C
  str r1, [r0]           ; store back in RCC_APB2ENR
  
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
  
  ldr r0, =0x40010008    ; AFIO->exticr1, see RM0041 p. 124
  ldr r1, [r0]
  bic r1, #0xf           ; Set LSBs to 0, Port A
  str r1, [r0]
  
  ldr r0, =0x40010400    ; EXTI base address
  mov r1, #1
  str r1, [r0, #8]       ; EXTI->rtsr; event 0 rising
  str r1, [r0, #0xC]
  str r1, [r0, #0]       ; EXTI->imr; unmask line 0
  
  ldr r0, =0xE000E404 ; Address of NVIC->ipr1; PM0056 p. 128
  ldr r1, [r0] ; NVIC->ipr1; PM0056 p. 125
  bic r1, #0xFF0000 ; Clear bits for IRQ6
  str r1, [r0] ; Set IRQ6 priority to 0
  
  ldr r0, =0xE000E100 ; NVIC->iser0; PM0056 p. 120
  mov r2, #0x40 ; Bit corresponding to IRQ6
  str r2, [r0] ; NVC->iser0; set enabled

mainblink
  ldr r0, =SHORT
  ldr r3, =GREEN
  bl blink
  
  ldr r0, =SHORT
  ldr r3, =BLUE
  bl blink
  
  b mainblink
  
  
checkpress
  ; need to set r0 to length r1 is memory loc r3 to color
  bl button
  ; now r0 contains the button state
  beq checkpress
  
  ldr r0, =SHORT
  ldr r3, =GREEN
  bl blink
  
  mov r0, #0          ; button press count, roughly proportional to user press
checkunpress
  add r0, #1          ; increment each loop
  
  bl button
  bne checkunpress    ; while it's held down, loop
  
  lsl r0, #4          ; increase count by factor of 2^4
  ldr r3, =BLUE
  bl blink
  
  b checkpress
  
  
; returns button pressed boolean in r0
button
  push {r0}
  ldr r0, =0x40010808
  ldr r0, [r0]
  ands r0, #1
  pop {r0}
  bx lr

; r0: length of blink
; r1: address of odr to write to
; r3: data to write to odr
blink
  push {r0, r3, lr} ; Push; see RM0041 p. 68
  ldr r1, =0x4001100C   ; PORTC->odr; see RM0041 p. 113

  str r3, [r1]

  bl delay

  ldr r3, =0
  str r3, [r1]

  
bfinish
  ldr r0, =0x100000 ; delay between blinks
  bl delay

  ; We push lr and pop it into the pc as our procedure return.
  pop {r0, r3, pc}

delay
  push {r0}
        
dloop
  cbz r0, dfinish
  sub r0, #1
  b dloop ; Unconditional jump; PM0056 p. 92
        
dfinish
  pop {r0}
  bx lr
  
ext0_handler
  push {r0, r3, r4, lr}

blinksimul  
  ldr r0, =SHORT
  ldr r3, =BOTH
  bl blink
  
  bl button
  bne blinksimul
  
  
  ldr r0, =0x40010414
  mov r1, #1
  str r1, [r0]
  
  ldr r0, =0xE000E280
  mov r1, #0x40
  str r1, [r0]
   

skipext
  pop {r0, r3, r4, pc}
  align
  END
