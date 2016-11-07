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
COUNT   equ 0x20000400    ; used to time led states
MODE    equ 0x20000404    ; blue is 0, green is 1, print score is 2, lost is 3
PRESSED equ 0x20000408    ; set by ext0 interrupt, read and cleared every systick
POINTS  equ 0x2000040C    ; set to number of points scored

GREEN   equ 0x200              ; Address in ODR to write to
BLUE    equ 0x100
BOTH    equ 0x300

SHORT   equ 0xFF00             ; Number of iterations

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
        str r1, [r0, #8]    ; EXTI->rtsr; event 0 rising; see RM0041 p. 139
        str r1, [r0, #0]    ; EXTI->imr; unmask line 0 
        
        ; Set up the IRQ in the NVIC. See PM0056 p. 118
        ldr r0, =0xe000e404 ; Address of NVIC->ipr1; PM0056 p. 128 
        ldr r1, [r0]        ; NVIC->ipr1; PM0056 p. 125 
        bic r1, #0xff0000   ; Zero out bits corresponding to IRQ6 
        str r1, [r0]        ; Set IRQ6 priority to 0 (highest) 
        
        ldr r0, =0xe000e100 ; NVIC->iser0; PM0056 p. 120 
        mov r2, #0x40       ; Bit corresponding to IRQ6 
        str r2, [r0]        ; NVC->iser0; set enabled 

        ; Initialize the systick timer to branch to systick every 1 ms
        ldr r0, =0xe000e010 ; systick base; PM0056 p. 150 
        ldr r1, =3000    ; systick reload value; PM0056 p. 152 
        str r1, [r0, #4]  ; SYSTICK->load 
        ldr r1, [r0, #0]  ; SYSTICK->ctrl; PM0056 p. 151 
        orr r1, #3        ; Set to 3: enable interrupt and counting
        str r1, [r0, #0]
        
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
        
        mov r0, #0
        ldr r1, =COUNT
        str r0, [r1]
        
        ldr r1, =MODE
        str r0, [r1]
        
        ldr r1, =PRESSED
        str r0, [r1]
        
        ldr r1, =POINTS
        str r0, [r1]

        ; Enable interrupts. 
        cpsie i

loop            
        b loop

ext0_handler  push {lr, r0, r1}

        ; Skip the handler if the button is no longer pressed. 
        ldr r0, =0x40010808
        ldr r0, [r0]
        and r0, #1 ; Test bit 0 
        cbz r0, skip_ext0
  
        ; Set PRESSED to true, this is all this interrupt is responsible for
        mov r0, #1
        ldr r1, =PRESSED
        str r0, [r1]
  
        ; Clear pending-bit in EXTI->pr; see RM0041 p. 140 
        ldr r0, =0x40010414 ; EXTI->pr, see RM0041 p. 140 
        mov r1, #1
        str r1, [r0]

        ; Clear pending-bit in interrupt controller 
        ldr r0, =0xe000e280 ; NVIC->icpr0; see PM0051 p. 123 
        mov r1, #0x40
        str r1, [r0]
        
skip_ext0     pop {pc, r0, r1} ; Return from interrupt. 

systick_handler
        push {lr, r0, r1, r2}
        
        ; increment count each time
        ldr r1, =COUNT
        ldr r0, [r1]
        add r0, #1
        str r0, [r1]

        ; switch on our current mode
        ldr r1, =MODE
        ldr r0, [r1]
        cmp r0, #0
        beq systick_blue      ; blue state
        cmp r0, #1
        beq systick_green     ; green state
        cmp r0, #2
        beq systick_points    ; flash points state
        
systick_dead
        ; otherwise, we are in dead state, do nothing
        mov r0, #0
        bl set_leds
        b systick_done

systick_blue
        ; check if we should transition to green
        ldr r2, =COUNT
        ldr r2, [r2]
        cmp r2, #1000
        ble systick_blue_cont
        ; we are done, transition to green (1)
        mov r0, #1
        str r0, [r1]
        ; clear count
        mov r0, #0
        ldr r2, =COUNT
        str r0, [r2]
        b systick_done
systick_blue_cont
        ; continuously set to blue while in this state
        ldr r0, =BLUE
        bl set_leds
        ; check if we got pressed
        ldr r2, =PRESSED
        ldr r0, [r2]
        cmp r0, #0
        beq systick_done
        ; otherwise, set our mode to dead
        mov r0, #3
        str r0, [r1]
        b systick_done
        
systick_green
        ; check if we should transition to blue
        ldr r2, =COUNT
        ldr r2, [r2]
        bl green_len       ; sets r0 to 1 / n
        cmp r2, r0
        ble systick_green_cont
        ; we are done, transition back to blue (0)
        mov r0, #0
        str r0, [r1]
        ; clear count
        mov r0, #0
        ldr r2, =COUNT
        str r0, [r2]
        b systick_done
systick_green_cont
        ; continuously set to green
        ldr r0, =GREEN
        bl set_leds
        ; check if we got pressed
        ldr r2, =PRESSED
        ldr r0, [r2]
        cmp r0, #0
        beq systick_done
        ; user pressed it! Woohoo!
        ; go to point mode
        mov r0, #2
        ldr r2, =MODE
        str r0, [r2]
        ; increment points
        ldr r2, =POINTS
        ldr r0, [r2]
        add r0, #1
        str r0, [r2]
        b systick_done

systick_points
        ; hard code the blinks in this systick because we
        ; don't care about the length of blinks too much here
        ldr r2, =POINTS
        ldr r2, [r2]
        mov r0, #0
        bl set_leds
        mov r0, #0x300000
        bl delay
systick_points_check
        cmp r2, #0
        bne systick_points_blink
        ; done blinking out the points
        ; go back to blue state
        mov r0, #0
        str r0, [r1]
        ; reset count
        ldr r1, =COUNT
        mov r0, #0
        str r0, [r1]
        b systick_done
systick_points_blink
        ldr r0, =BOTH
        bl set_leds
        mov r0, #0x100000
        bl delay
        mov r0, #0
        bl set_leds
        mov r0, #0x100000
        bl delay
        sub r2, #1
        b systick_points_check
systick_done
        ; clear the press
        ldr r2, =PRESSED
        mov r0, #0
        str r0, [r2]
        pop {pc, r0, r1, r2}

; returns in r0 the amount of time to wait based on POINTS
; formula is 1/n, when n == 0, returns 1 second.
; NOTE: this means that on point 0 and point 1, there will be
; no change in the length of time green displays for.
green_len
        push {lr, r1, r2}
        mov r0, #0
        mov r1, #1000      ; 1 second in ms
        ldr r2, =POINTS    ; num points
        ldr r2, [r2]
        cmp r2, #0         ; check if div by 0, if so return 1 second
        bne green_len_div
        mov r0, #1000
        b green_len_done
green_len_div
        add r0, #1
        sub r1, r2
        cmp r1, #0
        bge green_len_div
green_len_done
        pop {pc, r1, r2}
        
; Takes number of delay iterations in r0. 
delay   push {r0}
        
dloop   cbz r0, dfinish
        sub r0, #1
        b dloop     ; Unconditional jump; PM0056 p. 92 
        
dfinish  pop {r0}
         bx lr 

; r0: data to write to odr
set_leds
        push {lr, r0, r1}
        ldr r1, =0x4001100C
        str r0, [r1]
        pop {pc, r0, r1}

  align
  END

