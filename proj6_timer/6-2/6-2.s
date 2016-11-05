  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler
        
; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400          ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1   ; Entry point (+1 for thumb mode)
  DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  DCD systick_handler + 1 ; 
  ;DCD 0, 0, 0, 0, 0, 0 
  ;DCD ext0_handler + 1    ; IRQ6 : external interrupt from exti controller

Reset_Handler
COUNT   equ 0x20000400
OLDCNT  equ 0x20000404
PRESSED equ 0x20000408
SIMUL   equ 0x2000040C
BREAK   equ 0x20000410         ; indicates that we should break out of delay

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

        ; Initialize the systick timer to branch to systick every 10 ms
        ldr r0, =0xe000e010 ; systick base; PM0056 p. 150 
        ldr r1, =40000    ; systick reload value; PM0056 p. 152 
        str r1, [r0, #4]  ; SYSTICK->load 
        ldr r1, [r0, #0]  ; SYSTICK->ctrl; PM0056 p. 151 
        orr r1, #7        ; Set to 7: enable interrupt and counting, non prescaled clock
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
        ldr r1, =SIMUL
        str r0, [r1]
        
        ldr r1, =PRESSED
        str r0, [r1]
        
        ldr r1, =COUNT
        str r0, [r1]
        
        ldr r1, =OLDCNT
        str r0, [r1]

        ; Enable interrupts. 
        ;cpsie i

loop    
        ; Reset break flag
        mov r0, #0
        ldr r1, =BREAK
        str r0, [r1]
        
        ; Check if SIMUL is enabled
        ldr r1, =SIMUL
        ldr r1, [r1]
        cmp r1, #0
        bne simul_enb
simul_dis
        ; SIMUL not enabled, flash alternating
        ldr r0, =SHORT             ; Do alternating blinking.
        ldr r1, =GREEN
        bl blink
        ldr r0, =SHORT
        ldr r1, =BLUE
        bl blink
        b loop
simul_enb
        ; SIMUL is enabled, flash same time
        ldr r0, =SHORT             ; Do simultaneous blinking.
        ldr r1, =BOTH
        bl blink
        b loop

; Returns button state in r0
buttonval
        push {lr}
        ldr r0, =0x40010808
        ldr r0, [r0]
        and r0, #1
        pop {pc}

systick_handler
        push {lr, r0, r1, r2}

        bl buttonval
        ; r0 is now button val
        ldr r1, =PRESSED
        ldr r1, [r1]
        
        cmp r0, r1    ; compare current button state with last button
        beq systick_end
        
        ; We had a button transition, check if its a press or unpress
        cmp r0, #0
        beq unpressed
        ; beq means unpressed
        ; bne means pressed
pressed
        ; set pressed to true
        mov r0, #1
        ldr r1, =PRESSED
        str r0, [r1]
        ; clear count
        mov r0, #0
        ldr r1, =COUNT
        str r0, [r1]
        ; done
        b systick_done
unpressed
        ; set pressed to false
        mov r0, #0
        ldr r1, =PRESSED
        str r0, [r1]
        ; store count in old count
        ldr r0, =COUNT
        ldr r0, [r0]
        ldr r1, =OLDCNT
        str r0, [r1]
        ; set simul to true
        mov r0, #1
        ldr r1, =SIMUL
        str r0, [r1]
        ; clear count
        mov r0, #0
        ldr r1, =COUNT
        str r0, [r1]
        ; set break to true to exit alternating blinking
        mov r0, #1
        ldr r1, =BREAK
        str r0, [r1]
        ; done
        b systick_done
systick_end
        ; increment count
        ldr r0, =COUNT
        ldr r1, [r0]
        add r1, #1
        str r1, [r0]
        ; check simul
        ldr r1, =SIMUL
        ldr r1, [r1]
        mov r0, #0
        cmp r0, r1
        beq systick_done
        ; simul is true, so check if we're done
        ldr r0, =COUNT
        ldr r0, [r0]
        ldr r1, =OLDCNT
        ldr r1, [r1]
        cmp r0, r1
        ble systick_done
        ; count exceeds old count, so we're done with simul
        mov r0, #0
        ldr r1, =SIMUL
        str r0, [r1]
        ; set break to true to exit simul mode immediately
        mov r0, #1
        ldr r1, =BREAK
        str r0, [r1]
        ; done
        
systick_done
        pop {pc, r0, r1, r2}
        
; r0, length of delay
delay   push {lr, r0, r1}
        
dloop   ldr r1, =BREAK
        ldr r1, [r1]
        cmp r1, #0
        bne dfinish
        cbz r0, dfinish
        sub r0, #1
        b dloop     ; Unconditional jump; PM0056 p. 92 
        
dfinish pop {pc, r0, r1}
        
        
; r0: length of blink
; r1: data to write to odr
blink
        push {r0, r1, r2, lr}      ; Push; see RM0041 p. 68
        ldr r2, =0x4001100C        ; PORTC->odr; see RM0041 p. 113
        str r1, [r2]
        ; uses r0 for delaying
        bl delay
        
        mov r0, #0
        str r0, [r2]
bfinish
        ldr r0, =0x50000           ; delay between blinks
        bl delay

        pop {r0, r1, r2, pc}       ; pop pc as procedure return (from lr)

  align
  END

