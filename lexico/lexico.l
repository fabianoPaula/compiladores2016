%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NUM 256
#define STRING 257
#define ID  258
#define WS 262
#define CMD_DIVIDER 263


#define WHILE 301
#define FOR 302
#define IF  303
#define FUNCTION 304
#define RETURN 305

#define CHAR 401
#define INT  402
#define FLOAT 403

%}

D   [0-9]
L   [a-zA-Z_]
ID  {L}+
NUM {D}+("."{D}+)?([Ee][+"-"]?D+)?
WS  [ \n\t]+
OPR [+\-*/(){}]
STR \"([^\n]|\\\")*\"

%%


{WS}  { }

"for"	{return FOR;}
"if"	{return IF;}
"while"	{return WHILE;}
"function"	{return FUNCTION;}
"return"	{return RETURN;}
";" { return CMD_DIVIDER; } 

"int"	{return INT; }
"char"	{return CHAR; }
"float"	{return FLOAT; }

{NUM} { return NUM; }
{OPR} { return yytext[0]; }

{STR}     { return STRING; }
{ID}  { return ID; }
<<EOF>> {return EOF; }
.     { return *yytext; }


%%

int main(){
    int token = yylex();

    while( token != EOF){
        printf("%d:%s \n", token, yytext);
        token = yylex();
    }

    return 0;
}
