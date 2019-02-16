
NB_ROM_BANKS = 2

SECTION "Header", ROM0[$100]

EntryPoint::
    ld b, $60
    jr LogoFade

    dbr 0, $150 - $104

    ; Header ends here

LogoFade:
    xor a
    ldh [rAUDENA], a

.fadeLogo
    ld c, 7 ; Number of frames between each logo fade step
.logoWait
    ld a, [rLY]
    cp a, SCRN_Y
    jr nc, .logoWait
.waitVBlank
    ld a, [rLY]
    cp a, SCRN_Y
    jr c, .waitVBlank
    dec c
    jr nz, .logoWait
    ; Shift all colors (fading the logo progressively)
    ld a, b
    rra
    rra
    and $FC ; Ensures a proper rotation and sets Z for final check
    ldh [rBGP], a
    ld b, a
    jr nz, .fadeLogo ; End if the palette is fully blank (flag set from `and $FC`)

    ; xor a
    ldh [rDIV], a

Reset::
    di
    ld sp, wStackBottom

    xor a
    ldh [rAUDENA], a

.waitVBlank
    ld a, [rLY]
    cp SCRN_Y
    jr c, .waitVBlank
    xor a
    ldh [rLCDC], a


    ; Perform some init
    ; xor a
    ldh [rAUDENA], a

    ; Init HRAM
    ; Also clears IE, but we're gonna overwrite it just after
    ld c, LOW(hClearStart)
.clearHRAM
    xor a
    ld [$ff00+c], a
    inc c
    jr nz, .clearHRAM

    ; Copy OAM DMA routine
    ld hl, OAMDMA
    lb bc, OAMDMAEnd - OAMDMA, LOW(hOAMDMA)
.copyOAMDMA
    ld a, [hli]
    ld [$ff00+c], a
    inc c
    dec b
    jr nz, .copyOAMDMA

    ld a, LCDCF_ON | LCDCF_BGON
    ldh [hLCDC], a
    ldh [rLCDC], a

    ld a, IEF_VBLANK
    ldh [rIE], a
    xor a
    ei ; Delayed until the next instruction: perfectly safe!
    ldh [rIF], a
    
    
    ; Init code goes here



SECTION "OAM DMA routine", ROM0

OAMDMA:
    ldh [rDMA], a
    ld a, $28
.wait
    dec a
    jr nz, .wait
    ret
OAMDMAEnd:
