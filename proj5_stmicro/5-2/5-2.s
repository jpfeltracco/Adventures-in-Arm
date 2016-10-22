  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler
        
; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)

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
  
  align
  END
  
  ; END OF 5-1 code copied over

loop
  ldr r0, =0x40010808 ; PORTA->idr, read from port A ; RM0041 p. 111
  ldr r0, [r0]
  lsr r0, #1
  and r0, #1 ; We only care about the value in bit 0
  ;add r0, #2 ; 2 blinks for 0 (not pressed), 3 blinks for 1
  bl blink   ; Call blink using branch-and-link; RM0056 p. 92
  b loop

