#importonce
#import "./rle.asm"
#import "./rleCharPad.asm"

.filenamespace rle


.macro @rle_import(file) {rleImportFile(file)}
.macro @rle_decode_charpad(charmap, colormap) {LIBSCREEN_SETBACKGROUND_RLE_AA(charmap, colormap)}
