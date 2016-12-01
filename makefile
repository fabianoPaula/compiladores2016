all: trabalho.out entrada.wpp
	./trabalho.out < entrada.wpp > gerado.cc
	cat gerado.cc
	g++ -std=c++11 -o program.out gerado.cc -lfl
	./program.out

lex.yy.c: trabalho.lex
	lex trabalho.lex

y.tab.c: trabalho.y
	yacc trabalho.y -v

trabalho.out: lex.yy.c y.tab.c
	g++ -std=c++11 -o trabalho.out y.tab.c -lfl
