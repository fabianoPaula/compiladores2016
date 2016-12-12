%{ 
	string troca_aspas(string nome); 
%}

DELIM   [\t ]
LINHA   [\n]
NUMERO  [0-9]
LETRA   [A-Za-z_]
INT     {NUMERO}+
DOUBLE  {NUMERO}+("."{NUMERO}+)?
ID      {LETRA}({LETRA}|{NUMERO})*
CSTRING "'"([^\n']|"''")*"'"

COMMENT "(*"([^*]|"*"[^)])*"*)"

%%

{LINHA}      { nlinha++; }
{DELIM}      {}
{COMMENT}    {}


"começar"    { yylval = Atributos( yytext ); return TK_COMECAR; }
"com"        { yylval = Atributos( yytext ); return TK_COM; }
"tente"      { yylval = Atributos( yytext ); return TK_TENTE; }

"devolve"          { yylval = Atributos( yytext ); return TK_DEVOLVE; }

",tranquilo?"    { yylval = Atributos( yytext ); return TK_TRANQUILO; }
"favoravel"      { yylval = Atributos( yytext ); return TK_FAVORAVEL; }


"escreveAi" { yylval = Atributos( yytext ); return TK_ESCREVEAI; }
"leIssoAi" { yylval = Atributos( yytext ); return TK_LEISSOAI; }

"variaveis" { yylval = Atributos( yytext); return TK_VARIAVEIS; }

"simounão"         { yylval = Atributos( yytext, "b" ); return TK_TIPO_SIMOUNAO; }
"numero"           { yylval = Atributos( yytext, "i" ); return TK_TIPO_NUMERO; }
"numeroComVirgula" { yylval = Atributos( yytext, "d" ); return TK_TIPO_NUMERO_COM_VIRGULA; }
"letra"            { yylval = Atributos( yytext, "c" ); return TK_TIPO_LETRA; }
"palavra"          { yylval = Atributos( yytext, "s" ); return TK_TIPO_PALAVRA; }

"verdade"          { yylval = Atributos( yytext, "b" ); return TK_MENTIRA; }
"mentira"          { yylval = Atributos( yytext, "b" ); return TK_VERDADE; }

"se"               { yylval = Atributos( yytext); return TK_SE; }
"faz"              { yylval = Atributos( yytext); return TK_FAZ; }
"senao"            { yylval = Atributos( yytext); return TK_ESQUECE; }

"enquanto"		   { yylval = Atributos( yytext); return TK_ENQUANTO; }
"para"		       { yylval = Atributos( yytext); return TK_PARA; }
"vai"		       { yylval = Atributos( yytext); return TK_VAI; }
"ate"		       { yylval = Atributos( yytext); return TK_ATE; }
"faça"		       { yylval = Atributos( yytext); return TK_FACA; }

"e"                { yylval = Atributos( yytext ); return TK_E;  }
"&&"               { yylval = Atributos( yytext ); return TK_E;  }
"ou"               { yylval = Atributos( yytext ); return TK_OU; }
"||"               { yylval = Atributos( yytext ); return TK_OU; }

"=="       { yylval = Atributos( yytext ); return TK_IGUAL; }
"<="       { yylval = Atributos( yytext ); return TK_MEIG;  }
">="       { yylval = Atributos( yytext ); return TK_MAIG;  }
"!="       { yylval = Atributos( yytext ); return TK_DIF;   }
"="        { yylval = Atributos( yytext ); return TK_ATRIB; }

{CSTRING}  { yylval = Atributos( troca_aspas(yytext), "s" ); return TK_CSTRING; }
{ID}       { yylval = Atributos( yytext ); return TK_ID; }
{INT}      { yylval = Atributos( yytext, "i" ); return TK_CINT; }
{DOUBLE}   { yylval = Atributos( yytext, "d" ); return TK_CDOUBLE; }

.          { yylval = Atributos( yytext ); return *yytext; }

%%

string troca_aspas(string var){
	var[0] = '\"';
	var[var.size()-1] = '\"';
	return var;
}

