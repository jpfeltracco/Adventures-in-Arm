  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler

; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400             ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1      ; Entry point (+1 for thumb mode)

Reset_Handler
GREEN EQU 0x200              ; Address in ODR to write to
BLUE  EQU 0x100
BOTH  EQU 0x300

SHORT EQU 0x200000           ; Number of iterations
LONG  EQU 0x400000
LETTERPAUSE EQU 0x600000

  ; Clock enable
  ldr r0, =0x40021018        ; RCC_APB2ENR register
  mov r1, #0x10              ; set bit 4
  str r1, [r0]               ; store back in RCC_APB2ENR

  ; Set outputs (GPIOC_CRH)
  ldr r0, =0x40011004
  mov r1, #0x22              ; low-speed push-pull ouputs on bits 8/9
  str r1, [r0]

  ldr r1, =0x4001100c        ; PORTC->odr; see RM0041 p. 113

atl
  ldr r0, =SHORT             ; Call to blink for a SHORT, GREEN flash
  ldr r3, =GREEN
  bl blink

  ldr r0, =LONG
  ldr r3, =BLUE
  bl blink

  ldr r0, =LETTERPAUSE
  bl delay

  ldr r0, =LONG
  ldr r3, =BLUE
  bl blink

  ldr r0, =LETTERPAUSE
  bl delay

  ldr r0, =SHORT
  ldr r3, =GREEN
  bl blink

  ldr r0, =LONG
  ldr r3, =BLUE
  bl blink

  ldr r0, =SHORT
  ldr r3, =GREEN
  bl blink

  ldr r0, =SHORT
  ldr r3, =GREEN
  bl blink

  ldr r0, =LETTERPAUSE
  bl delay

  b atl


; r0: length of blink
; r1: address of odr to write to
; r3: data to write to odr
blink
  push {r0, r3, lr}          ; Push; see RM0041 p. 68
  ldr r1, =0x4001100C        ; PORTC->odr; see RM0041 p. 113

  str r3, [r1]

  bl delay

  ldr r3, =0
  str r3, [r1]

bfinish
  ldr r0, =0x100000          ; delay between blinks
  bl delay

  pop {r0, r3, pc}           ; pop pc as procedure return (from lr)

; r0: number of iterations to delay for
delay
  push {r0}
dloop
  cbz r0, dfinish
  sub r0, #1
  b dloop                    ; Unconditional jump; PM0056 p. 92
dfinish
  pop {r0}
  bx lr

  align
  END
