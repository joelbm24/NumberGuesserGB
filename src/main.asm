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

section "VBlank Interrupt", ROM0[$0040]
VBlankInterrupt:
	push af
	push bc
	push de
	push hl
	jp VBlankHandler

section "Game Code", ROM0
VBlankHandler:
  ; TODO: Should probably just store the address of the functions in RAM
  ldh a, [message_display]
  cp 0
  jr z, .drawGameState
  cp 1
  call z, clearHint
  cp 2
  call z, drawTooHigh
  cp 3
  call z, drawTooLow
  cp 4
  call z, drawYouWon
  cp 5
  call z, drawYouLose
.drawGameState:
  ldh a, [game_state]
  cp 4
  call z, drawGame
  cp 1
  call z, transitionStartToLevelSelect
  cp 2
  call z, drawLevelSelect
  cp 3
  call z, transitionLevelSelectToGame

  ldh a, [sub_message_display]
  cp 0
  jr z, .exit
  cp 1
  call z, clearOtherMessage
  cp 2
  call z, drawChooseLevel
.exit:
  pop hl
	pop de
	pop bc
	pop af
	reti

Start:
  CopyConstToVar rTAC, TACF_START
  CopyHighVars Seed, rDIV
  CopyHighVars Seed+1, rDIV
  CopyHighVars Seed+2, rDIV

.initDisplay
  xor a
  ldh [rBGP], a
  ldh [rOBP0], a
  ldh [rOBP1], a
  ldh [rSCY], a
  ldh [rSCX], a
  ldh [game_state], a
  ldh [message_display], a
  ldh [sub_message_display], a

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

  ldh a, [_PAD]
	cp a, 0
  call z, resetPress

  ; wait til button is released
  ldh a, [_PAD_PRESSED]
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

hold_level_input:
  halt
level_input:
  ReadPad

  ldh a, [_PAD]
	cp a, 0
  call z, resetPress

  ; wait til button is released
  ldh a, [_PAD_PRESSED]
  cp a, 1
  jp z, hold_level_input

  ; up
  ldh a, [_PAD]
	and PADF_UP
	call nz, moveArrowUp

  ; down
	ldh a, [_PAD]
	and PADF_DOWN
	call nz, moveArrowDown

  ; A
  ldh a, [_PAD]
	and PADF_A
  jp nz, select_level

  halt
  jr level_input

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

  xor a
  ld [attempts], a
  call initVariables

  GetDisplayNumber attempts, display_attempts, 2
  GetDisplayNumber max_attempts, display_max_attempts, 2

  ld a, 3
  ldh [game_state], a

  jp input

hold_input:
  halt
input:
	ReadPad

  ldh a, [_PAD]
	cp a, 0
  call z, resetPress

  ; wait til button is released
  ldh a, [_PAD_PRESSED]
  cp a, 1
  jp z, hold_input

  ldh a, [_PAD]
	and PADF_UP
	call nz, moveCursorUp

  ; down
	ldh a, [_PAD]
	and PADF_DOWN
	call nz, moveCursorDown

  ; left
 	ldh a, [_PAD]
	and PADF_LEFT
	call nz, moveCursorLeft

  ; right
  ldh a, [_PAD]
	and PADF_RIGHT
	call nz, moveCursorRight

  ; B
  ldh a, [_PAD]
	and PADF_B
  call nz, select.bPress

  ; A
  ldh a, [_PAD]
	and PADF_A
  call nz, select

  ; Start
  ldh a, [_PAD]
	and PADF_START
	; call nz, select.startPress

  ; Start
  ldh a, [_PAD]
	and PADF_SELECT
	call nz, select.startPress

  halt

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
  ld [display_max_attempts], a
  ld [display_max_attempts+1], a
  ret


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
  ldh [_PAD_PRESSED], a
  ret

startGame:
  PadPressed
  call Reseed
  call RandomNumber
  ldh [RN], a
  ld a, 1
  ld [game_started], a
  ldh [game_state], a
  xor a
  ld [sub_message_display], a

  call LCDControl.waitVBlank
  call fadeOut
  call LCDControl.turnOff
  call drawGameScreen
  call LCDControl.turnOn
  call fadeIn
  call setCursorOrigin

  ; Enable VBlank Interrupt
	ld a, IEF_VBLANK
  ld b, a
	ldh [rIE], a
	xor a, a
	ldh [rIF], a
  ei

  ret

transitionStartToLevelSelect: ; game_state = 1
  xor a
  ld [BEGIN_GUESS+0], a
  ld [BEGIN_GUESS+1], a
  ld [BEGIN_GUESS+2], a
  ld [cursorData_YPos], a
  ld [cursorData_XPos], a
  call draw_cursor
  ld a, 2
  ldh [game_state], a
  ret

drawLevelSelect: ; game_state = 2
  ld a, [arrowData_XPos]
  ld [arrowSprite_XPos], a
  ld a, [arrowData_YPos]
  ld [arrowSprite_YPos], a
  DrawNumber BEGIN_ATTEMPTS, display_attempts, 2
  ret

transitionLevelSelectToGame: ; game_state = 3
  call clearHint
  call clearOtherMessage
  call setCursorOrigin

  xor a
  ld [arrowSprite_XPos], a
  ld [arrowSprite_YPos], a

  ld a, 1
  ldh [message_display], a
  ldh [sub_message_display], a

  DrawNumber BEGIN_MAX_ATTEMPTS, display_max_attempts, 2
  DrawNumber BEGIN_ATTEMPTS, display_attempts, 2
  ld a, 4
  ldh [game_state], a
  ret

drawGame: ; game_state = 4
  call draw_cursor
  call drawGuess
  DrawNumber BEGIN_ATTEMPTS, display_attempts, 2
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
  PadPressed
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
  PadPressed
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
  PadPressed
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
  PadPressed
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
  PadPressed
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
  GetDisplayNumber attempts, display_attempts, 2

  ; call clearHint
  call setCursorOrigin
  ldh a, [RN]
  ld b, a
  ld a, [guessData_Value]
  cp b
  jr z, setWin

  ld a, [max_attempts]
  ld b, a
  ld a, [attempts]
  cp b
  jr nc, setLose

  ldh a, [RN]
  ld b, a
  ld a, [guessData_Value]

  sub b
  jp c, setTooLow
  jp nc, setTooHigh

  ret

restartGame:
  ld sp, $DFFF
  ld a, 1
  ldh [game_state], a
  call Reseed
  call RandomNumber
  ldh [RN], a
  xor a
  ld [cursorData_XPos], a
  ld [cursorData_YPos], a
  jp start_level_input

setTooHigh:
  ld a, 2
  ldh [message_display], a
  call guess.init
  ret

setTooLow:
  ld a, 3
  ldh [message_display], a
  call guess.init
  ret

setWin:
  ld a, 4
  ldh [message_display], a
  ld a, 2
  ldh [sub_message_display], a
  jp restartGame

setLose:
  ld a, 5
  ldh [message_display], a
  ld a, 2
  ldh [sub_message_display], a
  jp restartGame

drawYouWon: ; message_display = 3
  DrawMessage BEGIN_HINT, YouWonMessage
  ret

drawYouLose: ; message_dipslay = 4
  DrawMessage BEGIN_HINT, YouLoseMessage
  ret

drawChooseLevel: ; sub_message_display = 1
  DrawMessage BEGIN_PRESS_START, ChooseLevelMessage
  ret

drawTooHigh: ; message_display = 1
  DrawMessage BEGIN_HINT, TooHighMessage
  ret

drawTooLow: ; message_display = 2
  DrawMessage BEGIN_HINT, TooLowMessage
  ret

clearHint: ; message_display = 0
  DrawMessage BEGIN_HINT, ClearMessage
  ret

clearOtherMessage: ; sub_message_display = 0
  DrawMessage BEGIN_PRESS_START, OtherClearMessage
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
  db "Too Low     "
.end

TooHighMessage:
  db "Too High    "
.end

YouWonMessage:
  db "You Won!    "
.end

YouLoseMessage:
  db "You Lose!   "
.end

ChooseLevelMessage:
  db "Choose a Level"
.end

ClearMessage:
  db "            "
.end

OtherClearMessage:
  db "              "
.end
