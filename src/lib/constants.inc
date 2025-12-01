; vim: ft=gbasm

def NUMPAD_MENU_Y_MIN equ (13*8) + 16
def NUMPAD_MENU_X_MIN equ (8*8) + 8
def NUMPAD_MENU_Y_MAX equ (16*8) + 16
def NUMPAD_MENU_X_MAX equ (12*8) + 8
def NUMPAD_ORIGIN_X equ (10*8) + 8
def NUMPAD_ORIGIN_Y equ (14*8) + 16

def LEVEL_Y_MIN equ (13*8) + 16
def LEVEL_Y_MAX equ (16*8) + 16
def LEVEL_X_MAX equ (1*8) + 8

def BEGIN_GUESS equ _SCRN0 + 7 + (11 * 32)
def BEGIN_HINT equ _SCRN0 + 6 + (6 * 32)
def HINT_TOO_LOW_LEN equ 7
def HINT_TOO_HIGH_LEN equ 8
def HINT_YOU_WIN_LEN equ 8
def PRESS_START_LEN equ 12
def BEGIN_PRESS_START equ _SCRN0 + 4 + (7 * 32)
def BEGIN_ATTEMPTS equ _SCRN0 + 10 + (1 * 32)
def BEGIN_MAX_ATTEMPTS equ _SCRN0 + 13 + (1 * 32)
