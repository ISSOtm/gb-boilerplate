
SECTION "rst00", ROM0[$0000]
; Please do not call
; Traps execution errors (mostly to $FFFF / $0000)
rst00:
    ; Pad, in case we come from FFFF and read a 2-byte operand
    nop
    nop
    jp NullExecError

SECTION "rst08", ROM0[$0008]
; Please call using `rst memcpy_small`
; Copies c bytes of data from de to hl
MemcpySmall:
    ld a, [de]
    ld [hli], a
    inc de
    dec c
    jr nz, MemcpySmall
EmptyFunc::
    ret

SECTION "rst10", ROM0[$0010]
; Please call using `rst memset_small`
; Sets c bytes at hl with the value in a
MemsetSmall:
    ld [hli], a
    dec c
    jr nz, MemsetSmall
    ret

SECTION "rst18", ROM0[$0017]
; Please do not call. Use `rst memset`, or, if absolutely needed, `call rst18`.
; Sets bc bytes at hl with the value in d
Memset:
    ld a, d
; Please call using `rst memset`
; Sets bc bytes at hl with the value in a
rst18:
    ld d, a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, Memset
    ret

SECTION "rst20", ROM0[$0020]
; Please call using `rst bankswitch`
; Properly switches to a ROM bank
; @param a The ROM bank to switch to
; NOTE: only switches the lower 8 bytes, the upper bit (for 512 banks) is not considered
ROMbankswitch:
    ldh [hCurROMBank], a
    ld [rROMB0], a
    ret

SECTION "rst28", ROM0[$0028]
; Please call using `rst call_hl`
; Jumps to hl. Use as a placeholder for `call hl`!
; Will error out if the target is in RAM
CallHL:
    bit 7, h ; Prevent jumping into RAM (doesn't protec against returning to it, but hey :D)
    jr nz, .err
    jp hl
.err
    jp HLJumpingError

SECTION "rst30", ROM0[$0030]
; Please call using `rst wait_vblank`
; Waits for the VBlank interrupt
; Note: if the interrupt occurs without being waited for, it will skip performing some actions
WaitVBlank:
    xor a
    ldh [hVBlankFlag], a
.waitVBlank
    halt
    jr z, .waitVBlank
    ret

SECTION "rst38", ROM0[$0038]
; Please do not call
; Traps execution of the $FF byte (which serves as padding of the ROM)
rst38:
    jp Rst38Error


SECTION "Interrupt vectors", ROM0[$0040]

transfer_reg: MACRO
    ldh a, [h\1]
    ldh [r\1], a
ENDM

    ; VBlank
    push af
    transfer_reg LCDC
    jp VBlankHandler

    ; LCD
    push af
    push bc
    ldh a, [hScanlineFXIndex]
    ld c, a
    ld a, [c] ; Get port ID
    jr LCDHandler

    ; Timer
    reti
    ds 7

    ; Serial
    reti

; Fit in a 7-byte function, too!

; Jumps immediately to de, no questions asked (except RAM targets?).
CallDE::
    push de
    bit 7, d
    ret z
    jp DEJumpingError

    ; Joypad
    reti


LCDHandler:
    ld b, a ; Save port ID for later
    inc c
    inc c
    ld a, [c] ; Get next effect's scanline
    dec a ; Compensate for processing time
    ldh [rLYC], a ; Get set up (hopefully this should reset the interrupt trigger line)
    ld a, c ; Point to next effect's port ID
    inc a
    ldh [hScanlineFXIndex], a
    dec c
    ; Wait a bit to write during HBlank, to avoid gfx artifacts
    ld a, 4
.waitMode0
    dec a
    jr nz, .waitMode0

    ; Check if we're trying to write to P1 ($FF*00*)
    ld a, b
    and a ; Note: `and $7F` can be used instead to have control on bit 7 (if ever needed)
    ; Perform common ops
    ld a, [c] ; Get value
    ; rP1 is hardwired to instead perform textbox ops
    jr nz, .notTextbox

    ldh [rSCY], a ; Store value, which is actually for SCY (dat plot twist, eh?)
    xor a
    ldh [rSCX], a
    ld c, LOW(rLCDC)
    ldh a, [hLCDC] ; Retrieve LCDC value
    and ~(LCDCF_WINON | LCDCF_BG8000 | LCDCF_OBJON)
    or LCDCF_BG9C00
    ; Note: this is scrapped support for sprites on the textbox
    ; It was initially planned for JP diacritics.
    ; If for whatever reason, you need to re-activate this feature...
    ; ...uncomment this, and remove "LCDCF_OBJON" from above.
    ; 
    ; ld [c], a ; Apply LCDC modification
    ; ; Perform OAM DMA to get textbox's sprites
    ; ; Luckily, sprites are hidden during DMA
    ; ; Also no sprites should be present on the textbox 1st row, hiding our trickery >:P
    ; ld a, HIGH(wTextboxOAM)
    ; call hOAMDMA
    ; ; Reload OAM on next frame
    ; ldh a, [hCurrentOAMBuffer]
    ; ldh [hOAMBuffer], a
    ; jr .onlyOneEffect

.notTextbox
    ld c, b ; Retrieve port
    res 7, c
    ld [c], a ; Apply FX
    bit 7, b
    jr z, .onlyOneEffect
    ldh a, [hSecondFXAddr]
    ld c, a
    ldh a, [hSecondFXValue]
    ld [$ff00+c], a
.onlyOneEffect
    pop bc
    pop af
    reti


SECTION "VBlank handler", ROM0

VBlankHandler:
    push bc

    ; ============= Here are things that need to be updated, even on lag frames ==============

    ; Update IO from HRAM shadow
    transfer_reg SCY
    transfer_reg SCX
    transfer_reg WY
    transfer_reg WX


    ldh a, [hWhichScanlineBuffer]
    ld c, a
    ; Get first effect's scanline
    ld a, [$ff00+c]
    dec a ; Compensate for the processing time
    ; NOTE: this assumes no effect is scheduled on line 0
    ; This should never happen; instead, use the HRAM shadow regs (hSCY, etc.)
    ldh [rLYC], a
    inc c
    ld a, c
    ldh [hScanlineFXIndex], a


    ; Update OAM if needed
    ; Do this last so it will go through even without time
    ; This will simply cause sprites to not be displayed on the top few scanlines, but that's not as bad as palettes not loading at all, huh?
    ldh a, [hOAMBufferHigh]
    and a
    jr z, .dontUpdateOAM
    ld b, a
    ; Reset OAM buffer high vect
    xor a
    ldh [hOAMBufferHigh], a
    ; Perform DMA as specified
    ld a, b
    call hOAMDMA
.dontUpdateOAM


    ; ============== In case of lag, don't update further, to avoid breaking stuff ===============

    ldh a, [hVBlankFlag]
    and a
    jr nz, .lagFrame


    ; Poll joypad and update regs

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
    ; On SsAB held, soft-reset
    and $0F
    jp z, Reset

    or $F0 ; Set 4 upper bits
    xor b ; Mix with D-pad bits, and invert all bits (such that pressed=1) thanks to "or $F0"
    ld b, a

    ldh a, [hHeldButtons]
    cpl
    and b
    ldh [hPressedButtons], a

    ld a, b
    ldh [hHeldButtons], a

    ; Release joypad
    ld a, $30
    ld [$ff00+c], a

    pop bc
    pop af


    ; The main code was waiting for VBlank, so tell it it's OK by resetting Z
    xor a
    inc a ; Clear Z
    ldh [hVBlankFlag], a ; Mark VBlank as ACK'd
    reti


.lagFrame
    pop bc
    pop af
    reti
