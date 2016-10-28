  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler

; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400         ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1  ; Entry point (+1 for thumb mode)

Reset_Handler
  ; Your code here

  align
  END
