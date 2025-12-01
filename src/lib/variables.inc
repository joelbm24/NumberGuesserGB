; vim: ft=gbasm

SCREEN_UPDATE:
  ds 1

_PAD:
  ds 1

_PAD_PRESSED:
  ds 1

numberSlot1:
  ds 1

numberSlot2:
  ds 1

numberSlot3:
  ds 1

attempts:
  ds 1

max_attempts:
  ds 1

pad_column_selection:
  ds 1

pad_row_selection:
  ds 1

game_started:
  ds 1

display_attempts:
  ds 2

display_max_attempts:
  ds 2

level_select:
  ds 1

dstruct GuessData, guessData

dstruct CursorData, cursorData

dstruct ArrowData, arrowData
