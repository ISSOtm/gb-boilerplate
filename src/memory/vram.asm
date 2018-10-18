
SECTION "VRAM", VRAM[$8000]


    ds $1000

; $9000

vBlankTile::
    ds $10

    ds $7F0

; $9800

    ds SCRN_VX_B * SCRN_VY_B ; $400

; $9C00

    ds SCRN_VX_B * SCRN_VY_B ; $400
