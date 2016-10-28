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

        ; Initialize the systick timer. 
        ldr r0, =0xe000e010 ; systick base; PM0056 p. 150 
        ldr r1, =0x100000   ; systick reload value; PM0056 p. 152 
        str r1, [r0, #4]  ; SYSTICK->load 
        ldr r1, [r0, #0]  ; SYSTICK->ctrl; PM0056 p. 151 
        orr r1, #3        ; Set to 3: enable interrupt and counting 
        str r1, [r0, #0]
        
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
        
        ldr r0, =0xe000e100 ; NVIC->iser0; PM0056 p. 120 
        mov r2, #0x40       ; Bit corresponding to IRQ6 
        str r2, [r0]        ; NVC->iser0; set enabled 
        
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
        
        ; Infinite loop. Do nothing except for handling interrupts. 
loop    b loop


ext0_handler  push {lr}

              ; Skip the handler if the button is no longer pressed. 
              ldr r0, =0x40010808
              ldr r0, [r0]
              mov r1, #1
              and r0, r1 ; Test bit 0 
              cbz r0, skip_ext0
        
              ; Load counter value 
              ldr r2, =0x20000400
              ldr r0, [r2]

              bl blink ; Blink [incremented counter] times
        
              ; Clear pending-bit in EXTI->pr; see RM0041 p. 140 
              ldr r0, =0x40010414 ; EXTI->pr, see RM0041 p. 140 
              mov r1, #1
              str r1, [r0]

              ; Clear pending-bit in interrupt controller 
              ldr r0, =0xe000e280 ; NVIC->icpr0; see PM0051 p. 123 
              mov r1, #0x40
              str r1, [r0]
        
skip_ext0     pop {pc} ; Return from interrupt. 


systick_handler  push {lr}

                 ; Increment counter
                 ldr r0, =0x20000400
                 ldr r1, [r0]
                 add r1, #1
                 str r1, [r0]
        
                 pop {pc}

        
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
