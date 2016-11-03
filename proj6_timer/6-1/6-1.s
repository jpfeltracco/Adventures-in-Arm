  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler
        
; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400          ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1   ; Entry point (+1 for thumb mode)
  DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  DCD systick_handler + 1 ; 
  DCD 0, 0, 0, 0, 0, 0 
  DCD ext0_handler + 1    ; IRQ6 : external interrupt from exti controller

Reset_Handler
COUNT EQU   0x20000400
SIMUL EQU   0x20000408
PRESSED EQU 0x2000040C
OLDCNT EQU  0x20000414

GREEN EQU 0x200              ; Address in ODR to write to
BLUE  EQU 0x100
BOTH  EQU 0x300

SHORT EQU 0xF000             ; Number of iterations
LONG  EQU 0x400000
LETTERPAUSE EQU 0x600000

        ;  Enable I/O port clocks 
        ldr r0, =0x40021018 ; RCC->apb2enr, see RM0041 p. 84 
        mov r1, #0x15       ; Enable clock for I/O ports A and C, and AFIO
        str r1, [r0]        ; Store instruction, see PM0056 p. 61 

        ;  GPIO Port C bits 8,9: push-pull low speed (2MHz) outputs 
        ldr r0, =0x40011004 ; PORTC->crh, see RM0041 p. 111 
        ldr r1, =0x44444422 ; Bits 8/9, 2MHz push/pull; see RM0041 p. 112 
        str r1, [r0]

        ; GPIO Port A: all bits: inputs with no pull-up/pull down 
        ; This step is technically unnecessary, since the initial state of all
        ; * GPIOs is to be floating inputs. 
        ldr r0, =0x40010800 ; PORTA->crl, see RM0041 p. 111 
        ldr r1, =0x44444444 ; All inputs; RM0041 p. 112 
        str r1, [r0]

        ; Set EXTI0 source to Port A 
        ldr r0, =0x40010008 ; AFIO->exticr1, see RM0041 p. 124 
        ldr r1, [r0]
        bic r1, #0xf        ; Mask out the last 4 bits (set to 0, Port A) 
        str r1, [r0]

        ; Initialize the systick timer to branch to systick every 1 millisecond
        ldr r0, =0xe000e010 ; systick base; PM0056 p. 150 
        ldr r1, =500000   ; systick reload value; PM0056 p. 152 
        str r1, [r0, #4]  ; SYSTICK->load 
        ldr r1, [r0, #0]  ; SYSTICK->ctrl; PM0056 p. 151 
        orr r1, #3        ; Set to 3: enable interrupt and counting 
        str r1, [r0, #0]
        
        ; Set up interrupt on rising edge of port A bit 0 on the EXTI (external
        ; interrupt controller); see RM0041 p. 134
        ldr r0, =0x40010400 ; EXTI base address 
        mov r1, #1
        str r1, [r0, #8]    ; EXTI->rtsr; event 0 rising; see RM0041 p. 139 
        str r1, [r0, #0xC]  ; EXTI->ftsr; falling
        str r1, [r0, #0]    ; EXTI->imr; unmask line 0 

        ; Set up the IRQ in the NVIC. See PM0056 p. 118
        ldr r0, =0xe000e404 ; Address of NVIC->ipr1; PM0056 p. 128 
        ldr r1, [r0]        ; NVIC->ipr1; PM0056 p. 125 
        bic r1, #0xff0000   ; Zero out bits corresponding to IRQ6 
        str r1, [r0]        ; Set IRQ6 priority to 0 (highest) 
        
        ldr r0, =0xe000e100 ; NVIC->iser0; PM0056 p. 120 
        mov r2, #0x40       ; Bit corresponding to IRQ6 
        str r2, [r0]        ; NVC->iser0; set enabled 
        
        mov r0, #0
        ldr r1, =SIMUL
        str r0, [r1]
        
        ldr r1, =PRESSED
        str r0, [r1]
        
        ldr r1, =COUNT
        str r0, [r1]
        
        ldr r1, =OLDCNT
        str r0, [r1]

        ; Enable interrupts. 
        cpsie i

loop    
        ; Check if SIMUL is enabled
        ldr r1, =SIMUL
        ldr r1, [r1]
        cmp r1, #0
        bne simul_enb
simul_dis
        ; SIMUL not enabled, flash alternating
        ldr r0, =SHORT             ; Do alternating blinking.
        ldr r3, =GREEN
        bl blink
        ldr r0, =SHORT
        ldr r3, =BLUE
        bl blink
        b loop
simul_enb
        ; SIMUL is enabled, flash same time
        ldr r0, =SHORT             ; Do simultaneous blinking.
        ldr r3, =BOTH
        bl blink
        b loop
        
; Checks button state for use in conditionals, sets Z-bit
; if equal, and clears Z-bit if not equal.
button
        push {r0}
        ldr r0, =0x40010808        ; Memory address for reading GPIOA_IDR
        ldr r0, [r0]
        ands r0, #1                ; Only care about bit 0
        pop {r0}
        bx lr


ext0_handler  push {lr, r0, r1}

        ; Skip the handler if the button is no longer pressed. 
        ;ldr r0, =0x40010808
        ;ldr r0, [r0]
        ;and r0, #1 ; Test bit 0 
        ;cbz r0, skip_ext0
        ldr r1, =PRESSED
        ldr r1, [r1]
        cmp r1, #0
        bne ext0_unpressed
ext0_pressed
        bl button
        beq ext0_done ; button isn't actually pressed, escape
        ; Clear counter
        mov r0, #0
        ldr r1, =COUNT
        str r0, [r1]
        ; Set PRESSED to TRUE
        mov r0, #1
        ldr r1, =PRESSED
        str r0, [r1]
        b ext0_done
ext0_unpressed
        bl button
        bne ext0_done
        ; PRESSED = false
        mov r0, #0
        ldr r1, =PRESSED
        str r0, [r1]
        ; Get COUNTER Value
        ldr r1, =COUNT
        ldr r1, [r1]
        ; Store in OLDCNT
        ldr r0, =OLDCNT
        str r1, [r0]
        ; Set SIMUL to ON
        mov r0, #1
        ldr r1, =SIMUL
        str r0, [r1]

ext0_done
        ; Clear pending-bit in EXTI; see RM0041 p. 140
        ldr r0, =0x40010414
        mov r1, #1
        str r1, [r0]

        ; Clear pending-bit in interrupt controller
        ldr r0, =0xE000E280        ; NVIC->icpr0; see PM0051 p. 123
        mov r1, #0x40
        str r1, [r0]
        
        pop {pc, r0, r1} ; Return from interrupt. 


systick_handler
        push {lr, r0, r1, r2}

        ; Increment counter
        ldr r0, =COUNT
        ldr r1, [r0]
        add r1, #1
        str r1, [r0]
        
        ; Get simul mode var
        ldr r2, =SIMUL
        ldr r2, [r2]
        
        cmp r2, #0
        beq systick_end
        ; Get old counter var
        ldr r0, =OLDCNT
        ldr r0, [r0]
        ; Compare old counter and counter
        cmp r0, r1
        ; If old counter > counter, don't disable simul
        bge systick_end
        mov r0, #0
        ; Set simul mode to 0 (false)
        ldr r2, =SIMUL
        str r0, [r2]

systick_end
        pop {pc, r0, r1, r2}
        
        ; Takes number of delay iterations in r0. 
delay   push {r0}
        
dloop   cbz r0, dfinish
        sub r0, #1
        b dloop     ; Unconditional jump; PM0056 p. 92 
        
dfinish pop {r0}
        bx lr
        
        
; r0: length of blink
; r3: data to write to odr
blink
        push {r0, r1, r3, lr}          ; Push; see RM0041 p. 68
        ldr r1, =0x4001100C        ; PORTC->odr; see RM0041 p. 113

        str r3, [r1]

        bl delay

        ldr r3, =0
        str r3, [r1]

bfinish
        ldr r0, =0x100000          ; delay between blinks
        bl delay

        pop {r0, r1, r3, pc}           ; pop pc as procedure return (from lr)

  align
  END

