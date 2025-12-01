; vim: ft=gbasm

INCLUDE "src/lib/structs.inc"
	rgbds_structs_version 4.1.0

struct CursorSprite
  bytes 1, YPos
  bytes 1, XPos
	bytes 1, Tile
	bytes 1, Attr
end_struct

struct ArrowSprite
  bytes 1, YPos
  bytes 1, XPos
	bytes 1, Tile
	bytes 1, Attr
end_struct

struct ArrowData
  bytes 1, YPos
  bytes 1, XPos
end_struct

struct CursorData
  bytes 1, YPos
  bytes 1, XPos
  bytes 1, YMin
  bytes 1, XMin
end_struct

struct GuessData
  bytes 1, Num1
  bytes 1, Num2
  bytes 1, Num3
  bytes 1, Length
  bytes 1, Value
end_struct
