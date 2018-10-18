
SECTION "Build date", ROM0

    db "Built "
BuildDate::
INCBIN "res/build.date"
    db 0
