
SECTION "Error handler memory", WRAM0

; ID of the error that occurred
wErrorType::
; Once the ID has been used, this is re-used as a status, to route calls because stack space is available
wErrorDrawStatus::
; The status is also used to determine which dump to print
wErrorWhichDump::
    db

wErrorRegs::
; Value of A when the handler is called
; Re-used as part of the reg dump
wErrorA::
; Re-used to hold last frame's keys
wErrorHeldButtons::
    db ; a
; Re-used to hold the number of frames till the debugger is unlocked
wErrorFramesTillUnlock::
    db ; f
    dw ; bc
    dw ; de
wErrorHL::
    dw
wErrorSP::
    dw


SECTION "Shadow OAM", WRAM0,ALIGN[8]

wShadowOAM::
    ds $A0


SECTION "Stack", WRAM0[$E000 - STACK_SIZE]

wStackTop::
    ds STACK_SIZE
wStackBottom::
