
wait: MACRO
    ld c, \1
.delay\@
    rst wait_vblank
    dec c
    jr nz, .delay\@
ENDM


wait_vram: MACRO
.waitVRAM\@
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, .waitVRAM\@
ENDM
