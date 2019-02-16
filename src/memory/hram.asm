
SECTION "HRAM", HRAM

; The OAM DMA routine
hOAMDMA::
    ds 8 ; OAMDMAEnd - OAMDMA


; Currently-loaded ROM bank, useful to save back (eg. during ints)
hCurROMBank::
    db


; Used by the PB16 decompressor
pb16_byte0::
    db


; Place variables that need to be zero-cleared on init (and soft-reset) below
hClearStart::


; Used to let VBlank know it need to ACK
; NOTE: VBlank doesn't preserve AF **on purpose** when this is set
; Thus, make sure to wait for Z set before continuing
hVBlankFlag::
    db

; Values transferred to hw regs on VBlank
hLCDC::
    db
hSCY::
    db
hSCX::
    db
hWY::
    db
hWX::
    db
hBGP::
    db
hOBP0::
    db
hOBP1::
    db


; Joypad regs
hHeldButtons::
    db
hPressedButtons::
    db

; High byte of the shadow OAM buffer to be transferred
; Reset by the VBlank handler to signal transfer completion
hOAMBufferHigh::
    db
