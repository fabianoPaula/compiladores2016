%{
#include <string>
#include <iostream>
#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include <map>

using namespace std;

int yylex();
void yyerror( const char* st );




struct Atributos {
  string v, t, c; // Valor, tipo e código gerado.
  vector<string> lista; // Uma lista auxiliar.

  string var_temp; // Variaveis temporárias criadas
  
  Atributos() {} // Constutor vazio
  Atributos( string valor ) {
    v = valor;
  }

  Atributos( string valor, string tipo ) {
    v = valor;
    t = tipo;
  }
};


struct Variaveis{
  string t, contexto;

  Variaveis() {}
  Variaveis(string tipo) {
    t = tipo;
  }

  Variaveis(string tipo, string contextVar) {
    t = tipo;
    contexto = contextVar;
  }

};

map< string, string > tipo_opr;
map< string, string > tipo_tipo_c;


map<string,Variaveis> tabela_simbolos;

// Declarar todas as funções que serão usadas.
string consulta_ts( string nome_var );
string gera_nome_var_temp( string tipo );
void gera_expressao_opr(Atributos* result, Atributos s1, Atributos s2, string opr);


void debug( string producao, Atributos atr );


string includes = 
"#include <iostream>\n"
"#include <stdio.h>\n"
"#include <stdlib.h>\n"
"#include <string.h>\n"
"\n"
"using namespace std;\n";


#define YYSTYPE Atributos

%}

// Token de blocos
%token TK_TRANQUILO TK_FAVORAVEL TK_COMECAR TK_MI TK_E TK_DA

// Lista de parâmetros
%token TK_COM TK_TENTE

// Entrada e Saida
%token TK_ESCREVEAI TK_LEISSOAI

%token TK_ID TK_CINT TK_CDOUBLE TK_VAR  TK_ATRIB
%token TK_WRITELN TK_CSTRING


%left '+' '-'
%left '*' '/'

%%

S : DECLS COMECA
    {
      cout << includes << endl;
      cout << $1.c << endl;
      cout << $2.c << endl;
    }
  ;
    
DECLS : VARS DECLS { $$.c = $1.c + "\n" + $2.c; }
      | 
      ;  

// DECL : VARS ;

VARS : VAR ';' VARS { $$.c = $1.c + "\n" + $2.c;}

     | 
     ;     
     
VAR : TK_ID IDS 
        {  
           $$.c = tipo_tipo_c[tipo_tipo_c[$1.v]] + " " + $2.c;
           vector<string>::iterator it;
           for( it = $2.lista.begin(); it != $2.lista.end(); it++)
              tabela_simbolos[*it] = Variaveis(tipo_tipo_c[$1.v], "");
        }
    ;
    
IDS : TK_ID ',' IDS {  $$.c = $1.v + ',' + $3.c;
                       $$.lista.push_back($1.v); }
    | TK_ID { $$.c = $1.v + ";"; 
              $$.lista.push_back($1.v); }
    ;          

COMECA : PARAMS TK_COMECAR TK_E TK_MI TK_DA TK_ID BLOCO
       {  
          $$.c = "\n\nint main()\n" + $7.c;        
       } 
       ;

PARAMS: TK_COM VARS TK_TENTE
      | TK_TENTE
      ;
     
BLOCO : TK_TRANQUILO CMDS TK_FAVORAVEL
        { $$.c = "{\n" + $2.var_temp + $2.c + "\n}\n";      
        }
      ;  
      
CMDS : CMD CMDS
       { $$.c = $1.c + $2.c; 
         $$.var_temp = $1.var_temp + $2.var_temp; }
     |
     ;  
     
CMD : WRITELN
    | ATRIB 
    ;     

WRITELN : TK_ESCREVEAI '(' E ')' ';'
          {  
            $$.c = $3.c + "  cout << " + $3.v + " << endl;";
            $$.var_temp = $3.var_temp;
            //debug("WRITELN : TK_ESCREVEAI ( E )", $$);
          }
        ;
  
ATRIB : TK_ID TK_ATRIB E ';'
        { $$.c = $3.c + "  " + $1.v + " = " + $3.v + ";\n"; 
          $$.var_temp = $3.var_temp;
          //debug( "ATRIB : TK_ID TK_ATRIB E ';'", $$ );
        } 
      ;   

E : E '+' E
    { 
      gera_expressao_opr(&$$,$1,$3,"+");
      //debug( "E: E '+' E", $$ );
    }
  | E '-' E
    { 
      gera_expressao_opr(&$$,$1,$3,"-");
      //debug( "E: E '-' E", $$ );
    }
  | E '*' E
    { 
      gera_expressao_opr(&$$,$1,$3,"*");
      //debug( "E: E '*' E", $$ );
    }
  | E '/' E
    { 
      gera_expressao_opr(&$$,$1,$3,"/");
      //debug( "E: E '/' E", $$ );
    }
  | '(' E ')'

  | F {
      $$.t = $1.t;
      $$.v = $1.v;
      //debug("E : F", $$);
  }
  ;
  
F : TK_ID 
    // Aind precisa completar com a tabela de símbolos
    { $$.v = $1.v; $$.t = consulta_ts( $1.v ); $$.c = $1.c; }
  | TK_CINT 
    { $$.v = $1.v; $$.t = "i"; $$.c = $1.c; 
     // debug("F: TK_ID",$$);
    }
  | TK_CDOUBLE
    { $$.v = $1.v; $$.t = "d"; $$.c = $1.c; };
  | TK_CSTRING
    { $$.v = $1.v; $$.t = "s"; $$.c = $1.c; };
  ;
  
%%
int nlinha = 1;

#include "lex.yy.c"

int yyparse();

void debug( string producao, Atributos atr ) {
  cerr << "Debug: " << producao << endl;
  cerr << "  t: " << atr.t << endl;
  cerr << "  v: " << atr.v << endl;
  cerr << "  c: " << atr.c << endl;
}

void yyerror( const char* st )
{
  puts( st );
  printf( "Linha: %d, [%s]\n", nlinha, yytext );
  debug("",yylval);
}

void inicializa_operadores() {
  // Resultados para o operador "+"
  tipo_opr["i+i"] = "i";
  tipo_opr["i+d"] = "d";
  tipo_opr["d+i"] = "d";
  tipo_opr["d+d"] = "d";
  tipo_opr["s+s"] = "s";
  tipo_opr["c+s"] = "s";
  tipo_opr["s+c"] = "s";
  tipo_opr["c+c"] = "s";
 
  // Resultados para o operador "*"
  tipo_opr["i*i"] = "i";
  tipo_opr["i*d"] = "d";
  tipo_opr["d*i"] = "d";
  tipo_opr["d*d"] = "d";

  // Tipos da linguagem para os tipos internos do compilador
  tipo_tipo_c["numero"] = "i";
  tipo_tipo_c["numeroComVirgula"] = "d";
  tipo_tipo_c["letra"] = "c";
  tipo_tipo_c["palavra"] = "s";

  // Tipos internos do compilador para os tipos do C
  tipo_tipo_c["i"] = "int";
  tipo_tipo_c["d"] = "double";
  tipo_tipo_c["c"] = "char";
  tipo_tipo_c["s"] = "string";



  
}

string consulta_ts( string nome_var ) {
  // fake. Deveria ser ts[nome_var], onde ts é um map.
  // Antes de retornar, tem que verificar se a variável existe.
  return "i";
}

string gera_nome_var_temp( string tipo ) {
  static int n = 0;
  char buff[100];
  
  sprintf( buff, "_%d", ++n ); 

  return "t" + tipo + buff; 
}

string gera_saida_dados(string saida){
    return "cout << " + saida + " << endl;";
}

void gera_expressao_opr(Atributos* result, Atributos s1, Atributos s2, string opr){
      result->t = tipo_opr[ s1.t + opr + s2.t ]; 
      result->v = gera_nome_var_temp(result->t);

      result->var_temp = s1.var_temp + s2.var_temp + 
        tipo_tipo_c[result->t] + " " + result->v + ";\n";
      // Codigo das expressões dos filhos da arvore.
      result->c = s1.c + s2.c + "  " + 
                 result->v + " = " + 
                 s1.v + opr + s2.v + ";\n";       
}

int main( int argc, char* argv[] )
{
  inicializa_operadores();
  yyparse();
}
