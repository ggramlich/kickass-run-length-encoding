#importonce

.filenamespace rle

.label SCROLY       = $D011
.label SCROLX       = $D016
.label VMCSB        = $D018
.label EXTCOL       = $D020
.label BGCOL0       = $D021
.label BGCOL1       = $D022
.label BGCOL2       = $D023
.label SCREENRAM    = $0400
.label COLORRAM     = $D800

.label ZeroPage5 = $06

.macro LIBSCREEN_SETDISPLAYENABLE_V(bEnable)
{
    lda SCROLY
    .if (bEnable)           // Build-time condition (not run-time)
    {
        ora #%00010000      // Set bit 4
    }
    else
    {
        and #%11101111      // Clear bit 4
    }
    sta SCROLY
}

.macro SETWORD_VA(wValue, wAdress) {
    lda #<wValue
    sta wAdress
    lda #>wValue
    sta wAdress+1
}
