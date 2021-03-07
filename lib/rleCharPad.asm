#importonce
#import "./rleHelper.asm"

.filenamespace rle

.macro LIBSCREEN_SETBACKGROUND_RLE_AA(wBackground, wColor)
{
    // LIBSCREEN_SETDISPLAYENABLE_V(false) // Disable display while updating
    // Init self modifying code in subroutine with parameters values
    SETWORD_VA(wBackground, libScreenRleSetBackground.mapLengthByte)
    SETWORD_VA(wColor, libScreenRleSetBackground.fromColorRepeating)
    SETWORD_VA(wColor, libScreenRleSetBackground.fromColorLiteral)
    /* Initialize positions */
    SETWORD_VA(SCREENRAM-1, libScreenRleSetBackground.screenRamPosition)
    SETWORD_VA(COLORRAM-1, libScreenRleSetBackground.colorRamPosition)

    jsr libScreenRleSetBackground.processChunk
    LIBSCREEN_SETDISPLAYENABLE_V(true) // Re-enable display
}

libScreenRleSetBackground:
{
    /* Positions must be initialized before the subroutine is called to
       SCREENRAM-1
       COLORRAM-1
       off by one, because the last iteration of the dex-loops has x=1
    */
    screenRamPosition:
        .byte 0, 0
    colorRamPosition:
        .byte 0, 0

    /*
      inner loop
      - advance mapLengthByte by value of accu
      - advance screenRamPosition by length of last chunk
      - advance colorRamPosition by length of last chunk
    */
    nextChunk:
        :addAccuToAddressedValue mapLengthByte : mapLengthByte
        :addByteValueToAddressedValue ZeroPage5 : screenRamPosition : screenRamPosition
        :addByteValueToAddressedValue ZeroPage5 : colorRamPosition : colorRamPosition

    /* read byte representing the length of the next chunk
       length > 0: next character is repeated length times
       length = 0: rts
       length < 0: the following chunk of -length characters is copied literally
     */
    processChunk:
        lda mapLengthByte:$AAAA
        beq exit

        sta ZeroPage5
        bmi literalChunk

    repeatingChunk:
    /* initialize self modifying code */
        :addByteValueToAddressedValue #1 : mapLengthByte : repeatingValue
        copyAddress(screenRamPosition, toScreenRamRepeating)
        copyAddress(colorRamPosition, toColorRepeating)

    /* read character */
        lda repeatingValue:$AAAA
        ldx ZeroPage5
    repeatingChunkLoopCharacter:
        sta toScreenRamRepeating:SCREENRAM,x
        dex
        bne repeatingChunkLoopCharacter

    /* read color */
        tay
        lda fromColorRepeating:$AAAA,y
        ldx ZeroPage5
    repeatingChunkLoopColor:
        sta toColorRepeating:SCREENRAM,x
        dex
        bne repeatingChunkLoopColor

    /* end loop mapLengthByte must be incremented by 2 */
        lda #2
        jmp nextChunk

    /* placed here to prevent "jump distance is too far" */
    exit:
        rts

    literalChunk:
        copyAddress(screenRamPosition, toScreenRamLiteral)
        copyAddress(colorRamPosition, toColorLiteral)
    /* negative value in ZeroPage5 to positive */
        sec
        lda #0
        sbc ZeroPage5
        sta ZeroPage5
        tax

    /* initialize self modifying code */
    copyAddress(mapLengthByte, literalValue)

    literalChunkLoop:
        lda literalValue:$AAAA,x
        sta toScreenRamLiteral:SCREENRAM,x
        tay
        lda fromColorLiteral:$AAAA,y
        sta toColorLiteral:COLORRAM,x
        dex
        bne literalChunkLoop

    incToNextChunkForLiteral:
    /* end loop mapLengthByte must be incremented by chunk-length + 1 */
        ldx ZeroPage5
        inx
        txa

        jmp nextChunk

}

/* byteValue can be address or immediate */
.pseudocommand addByteValueToAddressedValue byteValue : addressNum1WordValue : addressSumWordValue
{
    lda byteValue
    :addAccuToAddressedValue addressNum1WordValue : addressSumWordValue
}

.pseudocommand addAccuToAddressedValue addressNum1WordValue : addressSumWordValue
{
    clc
    adc addressNum1WordValue
    sta addressSumWordValue

    lda _16bitnextArgument(addressNum1WordValue)
    adc #0
    sta _16bitnextArgument(addressSumWordValue)
}

.function _16bitnextArgument(arg) {
    .if (arg.getType() == AT_IMMEDIATE) {
        .return CmdArgument(arg.getType(), >arg.getValue())
    }
    .return CmdArgument(arg.getType(), arg.getValue()+1)
}

.macro copyAddress(from, to)
{
    lda from
    sta to
    lda from+1
    sta to+1
}
