  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler

; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)

Reset_Handler
  ; Your code here
  ; Clock enable
  ldr r0, =0x40021018    ; RCC_APB2ENR register
  mov r1, #0x10           ; set bit 4
  str r1, [r0]           ; store back in RCC_APB2ENR
  
  ; Set outputs (GPIOC_CRH)
  ldr r0, =0x40011004
  mov r1, #0x22          ; low-speed push-pull ouputs on bits 8/9
  str r1, [r0]
  
  ldr r0, =0x4001100c ; GPIOC_ODR
loop
  mov r1, #0x300
  str r1, [r0]
  mov r2, #0x80000
delay0
  sub r2, #1
  cmp r2, #0
  bne delay0
  
  mov r1, #0
  str r1, [r0]
  
  mov r2, #0x80000
delay1
  sub r2, #1
  cmp r2, #0
  bne delay1
  
  b loop

  align
  END
