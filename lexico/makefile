all: analex entrada.txt
	./analex < entrada.txt

analex: lexico.yy.c
	g++ lexico.yy.c -lfl -o analex

lexico.yy.c: lexico.l
	flex -o lexico.yy.c lexico.l
