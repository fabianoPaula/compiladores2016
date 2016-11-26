DELIM   [\t ]
LINHA   [\n]
NUMERO  [0-9]
LETRA   [A-Za-z_]
INT     {NUMERO}+
DOUBLE  {NUMERO}+("."{NUMERO}+)?
ID      {LETRA}({LETRA}|{NUMERO})*
CSTRING "'"([^\n']|"''")*"'"

%%

{LINHA}    { nlinha++; }
{DELIM}    {}


// Relativo a blocos
"começar"      { yylval = Atributos( yytext ); return TK_COMECAR; }
"com"      { yylval = Atributos( yytext ); return TK_COM; }
"tente"      { yylval = Atributos( yytext ); return TK_TENTE; }


"e"      { yylval = Atributos( yytext ); return TK_E; }
"mi"      { yylval = Atributos( yytext ); return TK_MI; }
"da"      { yylval = Atributos( yytext ); return TK_DA; }

",tranquilo?"    { yylval = Atributos( yytext ); return TK_TRANQUILO; }
"favoravel"      { yylval = Atributos( yytext ); return TK_FAVORAVEL; }

# Relativo a entrada e saida

"escreveAi" { yylval = Atributos( yytext ); return TK_ESCREVEAI; }
"leIssoAi" { yylval = Atributos( yytext ); return TK_LEISSOAI; }





"="       { yylval = Atributos( yytext ); return TK_ATRIB; }

{CSTRING}  { yylval = Atributos( yytext, "string" ); return TK_CSTRING; }
{ID}       { yylval = Atributos( yytext ); return TK_ID; }
{INT}      { yylval = Atributos( yytext, "int" ); return TK_CINT; }
{DOUBLE}   { yylval = Atributos( yytext, "double" ); return TK_CDOUBLE; }

.          { yylval = Atributos( yytext ); return *yytext; }

%%

 


