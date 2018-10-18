
; dbr value, nb_times
; Writes nb_times consecutive bytes with value.
dbr: MACRO
    REPT \2
        db \1
    ENDR
ENDM

; dwr value, nb_times
; Writes nb_times consecutive words with value.
dwr: MACRO
    REPT \2
        dw \1
    ENDR
ENDM

; db's everything given to it, and terminates with a NUL
; For strings, obviously.
dstr: MACRO
    REPT _NARG
        db \1
        shift
    ENDR
    db 0
ENDM

; Places a sprite's data, but with screen coords instead of OAM coords
dspr: MACRO
    db LOW(\1 + 16)
    db LOW(\2 + 8)
    db \3
    db \4
ENDM

; dwcoord y, x, base
dwcoord: MACRO
    dw (\1) * SCRN_VX_B + (\2) + (\3)
ENDM

; dptr symbol
; Places a symbol's bank and ptr
;
; dptr symbol_b, symbol_p
; Places a symbol's bank and another's ptr
; Useful for expressions: `dptr Label, Label+1`
dptr: MACRO
    db BANK(\1)
    IF _NARG < 2
        dw \1
    ELSE
        dw \2
    ENDC
ENDM


lda: MACRO
    IF \1 == 0
        xor a
    ELSE
        ld a, \1
    ENDC
ENDM

lb: MACRO
    ld \1, ((\2) << 8) | (\3)
ENDM

ln: MACRO
REGISTER\@ = \1
VALUE\@ = 0
INDEX\@ = 1
    REPT _NARG
        shift
INDEX\@ = INDEX\@ + 1
        IF \1 > $0F
            FAIL "Argument {INDEX} to `ln` must be a 4-bit value!"
        ENDC
VALUE\@ = VALUE\@ << 8 | \1
    ENDR

    ld REGISTER\@, VALUE\@

PURGE REGISTER\@
PURGE VALUE\@
PURGE INDEX\@
ENDM

; ldcoord reg16, y, x, base
ldcoord: MACRO
    IF "\1" == "bc"
        db $01
    ELIF "\1" == "de"
        db $11
    ELIF "\1" == "hl"
        db $21
    ELIF "\1" == "sp"
        db $31
    ELSE
        FAIL "Invalid 1st operand to ldcoord, \1 is not a 16-bit register"
    ENDC
    dwcoord \2, \3, \4
ENDM


; sgb_packet packet_type, nb_packets, 
sgb_packet: MACRO
SGBPacket:
    db (\1 << 3) | (\2)
NB_REPT = _NARG + (-2)

    REPT NB_REPT
        SHIFT
        db \2
    ENDR
    PURGE NB_REPT

SGBPacketEnd:
PACKET_SIZE = SGBPacketEnd - SGBPacket
    IF PACKET_SIZE != SGB_PACKET_SIZE
        dbr 0, SGB_PACKET_SIZE - PACKET_SIZE
    ENDC

    PURGE SGBPacket
    PURGE SGBPacketEnd
    PURGE PACKET_SIZE
ENDM
