; vim: ft=gbasm

guess:
.init:
  xor a
  ld [guessData_Num1], a
  ld [guessData_Num2], a
  ld [guessData_Num3], a
  ld [guessData_Length], a
  ld [guessData_Value], a
  ret

addNumberToGuess: ; Takes the value in the A register
  ld b, a
  ld a, [guessData_Length]
  cp a, 2
  jr z, .exit
  cp a, 1
  jr z, .checkNum2

  ld a, b
  ld [guessData_Num1], a
  ld [guessData_Value], a
  ld a, [guessData_Length]
  inc a
  ld [guessData_Length], a
  ret

.checkNum2:
  cp a, 2
  jr z, .checkNum3

  ld a, b
  ld [guessData_Num2], a
  ld a, [guessData_Length]
  inc a
  ld [guessData_Length], a

  ld a, [guessData_Num1]
  call mulBy10
  ld b, a
  ld a, [guessData_Num2]
  add b
  ld [guessData_Value], a
  ret

.checkNum3:
  ret

.exit:
  ret

removeNumberFromGuess:
  ld a, [guessData_Length]
  cp 2
  jr z, .handle2
  xor a
  ld [guessData_Length], a
  ld [guessData_Num1], a
  ld [guessData_Value], a
  ret

.handle2:
  dec a
  ld [guessData_Length], a
  ld a, [guessData_Num1]
  ld [guessData_Value], a
  xor a
  ld [guessData_Num2], a
  ret


drawGuess:
  ld a, [guessData_Length]
  cp 1
  jr z, .clear1
  ld a, [guessData_Length]
  cp 0
  jr z, .clear
.continue:
  ld a, [guessData_Num1]
  add '0'
  ld [BEGIN_GUESS], a
  ld a, [guessData_Length]
  cp 1
  ld a, '<C>'
  ld [BEGIN_GUESS+1], a
  jr z, .exit
  ld a, [guessData_Num2]
  add '0'
  ld [BEGIN_GUESS+1], a
  ld a, '<C>'
  ld [BEGIN_GUESS+2], a
  jr .exit
.clear1:
  ld a, '<C>'
  ld [BEGIN_GUESS+1], a
  xor a
  ld [BEGIN_GUESS+2], a
  jr .continue
.clear:
  xor a
  ld [BEGIN_GUESS+1], a
  ld [BEGIN_GUESS+2], a
  ld a, '<C>'
  ld [BEGIN_GUESS], a
.exit:
  ret
