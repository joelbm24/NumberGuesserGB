NAME = number_guesser

game : link
	rgbfix -v -p 0xFF bin/$(NAME).gb

link : asm
	rgblink -o bin/$(NAME).gb bin/$(NAME).o

asm :
	mkdir -p bin
	rgbasm -Weverything -o bin/$(NAME).o src/main.asm

clean :
	rm -r bin

run : game
	mgba bin/$(NAME).gb

debug : game
	java -jar ~/Emulicious/Emulicious.jar bin/$(NAME).gb
