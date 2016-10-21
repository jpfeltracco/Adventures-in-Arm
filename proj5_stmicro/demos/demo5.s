  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler
        
; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400          ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1   ; Entry point (+1 for thumb mode)
  DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  DCD systick_handler + 1 ; 

Reset_Handler
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

        ; Set up interrupt on rising edge of port A bit 0 on the EXTI (external
        ; interrupt controller); see RM0041 p. 134
        ldr r0, =0x40010400 ; EXTI base address 
        mov r1, #1
        str r1, [r0, #8] ; EXTI->rtsr; event 0 rising; see RM0041 p. 139 
        str r1, [r0, #0] ;   EXTI->imr; unmask line 0 

        ; Set up the IRQ in the NVIC. See PM0056 p. 118
        ldr r0, =0xe000e404 ; Address of NVIC->ipr1; PM0056 p. 128 
        ldr r1, [r0]        ; NVIC->ipr1; PM0056 p. 125 
        bic r1, #0xff0000   ; Zero out bits corresponding to IRQ6 
        str r1, [r0]        ; Set IRQ6 priority to 0 (highest) 
        
        ldr r0, =0xe000e280 ; NVIC->icpr0; PM0056 p. 123 
        ldr r2, [r0]
        orr r2, #0x40       ; Bit corresponding to IRQ6 
        str r2, [r0]        ; NVC->icpr0; clear pending state 
        
        ldr r0, =0xe000e100 ; NVIC->iser0; PM0056 p. 120 
        ldr r2, [r0]
        orr r2, #0x40       ; Bit corresponding to IRQ6 
        str r2, [r0]        ; NVC->iser0; set enabled 
        
        ldr r0, =0xe000e300 ; NVC->iabr0; PM0056 p. 124 
        ldr r2, [r0]
        orr r2, #0x40       ; Bit corresponding to IRQ6 
        str r2, [r0]        ; NVC->iabr0; set active 
        
        ; Clear our counter.
        ldr r0, =0x20000400
        mov r1, #0
        str r1, [r0]

        ; Enable interrupts. 
        cpsie i

        ; Switch to 24MHz clock.
        ldr r0, =0x40021000
        ldr r1, =0x100010 ; RCC->cfgr, PLL mul x6, pll src ext; RM0041 p. 80
        str r1, [r0, #4]

        ldr r1, [r0]      ; RCC->cr, turn on PLL, RM0041 p. 78
        orr r1, #0x1000000
        str r1, [r0]

        ; RCC->cfgr = (RCC->cfgr & 0xfffffffc) | 2;
        ldr r1, [r0, #4]  ; RCC->cfgr, switch system clock to PLL
        bic r1, #0x3      ; RM0041 p. 81
        orr r1, #2
        str r1, [r0, #4]

        ;  Set initial time-out and counter values
        mov r1, #1024
        ldr r0, =0x20000400
        str r1, [r0, #0]
        str r1, [r0, #4]
        mov r1, #0
        str r1, [r0, #8]
        str r1, [r0, #12]
        
        ; Do systick handler for the first time to set up the timer.
        bl systick_handler

        ; Infinite loop. Do nothing except for handling interrupts. 
loop    b loop

systick_handler  push {lr}

                 ; Flip state
                 ldr r0, =0x20000400
                 ldr r1, [r0, #8]
                 mov r2, #1
                 sub r2, r1
                 str r2, [r0, #8]
                 cbz r1, systick_off

                 
systick_on       bl advance_state    ; Get next on/off time values
                 ldr r3, [r0, #0]    ; Set timeout to off-time
                 bl set_systick
                 ldr r1, =0x4001100c ; Turn off the LEDs
                 mov r0, #0
                 str r0, [r1]
                 pop {pc}

systick_off      ldr r3, [r0, #4]    ; Set timeout to on-time
                 bl set_systick
                 ldr r1, =0x4001100c ; Turn on the LEDs
                 mov r0, #0x300
                 str r0, [r1]
        
                 pop {pc}

; advance_state - Increment counter and find next on-time and off-time values
advance_state  push {r1, r2, lr}

               ; Increment counter modulo 256
               ldr r1, [r0, #12]
               add r1, #1
               and r1, #0xff
               str r1, [r0, #12]

               ; Compute 128 - 128*sin(2*pi*r1/256) and store in r1
               push {r0}
               mov r0, r1
               bl isin
               mov r1, r0
               pop {r0}

               ldr r2, =0x100
               sub r2, r1
               lsl r1, #7
               lsl r2, #7
               str r1, [r0, #0]
               str r2, [r0, #4]

               pop {r1, r2, pc}

; set_systick - reset systick timer
; Input: r3 holds the new systick timeout
set_systick    push {r0, r1, r2, lr}
               ldr r0, =0xe000e010 ; systick base; PM0056 p. 150

               ; Disable systick
               ldr r1, [r0, #0]
               mov r2, #3
               bic r1, r2
               str r1, [r0, #0]

               ; Set timeout.
               str r3, [r0, #4]

               ; Enable systick
               ldr r1, [r0, #0]
               orr r1, #3
               str r1, [r0, #0]

               pop {r0, r1, r2, pc}

; qisin - quarter-waveform integer sine function; linearly interpolated from
;         lookup table */
; Inputs: r0 - degree, range [0,63] (with 256 degrees per circle)
; Output: r0 - rounded (128 + 128*sin(theta))
qisin   push {r1, r2, r3, r4, lr}

        adr r4, sintable

        lsr r1, r0, #3
        sub r2, r1, #1
        cmp r1, #0
        itee eq
        moveq r2, #0
        addne r2, r4
        ldrbne r2, [r2]

        add r1, r4
        ldrb r1, [r1]

        and r3, r0, #7
        mov r4, #8
        sub r4, r3

        mul r2, r4
        mul r1, r3
        add r1, r2
        lsr r0, r1, #4
        
        pop {r1, r2, r3, r4, pc}

sintable DCB 50, 98, 142, 180, 212, 236, 250, 255

; isin - integer sine function; linearly interpolated from lookup table
; Inputs: r0 - degree, range [0,255] (256 degrees per circle)
; Output: r0 - rounded (128 + 128*sin(theta))
isin  push {r1, r2, r3, lr}

      asr r2, r0, #6
      and r0, #0x3f
      and r2, #3

      and r3, r2, #1
      cmp r3, #0
      itt ne
      movne r1, #64
      subne r0, r1, r0

      bl qisin

      mov r1, #128
      and r3, #2
      cmp r3, #2
      ite eq
      addeq r0, r1, r0
      subne r0, r1, r0

      pop {r1, r2, r3, pc}

  align
  END
