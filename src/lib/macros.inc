; vim: ft=gbasm

macro ReadPad
    VariableSet rP1, %00100000
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]

    and $0F
    swap a
    ld b, a

    VariableSet rP1, %00010000
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]

    and $0F
    or b

    cpl
    ld [_PAD], a
  endm

macro DrawNumber ; TO_AREA, TILES_START, AMOUNT
  ld hl, \1
  FOR N, \3-1, 0, -1
    ld a, [\2+{d:N}]
    add '0'
    ld [hli], a
  ENDR
    ld a, [\2]
    add '0'
ld [hl], a
endm

macro PadPressed
  ld a, 1
  ld [_PAD_PRESSED], a
endm


macro VariableAdd ; VARIABLE, VALUE
  ld a, [\1]
  add a, \2
  ld [\1], a
endm

macro VariableSub ; VARIABLE, VALUE
  ld a, [\1]
  sub a, \2
  ld [\1], a
endm

macro VariableDec ; VARIABLE
  ld a, [\1]
  dec a
  ld [\1], a
endm

macro VariableInc ; VARIABLE
  ld a, [\1]
  inc a
  ld [\1], a
endm

macro VariableSet ; VARIABLE, VALUE
  ld a, \2
  ld [\1], a
endm

macro SetVariableBit ; VARIABLE BIT
  ld a, [\1]
  set \2, a
  ld [\1], a
endm

macro CopyConstToVar ; TO, FROM
  ld a, \2
  ld [\1], a
endm

macro CopyVars ; TO, FROM
  ld a, [\2]
  ld [\1], a
endm

macro CompareVars ; Var1, Var2
  ld a, [\2]
  ld b, a
  ld a, [\1]
  cp a, b
endm

macro CordToOffset ; X, Y
  _SCRN0 + \1 + (\2 * 32)
endm

macro GetDisplayNumber ; Number, DisplayAddr, Length
  IF \3 <= 2
    xor a
    ld h, a
  ELSE
    ld a, [\1 + 1]
    ld h, a
  ENDC
  ld a, [\1]
  ld l, a

  ld de, \2
  call getDisplayNumber
endm

macro DisplayAttempts
  GetDisplayNumber attempts, display_attempts, 2
  DrawNumber BEGIN_ATTEMPTS, display_attempts, 2
endm
