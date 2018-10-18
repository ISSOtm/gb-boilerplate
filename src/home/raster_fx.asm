
SECTION "Raster fx helper functions", ROM0

; Get a pointer to the currently free scanline buffer
; @return a The pointer
; @return c The pointer
; @destroys a c
GetFreeScanlineBuf::
    ldh a, [hWhichScanlineBuffer]
    xor LOW(hScanlineFXBuffer2) ^ LOW(hScanlineFXBuffer1)
    ld c, a
    ret

; Switches to the currently free scanline buffer
; @return c A pointer to the newly freed buffer
; @return b A pointer to the newly used buffer
; @destroys a c
SwitchScanlineBuf::
    call GetFreeScanlineBuf
    ldh [hWhichScanlineBuffer], a
    ld b, a
    xor LOW(hScanlineFXBuffer2) ^ LOW(hScanlineFXBuffer1)
    ld c, a
    ret

; Switches to the currently free scanline buffer, and copies it over to the other buffer
; @destroys a c hl
SwitchAndCopyScanlineBuf::
    call SwitchScanlineBuf
    ld l, b
    ld h, HIGH(hScanlineFXBuffer1)
.loop
    ld a, [hli]
    ld [$ff00+c], a
    inc c
    inc a
    jr nz, .loop
    ret


; Finds the effect applied to a given scanline
; @param b The scanline being looked for
; @return Zero Set if the lookup succeeded
; @return c A pointer to the effect's scanline, otherwise to the terminating $FF byte
; @destroys a c
GetFXByScanline::
    call GetFreeScanlineBuf
.lookup
    ld a, [$ff00+c]
    cp b
    ret nc ; Return if scanline was greater than or equal
    inc c
    inc c
    inc c
    jr .lookup

; Insert effect into the free buffer at the given scanline
; The effect's scanline will have been set, and the other two values will be zero'd
; @param b The scanline to insert the effect at
; @return c A pointer to the new effect's port address
; @return Zero Set if the scanline is already taken (in which case c still holds the correct value)
; @destroys a bc hl
InsertFX::
    call GetFreeScanlineBuf
    ld l, c
    ld h, HIGH(hScanlineFXBuffer1)
    scf ; Don't skip the check
.lookForEnd
    ld a, [hli]
    inc l
    ; C is inherited from previous `cp b`
    jr nc, .skip ; If we're already greater then the scanline, skip this
    cp b
    ret z ; End now if the scanline is already taken, because two FX can't be on the same line
    jr c, .skip ; Skip if we aren't the first greater than the scanline
    ld c, l ; Make c point to the target's value
.skip
    inc l
    inc a
    jr nz, .lookForEnd
    ; Write new terminator ($FF)
    ld [hl], h ; Bet you didn't expect this opcode to ever be used, eh?
    dec l
.copy
    dec l
    dec l
    dec l
    ld a, [hli]
    inc l
    inc l
    ld [hld], a ; If we just copied the target scanline,
    ld a, l ; this points to the value
    cp c ; which we know the address of!
    jr nz, .copy
    ; Move the pointer and init the new fx
    xor a
    ld [hld], a
    ld [hld], a
    ld [hl], b ; Write the desired scanline
    inc a ; Don't have Z set
    ret
    

; Remove effect from the free buffer
; @param b The targeted effect's scanline
; @return Zero Set if the lookup succeeded
; @destroys a c hl
RemoveFX::
    call GetFXByScanline
    ret nz
    ld l, c
    ld h, HIGH(hScanlineFXBuffer1)
    inc c
    inc c
    inc c
.copy
    ; Copy scanline
    ld a, [$ff00+c]
    ld [hli], a
    inc a
    ret z ; End if we copied the terminator
    inc c
    ; Copy port address
    ld a, [$ff00+c]
    ld [hli], a
    inc c
    ; Copy value
    ld a, [$ff00+c]
    ld [hli], a
    inc c
    jr .copy


; Add the textbox raster FX
; Caution: overwrites the currently free fx buffer with the active (+textbox)
; @param b The number of pixels of the textbox to display (0 closes it)
; @destroys a bc de hl
SetUpTextbox::
    ld h, HIGH(hWhichScanlineBuffer)

    ; Check if backup operations should be performed
    ldh a, [hIsTextboxActive]
    and a
    jr nz, .dontBackup
    ld a, b
    and a
    ret z ; Do nothing if the textbox is closed while it is closed (lol)
    ldh a, [hWhichScanlineBuffer]
    ld c, a
    ld l, LOW(hBackupScanlineFXBuffer)
.backup
    ld a, [$ff00+c]
    inc c
    ld [hli], a
    inc a
    jr nz, .backup
    inc a ; ld a, 1
    ldh [hIsTextboxActive], a
    ; Fall through, but this won't get executed
.dontBackup
    ld a, b
    and a
    jr z, .restoreAndQuit

    ; Get pointers to buffers
    ldh a, [hWhichScanlineBuffer]
    ld c, a
    xor LOW(hScanlineFXBuffer2) ^ LOW(hScanlineFXBuffer1)
    ld l, a
    ; Calculate scanline
    ld a, SCRN_Y
    sub b
    ld b, a

    scf
.copy
    ld a, [$ff00+c] ; Get scanline
    cp b
    jr nc, .insertTextbox
    inc c
    ld [hl], a
    ld a, [$ff00+c] ; Read port
    inc c
    inc c ; Skip value, jic
    and a ; Are we copying a textbox FX?
    jr z, .copy ; Abort
    inc l
    ld [hli], a
    dec c
    ld a, [$ff00+c] ; Read value
    inc c
    ld [hli], a
    jr .copy

.restoreAndQuit
    call GetFreeScanlineBuf
.restore
    ld a, [hli]
    ld [$ff00+c], a
    inc c
    inc a
    jr nz, .restore
    ; a = 0
    ldh [hIsTextboxActive], a
    ret

.insertTextbox
    ; Place the textbox FX
    ld [hl], b
    inc l
    ld [hl], 0
    inc l
    ld a, b
    sub SCRN_Y
    ld [hli], a
    ld [hl], $FF ; Don't forget to terminate!
    
    ldh a, [hWhichScanlineBuffer]
    xor LOW(hScanlineFXBuffer2) ^ LOW(hScanlineFXBuffer1)
    ldh [hWhichScanlineBuffer], a
    ret
