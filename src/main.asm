; vim: ft=gbasm

include "src/lib/hardware.inc"
include "src/lib/hardware_compat.inc"
include "src/lib/macros.inc"
include "assets/character_map.inc"
include "src/lib/constants.inc"
include "src/lib/definitions.inc"

section "Header", ROM0[$100]
EntryPoint:
  di
  jp Start

rept $150 - $104
  db 0
endr

section "Sprites", oam
dstruct CursorSprite, leftCursorSprite
dstruct CursorSprite, rightCursorSprite
dstruct ArrowSprite, arrowSprite

Section "Fast Data", hram
include "src/lib/fast_variables.inc"

section "Data", wram0
include "src/lib/variables.inc"

section "Game Code", ROM0
Start:
  CopyConstToVar rTAC, TACF_START
  CopyVars Seed, rDIV
  CopyVars Seed+1, rDIV
  CopyVars Seed+2, rDIV

.initDisplay
  xor a
  ld [rBGP], a
  ld [rOBP0], a
  ld [rOBP1], a
  ld [rSCY], a
  ld [rSCX], a

  call LCDControl.waitVBlank
  call LCDControl.turnOff

.copyTiles
  ld hl, $8000
  ld de, Tiles
  ld bc, Tiles.end - Tiles

.copyTilesLoop
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, .copyTilesLoop

setupGame:
  ld sp, $DFFF

  call Reseed
  call initVariables

  ld a, $4D
  ld [leftCursorSprite_Tile], a
  ld a, $4F
  ld [rightCursorSprite_Tile], a
  ld a, $01
  ld [arrowSprite_Tile], a
  xor a
  ld [cursorData_YPos], a
  ld [cursorData_XPos], a
  ld [leftCursorSprite_Attr], a
  ld [rightCursorSprite_Attr], a
  ld [arrowSprite_Attr], a

.main
  call drawTitleScreen

  call LCDControl.turnOn
  call fadeIn
  jr start_input

start_input:
  ReadPad

  ld a, [_PAD]
	cp a, 0
  call z, resetPress

  ; wait til button is released
  ld a, [_PAD_PRESSED]
  cp a, 1
  jp z, start_input

  ; Start
  ld a, [_PAD]
	and PADF_START
	call nz, startGame

  ld a, [game_started]
  cp 1
  jr nz, start_input
  jr start_level_input

start_level_input:
  ld a, LEVEL_X_MAX
  ld [arrowData_XPos], a
  ld a, LEVEL_Y_MIN
  ld [arrowData_YPos], a

  call LCDControl.waitVBlank

  xor a
  ld [BEGIN_GUESS+0], a
  ld [BEGIN_GUESS+1], a
  ld [BEGIN_GUESS+2], a
  ld [cursorData_YPos], a
  ld [cursorData_XPos], a
  call draw_cursor
  jr level_input

level_input:
  ReadPad

  ld a, [_PAD]
	cp a, 0
  call z, resetPress

  ; wait til button is released
  ld a, [_PAD_PRESSED]
  cp a, 1
  jp z, level_input

  ; up
  ld a, [_PAD]
	and PADF_UP
	call nz, moveArrowUp

  ; down
	ld a, [_PAD]
	and PADF_DOWN
	call nz, moveArrowDown

  ; A
  ld a, [_PAD]
	and PADF_A
  jp nz, select_level

  call LCDControl.waitVBlank
  ld a, [arrowData_XPos]
  ld [arrowSprite_XPos], a
  ld a, [arrowData_YPos]
  ld [arrowSprite_YPos], a

  jr level_input

input:
	ReadPad

  ld a, [_PAD]
	cp a, 0
  call z, resetPress

  ; wait til button is released
  ld a, [_PAD_PRESSED]
  cp a, 1
  jp z, input

  ld a, [_PAD]
	and PADF_UP
	call nz, moveCursorUp

  ; down
	ld a, [_PAD]
	and PADF_DOWN
	call nz, moveCursorDown

  ; left
 	ld a, [_PAD]
	and PADF_LEFT
	call nz, moveCursorLeft

  ; right
  ld a, [_PAD]
	and PADF_RIGHT
	call nz, moveCursorRight

  ; B
  ld a, [_PAD]
	and PADF_B
  call nz, select.bPress

  ; A
  ld a, [_PAD]
	and PADF_A
  call nz, select

  ; Start
  ld a, [_PAD]
	and PADF_START
	; call nz, select.startPress

  ; Start
  ld a, [_PAD]
	and PADF_SELECT
	call nz, select.startPress

.drawFrame:
  GetDisplayNumber attempts, display_attempts, 2

  call LCDControl.waitVBlank
  call draw_cursor
  call drawGuess
  DrawNumber BEGIN_ATTEMPTS, display_attempts, 2

  jp input

slowdown:
  ld bc, $1fff

.slowLoop
  dec bc
  ld a, b
  cp a, 0
  jr nz, .slowLoop
  ret

initVariables:
  call guess.init

  xor a
  ld [leftCursorSprite_Attr], a
  ld [level_select], a
  ld [rightCursorSprite_Attr], a
  ld [pad_column_selection], a
  ld [pad_row_selection], a
  ld [game_started], a
  ld [attempts], a
  ld [display_attempts], a
  ld [display_attempts+1], a
  ld [display_max_attempts], a
  ld [display_max_attempts+1], a
  ret

select_level:
  PadPressed
  ld a, [level_select]
  cp a, 0
  call z, setLevelTo1
  cp a, 1
  call z, setLevelTo2
  cp a, 2
  call z, setLevelTo3
  cp a, 3
  call z, setLevelTo4

  GetDisplayNumber max_attempts, display_max_attempts, 2
  GetDisplayNumber attempts, display_attempts, 2
  call LCDControl.waitVBlank
  call clearHint
  call clearOtherMessage
  call setCursorOrigin
  xor a
  ld [arrowSprite_XPos], a
  ld [arrowSprite_YPos], a
  DrawNumber BEGIN_MAX_ATTEMPTS, display_max_attempts, 2
  DrawNumber BEGIN_ATTEMPTS, display_attempts, 2
  jp input

setLevelTo1:
  ld a, 99
  ld [max_attempts], a
  ret
setLevelTo2:
  ld a, 20
  ld [max_attempts], a
  ret
setLevelTo3:
  ld a, 7
  ld [max_attempts], a
  ret
setLevelTo4:
  ld a, 5
  ld [max_attempts], a
  ret

moveArrowDown:
  PadPressed
  ld a, [arrowData_YPos]
  cp a, LEVEL_Y_MAX
  ret z
  add 8
  ld [arrowData_YPos], a
  ld a, [level_select]
  inc a
  ld [level_select], a
  ret

moveArrowUp:
  PadPressed
  ld a, [arrowData_YPos]
  cp a, LEVEL_Y_MIN
  ret z
  ld a, [arrowData_YPos]
  sub 8
  ld [arrowData_YPos], a
  ld a, [level_select]
  dec a
  ld [level_select], a
  ret

resetPress:
  xor a
  ld [_PAD_PRESSED], a
  ret

startGame:
  PadPressed
  call Reseed
  call RandomNumber
  ld [RN], a
  ld a, 1
  ld [game_started], a

  call LCDControl.waitVBlank
  call fadeOut
  call LCDControl.turnOff
  call drawGameScreen
  call LCDControl.turnOn
  call fadeIn
  call setCursorOrigin
  ret

setCursorOrigin:
  ld a, NUMPAD_ORIGIN_X
  ld [cursorData_XPos], a
  ld a, NUMPAD_ORIGIN_Y
  ld [cursorData_YPos], a
  ld a, 1
  ld [pad_row_selection], a
  ld [pad_column_selection], a
  ret

draw_cursor:
  ld a, [cursorData_XPos]
  sub 8
  ld [leftCursorSprite_XPos], a
  add 16
  ld [rightCursorSprite_XPos], a

  ld a, [cursorData_YPos]
  ld [leftCursorSprite_YPos], a
  ld [rightCursorSprite_YPos], a
  ret

moveCursorRight:
  PadPressed
  ld a, [cursorData_XPos]
  cp a, NUMPAD_MENU_X_MAX
  ret z

  add 16
  ld [cursorData_XPos], a

  ld a, [pad_column_selection]
  inc a
  ld [pad_column_selection], a
  ret

moveCursorLeft:
  VariableSet _PAD_PRESSED, 1
  ld a, [cursorData_XPos]
  cp a, NUMPAD_MENU_X_MIN
  ret z

  sub 16
  ld [cursorData_XPos], a

  ld a, [pad_column_selection]
  dec a
  ld [pad_column_selection], a
  ret

moveCursorDown:
  VariableSet _PAD_PRESSED, 1
  ld a, [cursorData_YPos]
  cp a, NUMPAD_MENU_Y_MAX
  ret z
  add 8
  ld [cursorData_YPos], a

  ld a, [pad_row_selection]
  inc a
  ld [pad_row_selection], a
  ret

moveCursorUp:
  VariableSet _PAD_PRESSED, 1
  ld a, [cursorData_YPos]
  cp a, NUMPAD_MENU_Y_MIN
  ret z
  sub 8
  ld [cursorData_YPos], a

  ld a, [pad_row_selection]
  dec a
  ld [pad_row_selection], a
  ret

select:
  VariableSet _PAD_PRESSED, 1
  ld a, [pad_row_selection]
  cp 0
  jr z, .selectRow0
  cp 1
  jr z, .selectRow1
  cp 2
  jr z, .selectRow2
  cp 3
  jr z, .selectRow3
  ret

.selectRow0:
  ld a, [pad_column_selection]
  cp 0
  jr z, .select1
  cp 1
  jr z, .select2
  cp 2
  jr z, .select3
  ret

.select1:
  ld a, 1
  call addNumberToGuess
  ret

.select2:
  ld a, 2
  call addNumberToGuess
  ret

.select3:
  ld a, 3
  call addNumberToGuess
  ret

.selectRow1:
  ld a, [pad_column_selection]
  cp 0
  jr z, .select4
  cp 1
  jr z, .select5
  cp 2
  jr z, .select6
  ret

.select4:
  ld a, 4
  call addNumberToGuess
  ret

.select5:
  ld a, 5
  call addNumberToGuess
  ret

.select6:
  ld a, 6
  call addNumberToGuess
  ret

.selectRow2:
  ld a, [pad_column_selection]
  cp 0
  jr z, .select7
  cp 1
  jr z, .select8
  cp 2
  jr z, .select9
  ret

.select7:
  ld a, 7
  call addNumberToGuess
  ret

.select8:
  ld a, 8
  call addNumberToGuess
  ret

.select9:
  ld a, 9
  call addNumberToGuess
  ret

.selectRow3:
  ld a, [pad_column_selection]
  cp 0
  jr z, .selectBackspace
  cp 1
  jr z, .select0
  cp 2
  jr z, .selectEnter
  ret

.bPress:
  VariableSet _PAD_PRESSED, 1
.selectBackspace:
  ld a, [guessData_Length]
  cp 0
  ret z
  call removeNumberFromGuess
  ret

.select0:
  ld a, [guessData_Length]
  cp 0
  ret z
  xor a
  call addNumberToGuess
  ret

.startPress:
  PadPressed
.selectEnter:
  ld a, [guessData_Length]
  cp 0
  ret z

  ld a, [attempts]
  inc a
  ld [attempts], a


  call clearHint
  call setCursorOrigin
  ld a, [RN]
  ld b, a
  ld a, [guessData_Value]
  cp b
  jr z, drawYouWon

  ld a, [max_attempts]
  ld b, a
  ld a, [attempts]
  cp b
  jr nc, drawYouLose

  ld a, [RN]
  ld b, a
  ld a, [guessData_Value]

  sub b
  jp c, drawTooLow
  jp nc, drawTooHigh

  ret

drawYouWon:
  ld hl, BEGIN_HINT
  ld de, YouWonMessage
  ld bc, YouWonMessage.end - YouWonMessage
.loop:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, .loop
  jr drawChooseLevel

drawYouLose:
  ld hl, BEGIN_HINT
  ld de, YouLoseMessage
  ld bc, YouLoseMessage.end - YouLoseMessage
.loop:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, .loop
  jr drawChooseLevel

drawChooseLevel:
  call LCDControl.waitVBlank
  DisplayAttempts
  ld hl, BEGIN_PRESS_START
  ld de, ChooseLevelMessage
  ld bc, ChooseLevelMessage.end - ChooseLevelMessage
.loopChooseLevel:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, .loopChooseLevel
  jr restartGame

restartGame:
  ld sp, $DFFF
  call Reseed
  call RandomNumber
  ld [RN], a
  call initVariables
  xor a
  ld [cursorData_XPos], a
  ld [cursorData_YPos], a
  call initVariables
  jp start_level_input

drawTooHigh:
  call guess.init
  ld hl, BEGIN_HINT
  ld de, TooHighMessage
  ld bc, TooHighMessage.end - TooHighMessage
.loop:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, .loop
  ret

drawTooLow:
  call guess.init
  ld hl, BEGIN_HINT
  ld de, TooLowMessage
  ld bc, TooLowMessage.end - TooLowMessage
.loop:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, .loop
  ret

clearHint:
  ld hl, BEGIN_HINT
  ld de, ClearMessage
  ld bc, ClearMessage.end - ClearMessage
.loop:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, .loop
  ret

clearOtherMessage:
  ld hl, BEGIN_PRESS_START
  ld de, ClearMessage
  ld bc, ClearMessage.end - ClearMessage
.loop:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, .loop
  ret

include "src/lib/lcd_control.inc"
include "src/lib/helpers.inc"
include "src/lib/guess.inc"

section "Tiles", ROM0
Tiles:
include "assets/tiles.inc"
Tiles.end

section "Maps", ROM0
include "assets/map.inc"
include "assets/title_map.inc"

TooLowMessage:
  db "Too Low"
.end

TooHighMessage:
  db "Too High"
.end

YouWonMessage:
  db "You Won!"
.end

YouLoseMessage:
  db "You Lose!"
.end

PressStartMessage:
  db "Press  Start"
.end

ChooseLevelMessage:
  db "Choose Level"
.end

ClearMessage:
  db "            "
.end

; include "assets/finish_screen_map.inc"
; include "assets/title_screen_map.inc"
