all: trabalho.out entrada.cc
	./trabalho.out < entrada.cc 
#   > gerado.cc
#	./gabarito < gerado.cc

lex.yy.c: trabalho.lex
	lex trabalho.lex

y.tab.c: trabalho.y
	yacc trabalho.y

trabalho: lex.yy.c y.tab.c
	g++ -std=c++11 -o trabalho.out y.tab.c -lfl
