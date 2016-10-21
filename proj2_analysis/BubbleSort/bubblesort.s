; ECE 3056 Homework Code - Jeremy Feltracco


;;; Directives
    PRESERVE8
    THUMB

; Vector Table Mapped to Address 0 at Reset
; Linker requires __Vectors to be exported

    AREA    RESET, DATA, READONLY
    EXPORT  __Vectors

__Vectors
    DCD  0x20001000     ; stack pointer value when stack is empty
    DCD  Reset_Handler  ; reset vector

    ALIGN
; The program
; Linker requires Reset_Handler
    AREA    MYCODE, CODE, READONLY
    ENTRY
    EXPORT Reset_Handler

Reset_Handler
;;;;;;;;;;User Code Starts from the next line;;;;;;;;;;;;

array_declaration               ; fills out memory starting at init_addr with static arr values
    ldr r0,init_addr            ; pointer to beginning of memory to fill
    ldr r1,=data                ; pointer of static data to copy to init_addr
    ldr r2,num_elements         ; number of elements to do this on
cp  cmp r2,#0                   ; if num elements is 0
    beq sort_start              ; stop adding values
    ldr r3,[r1],#4              ; load value from static memory
    str r3,[r0],#4              ; store value in ram
    sub r2,#1                   ; decrement counter
    b   cp
sort_start                      ; sorts an array starting at init_addr, ending at r1
    mov r1,r0                   ; r1 points to one past end of array
    mov r2,#1                   ; non-zero value to not trip next cond
sort_outer                      ; assuming r1 = end of array and r2 = unchanged flag
    cmp r2,#0                   ; r2 == 0 means we didn't change
    beq bin_search_init         ; if didn't change, we are done, do binary search
    mov r2,#0                   ; r2 was 1, reset it to 0, assume we didn't change initially
    ldr r0,init_addr            ; reset r0 to beginning of array
    ldr r3,[r0],#4              ; r3 and r4 contain values to swap
sort_inner
    ldr r4,[r0],#4
    ; r3 and r4 are array vals that we check to swap
    sub r5,r3,r4                ; check if r3 < r4
    cmp r5,#0
    ble sort_inner_shift        ; if so, skip swap
    mov r2,#1                   ; otherwise specify that we had to swap
    ; actually swap the values
    str r4,[r0, #-8]            ; b/c already incremented r0, r3 is in -8
    str r3,[r0, #-4]            ; and r4 is in -4, so swap in opposite way
    b sort_inner_fin
sort_inner_shift                ; section where we shift r4 down to r3
    mov r3,r4                   ; only if we didn't swap
sort_inner_fin
    cmp r0,r1                   ; check if cur pointer has reached end
    beq sort_outer              ; if so, loop up to outer level
    b sort_inner                ; else do another inner loop

bin_search_init                 ; initializes variables to enter the binary search
    ldr r0,init_addr
    ldr r1,num_elements         ; load num_elements to 9
    ldr r2,search_val           ; initialize r2 to the value searching for
bin_search
; r0 is pointer to beginning of list we're searching
; r1 is number of elements in the list to search (x4 for bytes)
; r2 is element we are searching for
    cmp r1,#0                   ; if no more elements
    beq failed                  ; didn't find it, quit
    lsr r3,r1,#1                ; convert num elements / 2 (round down)
    lsl r3,#2                   ; convert above elements to byte address
    ; r3 now contains offset to middle element from r0
    add r4,r0,r3                ; get pointer to middle element by adding r0
    ldr r5,[r4]                 ; get value at middle element
    cmp r2,r5
    beq success                 ; if equal, we found the element, address is in *r4*
    lsr r1,#1                   ; half our num elements
    bge top_half
    b   bin_search              ; bottom half, r0 stays the same
top_half
    add r0,r4,#4                ; one past the previous middle value becomes new start
    b   bin_search
    
failed
    mov r10,#0                  ; no address found!
    b quit
success
    mov r10,r4                  ; found address, store in r10
quit b quit                     ; done, loop forever

  AREA   CONSTANT, DATA, READONLY
; number of elements in data
num_elements  DCD 9
  ALIGN
; initial address of space we want to store data in
init_addr     DCD 0x200000f0
  ALIGN
data          DCD 0x94ff3e02, 0x000c0001, 0x36fbaaaa, 0x21211212, 0x0004bff2, 0x00382159, 0x77777777, 0x44444443, 0x00889900
  ALIGN
; value we are going to search for
search_val    DCD 0x21211212
  END