
; RST labels
null_exec    equ $00
memcpy_small equ $08
memset_small equ $10
memset       equ $18
bankswitch   equ $20
call_hl      equ $28
wait_vblank  equ $30
rst38_err    equ $38


; Seconds-to-frames converter
; "wait 30 seconds" is nice RGBDS magic :D
second  EQUS "* 60"
seconds EQUS "* 60"
frames  EQUS "" ; lol


STACK_SIZE = $40

SGB_PACKET_SIZE = 16

