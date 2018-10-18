
SECTION "Error handler trampoline", ROM0

handle_error: MACRO
    ; Make sure we're not interrupted
    di
    ; Save current value of A
    ld [wErrorA], a
    ld a, \1 ; Preserve flags, don't "xor a"!
    ; Will generate an extra, unnecessary "jr", but eh.
    jr ErrorHandler
ENDM


HLJumpingError::
    handle_error ERROR_JUMP_HL
DEJumpingError::
    handle_error ERROR_JUMP_DE
NullExecError::
    handle_error ERROR_NULL_EXEC
Rst38Error::
    handle_error ERROR_RST38

; Perform minimal init, and jump to error handler in ROMX
ErrorHandler:
    ld [wErrorType], a

    ld a, BANK(_ErrorHandler)
    ld [rROMB0], a
    xor a ; Ensure the error handler WILL be called, even if we end up with 512 banks
    ld [rROMB1], a
    jp _ErrorHandler


SECTION "Error handler", ROMX

; Note: `call` is BANNED in this section of code!!
_ErrorHandler:
    ld [wErrorSP], sp
    ld sp, wErrorSP
    push hl
    push de
    push bc
    ld a, [wErrorA]
    push af

    xor a
    ldh [rNR52], a
    
    ldh a, [rLCDC]
    bit 7, a
    jr z, .lcdOff
.waitVBlank
    ld a, [rLY]
    cp SCRN_Y
    jr c, .waitVBlank
    xor a
    ld [rLCDC], a
.lcdOff

    ; Load palette
    ld a, $F4
    ld [rBGP], a

    xor a
    ldh [rSCY], a
    ldh [rSCX], a

    ld hl, _SCRN0
    ld bc, SCRN_VX_B * SCRN_Y_B
.clearVRAM
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clearVRAM

    ; Copy monospace font
    ld hl, vBlankTile
    ld de, ErrorFont
    ld bc, $800
.copyFont
    ld a, [de]
    inc de
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .copyFont

    ; Oh noes!!
    ; ld hl, _SCRN0
    ; ld de, ErrorUwu
.copyUwU
    ld a, [de]
    inc de
    ld [hli], a
    and a
    jr nz, .copyUwU

    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a
    lb bc, 180, LOW(rLY)
.delayBetweenUwUs
    ld a, [$ff00+c]
    cp SCRN_Y + 1
    jr nz, .delayBetweenUwUs
.waitUwUBlank
    ld a, [$ff00+c]
    cp SCRN_Y
    jr nz, .waitUwUBlank
    dec b
    jr nz, .delayBetweenUwUs

    ldcoord hl, 8, 0, _SCRN0
.copySeriousUwU
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, .copySeriousUwU
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, .copySeriousUwU

    ; But can you do it in 0.5x A presses?
    lb bc, 1, LOW(rP1)
    ld a, $10 ; Select buttons
    ld [$ff00+c], a
.waitAPress
REPT 6
    ld a, [$ff00+c]
ENDR
    xor b
    rra
    jr nc, .waitAPress
    dec b ; No, you can't.
    jr z, .waitAPress


ErrorDumpScreen:
    ldh a, [rLY]
    sub SCRN_Y
    jr nz, ErrorDumpScreen
    ldh [rLCDC], a

    ld hl, _SCRN0
    ld bc, SCRN_VX_B * SCRN_Y_B
.clearSCRN0
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clearSCRN0

    ld a, [wErrorType]
    ld c, a
    ; We can start using wErrorType for the drawing status purpose
    xor a
    ld [wErrorDrawStatus], a

    ld a, c
    cp ERROR_UNKNOWN
    jr c, .errorTypeOK
    ld a, ERROR_UNKNOWN
.errorTypeOK
    add a, a
    add a, LOW(ErrorStrings)
    ld l, a
    adc a, HIGH(ErrorStrings)
    sub l
    ld h, a
    ld a, [hli]
    ld d, [hl]
    ld e, a
    ldcoord hl, 3, 1, _SCRN0
    jp StrcpyNoTerm
PrintedErrorStr:
    ld a, c
    cp ERROR_UNKNOWN
    jp nc, PrintHex
PrintedErrorCode:
    ld hl, wErrorDrawStatus
    inc [hl]

    pop bc
    ; From now on, there is 1 free stack slot, which means we can `call`!!
    ld de, AFStr
    ldcoord hl, 4, 1, _SCRN0
    call StrcpyNoTerm
    ld a, b
    call PrintHex
    ld a, c
    call PrintHex

    ldcoord hl, 0, 1, _SCRN0
    ld de, SendNudesStr
    call Strcpy
    ld l, $21 ; ld hl, $9821
    call Strcpy

    ldcoord hl, 5, 1, _SCRN0
    ld de, BCStr
    call StrcpyNoTerm
    pop bc
    ld a, b
    call PrintHex
    ld a, c
    call PrintHex
    inc hl
    ; ld de, DEStr
    call StrcpyNoTerm
    pop bc
    ld a, b
    call PrintHex
    ld a, c
    call PrintHex

    ldcoord hl, 14, 1, _SCRN0
    ld de, MemRegs
.printMemReg
    ld a, [de]
    and a
    jr z, .doneWithMemRegs
    call StrcpyNoTerm
    ld a, [de]
    inc de
    ld c, a
    ld a, [de]
    inc de
    ld b, a
    ld a, [bc]
    call PrintHex
    inc hl
    jr .printMemReg
.doneWithMemRegs

    ldcoord hl, 15, 1, _SCRN0
    ld de, BankStr
    call StrcpyNoTerm
    ldh a, [hCurROMBank]
    call PrintHex

    ldcoord hl, 16, 1, _SCRN0
    ld de, BuildDate
    call Strcpy

    ; Now, we need to do the hex dumps. Boi are we in for some trouble!
    ldcoord hl, 6, 1, _SCRN0
    ld de, HLStr
    call StrcpyNoTerm

    ; We first need to get the two registers (both at once to increase efficiency)
    pop bc ; hl
    pop de ; sp
    ; Move SP back by 2 entries (we need to preserve those for dump printing)
    add sp, -4

    ld a, b
    call PrintHex
    ld a, c
    call PrintHex

    ld b, d
    ld c, e
    ldcoord hl, 10, 1, _SCRN0
    ld de, SPstr
    call StrcpyNoTerm
    ld a, b
    call PrintHex
    ld a, c
    call PrintHex

    ldcoord hl, 6, 10, _SCRN0
    ld de, ViewStr
    call StrcpyNoTerm
    ldcoord hl, 10, 10, _SCRN0
    ld de, ViewStr
    call StrcpyNoTerm

    ld a, 2
    ld [wErrorWhichDump], a
.printOneDump
    call PrintDump
    ld hl, wErrorWhichDump
    dec [hl]
    jr nz, .printOneDump

    ldcoord hl, 8, 0, _SCRN0
    ld [hl], $1F
    ld l, $80 ; ld hl, $9980
    ld [hl], $1F


    ld a, 4
    ldh [rSCX], a
    ld a, $FF
    ldh [rSCY], a

    ; ld a, $FF
    ld [wErrorHeldButtons], a
    ld a, 30
    ld [wErrorFramesTillUnlock], a

    ld a, LCDCF_ON | LCDCF_BGON
    ldh [rLCDC], a


; From now on, we'll be using the upper byte of the AF stack slot to save keys
; Thus, we're only allowed 2 stack slots (bc and de)
ErrorLoop:
    ; Wait till next frame
    ld a, [rLY]
    cp SCRN_Y + 1
    jr c, ErrorLoop
    ; Wait until right before VBlank, to account for the overhead
.waitVBlank
    ld a, [rLY]
    cp SCRN_Y
    jr nz, .waitVBlank

    ld c, LOW(rP1)
    ld a, $20 ; Select D-pad
    ld [$ff00+c], a
REPT 6
    ld a, [$ff00+c]
ENDR
    or $F0 ; Set 4 upper bits (give them consistency)
    ld b, a

    ; Filter impossible D-pad combinations
    and $0C ; Filter only Down and Up
    ld a, b
    jr nz, .notUpAndDown
    or $0C ; If both are pressed, "unpress" them
    ld b, a
.notUpAndDown
    and $03 ; Filter only Left and Right
    jr nz, .notLeftAndRight
    ld a, b
    or $03 ; If both are pressed, "unpress" them
    ld b, a
.notLeftAndRight
    swap b ; Put D-pad buttons in upper nibble

    ld a, $10 ; Select buttons
    ld [$ff00+c], a
REPT 6
    ld a, [$ff00+c]
ENDR
    or $F0 ; Set 4 upper bits
    and b ; Mix with D-pad bits (use AND because pressed=0)
    ld b, a

    ld a, [wErrorHeldButtons]
    cpl
    or b
    ld e, a ; Pressed buttons

    ld a, b
    ld [wErrorHeldButtons], a

    ; Release joypad
    ld a, $30
    ld [$ff00+c], a


    ld hl, wErrorFramesTillUnlock
    ld a, [hl]
    and a
    jr z, .dumpsUnlocked
    ld a, b ; Get back held buttons
    and 3 ; Get only A and B
    jr nz, ErrorLoop ; Decrement only if both are held
    dec [hl]
    jr ErrorLoop

.dumpsUnlocked
    ld hl, wErrorWhichDump
    bit 1, e ; Check if B was pressed
    jr z, .changeDumps
    ; Prevent any dump-related operation if none have been chosen yet
    ld a, [hl]
    and a
    jr z, ErrorLoop

    ; Select dump to act upon
    ld hl, wErrorHL
    dec a
    jr z, .usingHLDump
    ld hl, wErrorSP
.usingHLDump
    bit 0, b
    lb bc, 1, 8
    jr nz, .moveSmall
    lb bc, $10, 1
.moveSmall
    ld a, [hl]
    bit 7, e
    jr z, .moveDown
    bit 6, e
    jr z, .moveUp
    inc hl ; The next 2 target the high byte only
    ld a, [hl]
    bit 5, e
    jr z, .moveLeft
    bit 4, e
    jp nz, ErrorLoop
.moveRight
    add a, b
    db $0E
.moveLeft
    sub a, b
    ld [hl], a
    jr .redrawDump

.moveDown
    add a, c
    ld [hli], a
    jr nc, .redrawDump
    inc [hl]
    jr .redrawDump
.moveUp
    sub c
    ld [hli], a
    jp nc, .redrawDump
    dec [hl]
.redrawDump
    call PrintDump
    ; Unfortunately, PrintDump uses 3 stack slots, which overwrites the held keys and the lock frames
    ; We can get around that, though
    ld hl, wErrorFramesTillUnlock
    xor a ; Set no remaining frames (obv)
    ld [hld], a
    ; Set all buttons as held (avoid spurious presses)
    ld [hl], a
    jp ErrorLoop

.changeDumps
    ld a, [hl]
    dec a ; Check if on HL dump
    jr z, .toSPDump
    ld [hl], 1 ; Switch to HL dump (from SP dump & no dump yet)
    db $21
.toSPDump
    ld [hl], 2

    ; Toggle cursors
    ld a, $1F
    jr z, .emptyHLCursor
    ld a, $7F
.emptyHLCursor
    ld [$9900], a
    xor $1F ^ $7F
    ld [$9980], a
    jp ErrorLoop


PrintHex:
    ld b, a
    and $F0
    swap a
    cp 10
    jr c, .highIsDigit
    add a, "A" - "0" - 10
.highIsDigit
    add a, "0"
    ld [hli], a

    ld a, b
    and $0F
    cp 10
    jr c, .lowIsDigit
    add a, "A" - "0" - 10
.lowIsDigit
    add a, "0"
    ld [hli], a

    ld a, [wErrorDrawStatus]
    and a
    jp z, PrintedErrorCode
    ret


StrcpyNoTerm:
    ld a, [de]
    inc de
    and a
    jr z, .return
    ld [hli], a
    jr StrcpyNoTerm

.return
    ld a, [wErrorDrawStatus]
    and a
    jp z, PrintedErrorStr
    ret


PrintDump:
    ldcoord hl, 6, 15, _SCRN0
    ld bc, wErrorHL
    ld a, [wErrorWhichDump]
    dec a
    jr z, .dumpHL
    ldcoord hl, 10, 15, _SCRN0
    ld bc, wErrorSP
.dumpHL
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a
    call PrintHex
    ld a, e
    call PrintHex
    inc hl

    ld a, e
    sub 4 * 2
    ld e, a
    ld a, d
    sbc 0
    ld d, a

    ld b, 3
.printNextRow
    ld a, b
    ld bc, $20 - 20
    add hl, bc
    ld c, 4
    ld b, a
    dec a ; Dirty hack: when the LCD is on, VBlank expires slightly too early, so only 2 rows can be drawn correctly
    jr nz, .printOneWord
    ; If the LCD is off, no worries
    ldh a, [rLCDC]
    add a, a
    jr nc, .printOneWord
    ; Wait till VBlank again
.waitVBlank
    ldh a, [rLY]
    cp $90
    jr nz, .waitVBlank
.printOneWord
    inc hl
    push bc ; B is trashed by PrintHex, so we need to save it anyways; but we also free c for storage
    ld a, [de]
    inc de
    ld c, a ; Save low byte for later
    ld a, [de]
    inc de
    call PrintHex
    ld a, c
    call PrintHex
    pop bc
    dec c
    jr nz, .printOneWord

    dec b
    jr nz, .printNextRow
    ret


SendNudesStr:
    dstr "Pls send us a pic"
    dstr "of this screen! =)"

ErrorStrings:
    dw .hlJumpErrorStr
    dw .deJumpErrorStr
    dw .nullExecErrorStr
    dw .rst38ErrorStr

    dw .unknownErrorStr

.hlJumpErrorStr
    dstr "Bad hl jump"
.deJumpErrorStr
    dstr "Bad de jump"
.nullExecErrorStr
    dstr "Null exec"
.rst38ErrorStr
    dstr "rst 38 error"
.unknownErrorStr
    dstr "Unk err $"


AFStr:
    dstr "AF:"
BCStr:
    dstr "BC:"
DEStr:
    dstr "DE:"
HLStr:
    dstr "HL:"
SPstr:
    dstr "SP:"

ViewStr:
    dstr "View:"

MemRegs:
    dstr "STAT:"
    dw rSTAT
    dstr "IE:"
    dw rIE
    db 0

BankStr:
    dstr "Bank:"

ErrorFont:
REPT " " - 1
    dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
ENDR
    dw $0000, $0000, $0800, $0C00, $0800, $0000, $0000, $0000 ; Empty arrow
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 ; Space

	; Symbols 1
	dw $8000, $8000, $8000, $8000, $8000, $0000, $8000, $0000
	dw $0000, $6C00, $6C00, $4800, $0000, $0000, $0000, $0000
	dw $4800, $FC00, $4800, $4800, $4800, $FC00, $4800, $0000
	dw $1000, $7C00, $9000, $7800, $1400, $F800, $1000, $0000
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 ; %, empty slot for now
	dw $6000, $9000, $5000, $6000, $9400, $9800, $6C00, $0000
	dw $0000, $3800, $3800, $0800, $1000, $0000, $0000, $0000
	dw $1800, $2000, $2000, $2000, $2000, $2000, $1800, $0000
	dw $1800, $0400, $0400, $0400, $0400, $0400, $1800, $0000
	dw $0000, $1000, $5400, $3800, $5400, $1000, $0000, $0000
	dw $0000, $1000, $1000, $7C00, $1000, $1000, $0000, $0000
	dw $0000, $0000, $0000, $0000, $3000, $3000, $6000, $0000
	dw $0000, $0000, $0000, $7C00, $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000, $0000, $6000, $6000, $0000
	dw $0000, $0400, $0800, $1000, $2000, $4000, $8000, $0000
	dw $3000, $5800, $CC00, $CC00, $CC00, $6800, $3000, $0000
	dw $3000, $7000, $F000, $3000, $3000, $3000, $FC00, $0000
	dw $7800, $CC00, $1800, $3000, $6000, $C000, $FC00, $0000
	dw $7800, $8C00, $0C00, $3800, $0C00, $8C00, $7800, $0000
	dw $3800, $5800, $9800, $FC00, $1800, $1800, $1800, $0000
	dw $FC00, $C000, $C000, $7800, $0C00, $CC00, $7800, $0000
	dw $7800, $CC00, $C000, $F800, $CC00, $CC00, $7800, $0000
	dw $FC00, $0C00, $0C00, $1800, $1800, $3000, $3000, $0000
	dw $7800, $CC00, $CC00, $7800, $CC00, $CC00, $7800, $0000
	dw $7800, $CC00, $CC00, $7C00, $0C00, $CC00, $7800, $0000
	dw $0000, $C000, $C000, $0000, $C000, $C000, $0000, $0000
	dw $0000, $C000, $C000, $0000, $C000, $4000, $8000, $0000
	dw $0400, $1800, $6000, $8000, $6000, $1800, $0400, $0000
	dw $0000, $0000, $FC00, $0000, $FC00, $0000, $0000, $0000
	dw $8000, $6000, $1800, $0400, $1800, $6000, $8000, $0000
	dw $7800, $CC00, $1800, $3000, $2000, $0000, $2000, $0000
	dw $0000, $2000, $7000, $F800, $F800, $F800, $0000, $0000 ; "Up" arrow, not ASCII but otherwise unused :P

	; Uppercase
	dw $3000, $4800, $8400, $8400, $FC00, $8400, $8400, $0000
	dw $F800, $8400, $8400, $F800, $8400, $8400, $F800, $0000
	dw $3C00, $4000, $8000, $8000, $8000, $4000, $3C00, $0000
	dw $F000, $8800, $8400, $8400, $8400, $8800, $F000, $0000
	dw $FC00, $8000, $8000, $FC00, $8000, $8000, $FC00, $0000
	dw $FC00, $8000, $8000, $FC00, $8000, $8000, $8000, $0000
	dw $7C00, $8000, $8000, $BC00, $8400, $8400, $7800, $0000
	dw $8400, $8400, $8400, $FC00, $8400, $8400, $8400, $0000
	dw $7C00, $1000, $1000, $1000, $1000, $1000, $7C00, $0000
	dw $0400, $0400, $0400, $0400, $0400, $0400, $F800, $0000
	dw $8400, $8800, $9000, $A000, $E000, $9000, $8C00, $0000
	dw $8000, $8000, $8000, $8000, $8000, $8000, $FC00, $0000
	dw $8400, $CC00, $B400, $8400, $8400, $8400, $8400, $0000
	dw $8400, $C400, $A400, $9400, $8C00, $8400, $8400, $0000
	dw $7800, $8400, $8400, $8400, $8400, $8400, $7800, $0000
	dw $F800, $8400, $8400, $F800, $8000, $8000, $8000, $0000
	dw $7800, $8400, $8400, $8400, $A400, $9800, $6C00, $0000
	dw $F800, $8400, $8400, $F800, $9000, $8800, $8400, $0000
	dw $7C00, $8000, $8000, $7800, $0400, $8400, $7800, $0000
	dw $7C00, $1000, $1000, $1000, $1000, $1000, $1000, $0000
	dw $8400, $8400, $8400, $8400, $8400, $8400, $7800, $0000
	dw $8400, $8400, $8400, $8400, $8400, $4800, $3000, $0000
	dw $8400, $8400, $8400, $8400, $B400, $CC00, $8400, $0000
	dw $8400, $8400, $4800, $3000, $4800, $8400, $8400, $0000
	dw $4400, $4400, $4400, $2800, $1000, $1000, $1000, $0000
	dw $FC00, $0400, $0800, $1000, $2000, $4000, $FC00, $0000

	; Symbols 2
	dw $3800, $2000, $2000, $2000, $2000, $2000, $3800, $0000
	dw $0000, $8000, $4000, $2000, $1000, $0800, $0400, $0000
	dw $1C00, $0400, $0400, $0400, $0400, $0400, $1C00, $0000
	dw $1000, $2800, $0000, $0000, $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $FF00
	dw $C000, $6000, $0000, $0000, $0000, $0000, $0000, $0000

	; Lowercase
	dw $0000, $0000, $7800, $0400, $7C00, $8400, $7800, $0000
	dw $8000, $8000, $8000, $F800, $8400, $8400, $7800, $0000
	dw $0000, $0000, $7C00, $8000, $8000, $8000, $7C00, $0000
	dw $0400, $0400, $0400, $7C00, $8400, $8400, $7800, $0000
	dw $0000, $0000, $7800, $8400, $F800, $8000, $7C00, $0000
	dw $0000, $3C00, $4000, $FC00, $4000, $4000, $4000, $0000
	dw $0000, $0000, $7800, $8400, $7C00, $0400, $F800, $0000
	dw $8000, $8000, $F800, $8400, $8400, $8400, $8400, $0000
	dw $0000, $1000, $0000, $1000, $1000, $1000, $1000, $0000
	dw $0000, $1000, $0000, $1000, $1000, $1000, $E000, $0000
	dw $8000, $8000, $8400, $9800, $E000, $9800, $8400, $0000
	dw $1000, $1000, $1000, $1000, $1000, $1000, $1000, $0000
	dw $0000, $0000, $6800, $9400, $9400, $9400, $9400, $0000
	dw $0000, $0000, $7800, $8400, $8400, $8400, $8400, $0000
	dw $0000, $0000, $7800, $8400, $8400, $8400, $7800, $0000
	dw $0000, $0000, $7800, $8400, $8400, $F800, $8000, $0000
	dw $0000, $0000, $7800, $8400, $8400, $7C00, $0400, $0000
	dw $0000, $0000, $BC00, $C000, $8000, $8000, $8000, $0000
	dw $0000, $0000, $7C00, $8000, $7800, $0400, $F800, $0000
	dw $0000, $4000, $F800, $4000, $4000, $4000, $3C00, $0000
	dw $0000, $0000, $8400, $8400, $8400, $8400, $7800, $0000
	dw $0000, $0000, $8400, $8400, $4800, $4800, $3000, $0000
	dw $0000, $0000, $8400, $8400, $8400, $A400, $5800, $0000
	dw $0000, $0000, $8C00, $5000, $2000, $5000, $8C00, $0000
	dw $0000, $0000, $8400, $8400, $7C00, $0400, $F800, $0000
	dw $0000, $0000, $FC00, $0800, $3000, $4000, $FC00, $0000

	; Symbols 3
	dw $1800, $2000, $2000, $4000, $2000, $2000, $1800, $0000
	dw $1000, $1000, $1000, $1000, $1000, $1000, $1000, $0000
	dw $3000, $0800, $0800, $0400, $0800, $0800, $3000, $0000
	dw $0000, $0000, $4800, $A800, $9000, $0000, $0000, $0000

	dw $0000, $0800, $0C00, $0E00, $0C00, $0800, $0000, $0000 ; Left arrow

ErrorUwu:
    db "OOPSIE WOOPSIE!! Uwu            "
    db "  We made a fucky               "
    db "  wucky!! A wittle              "
    db " fucko boingo! The              "
    db "code monkeys at our             "
    db "  headquarters are              "
    db "working VEWY HAWD to            "
    db "     fix this!     ",0

    db "                                "
    db "More seriously, I'm             "
    db "sorry, but the game             "
    db "has encountered a               "
    db "fatal error blah                "
    db "blah blah, tl;dr it             "
    db "has crashed.                    "
    db "To allow us to fix              "
    db "it, please be a                 "
    db "peach and press A =3",0
