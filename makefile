all: build/trabalho.out entrada.wpp
	./build/trabalho.out < entrada.wpp > build/gerado.cc
	./gabarito < build/gerado.cc
	g++ -std=c++11 -o ./build/program.out build/gerado.cc -lfl
	./build/program.out

build/lex.yy.c: trabalho.lex
	lex -o ./build/lex.yy.c trabalho.lex 

build/y.tab.c: trabalho.y
	yacc -o ./build/y.tab.c trabalho.y -v

build/trabalho.out: build/lex.yy.c build/y.tab.c
	g++ -std=c++11 -o ./build/trabalho.out ./build/y.tab.c -lfl
