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
  
  Atributos() { // Constutor vazio
    v = "";
    t = "";
    c = "";
    var_temp = "";
  } 

  Atributos( string valor ) {
    v = valor;
    t = "";
    c = "";
    var_temp = "";
  }

  Atributos( string valor, string tipo ) {
    v = valor;
    t = tipo;
    c = "";
    var_temp = "";
  }
};


#define MAX_DIM 2
struct TipoGeral{
  string t;
  int ndim;
  int tam[MAX_DIM];

  TipoGeral() {} // Constutor Vazio

  TipoGeral(string tipo) {
    t = tipo;
    ndim = 0;
    tam[0] = -1;
    tam[1] = -1;
  }

  TipoGeral(string tipo, int v1) {
    t = tipo;
    ndim = 1;
    tam[0] = v1;
    tam[1] = -1;
  }

  TipoGeral(string tipo, int v1, int v2) {
    t = tipo;
    ndim = 2;
    tam[0] = v1;
    tam[1] = v2;
  }
};

map< string, string > tipo_opr;

// Dicionário para os tipos da forma intermediária
map< string, string > tipos;

map<string,TipoGeral> tabela_simbolos;

// Declarar todas as funções que serão usadas.

// Funções que mexem na tabela_simbolos
TipoGeral consulta_ts( string nome_var );
void inserir_ts( string nome_var, TipoGeral tipo);

Atributos cria_variavel(string tipo, vector<string> lista, int dim, int s1, int s2);


string gera_nome_var_temp( string tipo );
Atributos gera_codigo_opr(Atributos s1, string opr, Atributos s2);
Atributos gera_codigo_teste_vetor(string nome_var, Atributos s1,Atributos s2);


// Funções auxiliares
string toString(int n);
int    toInt(string valor);
void   debug( string producao, Atributos atr );
void   error(string);


string includes = 
"#include <iostream>\n"
"#include <stdio.h>\n"
"#include <stdlib.h>\n"
"#include <string.h>\n"
"#include <string>\n"
"#include <cstring>\n"
"\n"
"using namespace std;\n";


#define YYSTYPE Atributos

%}

// Token de blocos
%token TK_TRANQUILO TK_FAVORAVEL TK_COMECAR TK_DEVOLVE

// Lista de parâmetros
%token TK_COM TK_TENTE 

// Varíáveis
%token TK_VARIAVEIS TK_TIPO_NUMERO TK_TIPO_NUMERO_COM_VIRGULA TK_TIPO_LETRA TK_TIPO_PALAVRA TK_TIPO_SIMOUNAO

// Entrada e Saida
%token TK_ESCREVEAI TK_LEISSOAI



// Tipos de valores
%token TK_ID TK_CINT TK_CDOUBLE TK_ATRIB TK_CSTRING
%token TK_VERDADE TK_MENTIRA

// Parte dos operadores
%token TK_MAIG TK_MEIG TK_DIF TK_E TK_OU TK_IGUAL

%left TK_E TK_OU
%nonassoc '<' '>' TK_MAIG TK_MEIG TK_IGUAL TK_DIF 
%left '+' '-'
%left '*' '/'

%%

/* Escopo Principal */
S : DECLS COMECA
    {
      cout << includes << endl;
      cout << $1.c << endl;
      cout << $2.c << endl;
    }
  ;

/* Declaração de variáveis e funções */
    
DECLS : BLOCO_VARS DECLS { $$.c = $1.c + $2.c;  }
      | { $$.c = ""; }
      ;  

BLOCO_VARS : TK_VARIAVEIS VARS { $$.c = $2.c; }
           ;


VARS : VAR ';' VARS { $$.c = $1.c + $3.c; }
     | { $$.c = ""; }
     ;     
     
VAR : TIPO_VAR IDS                 { $$ = cria_variavel($1.t, $2.lista, 0, -1,-1); }
    | TIPO_VAR '[' TK_CINT ']' IDS { $$ = cria_variavel($1.t, $5.lista, 1, toInt($3.v),-1); }
    ;

TIPO_VAR : TK_TIPO_NUMERO             { $$ = $1; }
         | TK_TIPO_NUMERO_COM_VIRGULA { $$ = $1; }
         | TK_TIPO_LETRA              { $$ = $1; }
         | TK_TIPO_PALAVRA            { $$ = $1; }
         | TK_TIPO_SIMOUNAO           { $$ = $1; }
         ;

    
IDS : TK_ID ',' IDS { $3.lista.push_back($1.v); $$ = $3; }
    | TK_ID         { $1.lista.push_back($1.v); $$ = $1; }
    ; 

// Declaração  do método Principal

COMECA : PARAMS TK_COMECAR TK_DEVOLVE TIPO_VAR BLOCO_VARS BLOCO_COMECA {  $$.c = $5.c +"int main()" + $6.c + "l_exit:;\n  return 0;\n}"; }
       | PARAMS TK_COMECAR TK_DEVOLVE TIPO_VAR BLOCO_COMECA { $$.c = "int main(){ \n" + $5.c + "l_exit:;\n  return 0;\n}" ; }  
       ;

PARAMS: TK_COM TK_TENTE
      | TK_TENTE
      ;
     
BLOCO_COMECA : TK_TRANQUILO CMDS TK_FAVORAVEL { $$.c = $2.var_temp + $2.c; }
             ;  

BLOCO : TK_TRANQUILO CMDS TK_FAVORAVEL { $$.c = "{\n"+ $2.var_temp + $2.c + "\n}"; }
      ;
      
CMDS : CMD ';' CMDS
       { $$.c = $1.c + $3.c; 
         $$.var_temp = $1.var_temp + $3.var_temp; }
     | { $$.c = ""; $$.var_temp = ""; }
     ;  
     
CMD : WRITELN
    | READLN
    | ATRIB 
    | BLOCO
//    | CMD_IF
//    | CMD_FOR
    ;     

READLN : TK_LEISSOAI '(' E ',' NOME_VAR ')'
          {  
            $$.c = $3.c + "  cout << " + $3.v + ";\n  cout << endl;\n"
                        + "  cin  >> " + $5.v + ";\n";
            $$.var_temp = $3.var_temp;
          }
        ;

WRITELN : TK_ESCREVEAI '(' E ')'
          {  
            $$.c = $3.c + "  cout << " + $3.v + ";\n  cout << endl;\n";
            $$.var_temp = $3.var_temp;
          }
        ;
  
ATRIB : F TK_ATRIB E 
        { 
          if( $1.t.compare($3.t) != 0){
            error("Atribuição com tipos errados errados! "+ $1.t +" <- "+ $3.t);
          }

          $$.c = $1.c + $3.c+ "  " + $1.v + " = " + $3.v + ";\n"; 
          $$.var_temp = $1.var_temp + $3.var_temp;
        } 
      ;   

E : E '+' E      { $$ = gera_codigo_opr( $1, "+" , $3 ); }
  | E '-' E      { $$ = gera_codigo_opr( $1, "-" , $3 ); }
  | E '*' E      { $$ = gera_codigo_opr( $1, "*" , $3 ); }
  | E '/' E      { $$ = gera_codigo_opr( $1, "/" , $3 ); }
  | E '%' E      { $$ = gera_codigo_opr( $1, "%" , $3 ); }
  | E '<' E      { $$ = gera_codigo_opr( $1, "<" , $3 ); }
  | E '>' E      { $$ = gera_codigo_opr( $1, ">" , $3 ); }
  | E TK_MEIG E  { $$ = gera_codigo_opr( $1, "<=", $3 ); }
  | E TK_MAIG E  { $$ = gera_codigo_opr( $1, ">=", $3 ); }
  | E TK_IGUAL E { $$ = gera_codigo_opr( $1, "==", $3 ); }
  | E TK_DIF E   { $$ = gera_codigo_opr( $1, "!=", $3 ); }
  | E TK_E E     { $$ = gera_codigo_opr( $1, "&&" , $3 ); }
  | E TK_OU E    { $$ = gera_codigo_opr( $1, "||", $3 ); }
  | '(' E ')'    { $$ = $2; }
  | F            { $$ = $1; }
  ;
  
F : NOME_VAR           { $$ = $1; }
  | NOME_VAR '[' E ']' { $$ = gera_codigo_teste_vetor($1.v,$1,$3); }
  | TK_CINT    { $$.v = $1.v; $$.t = "i"; $$.c = $1.c; }
  | TK_CDOUBLE { $$.v = $1.v; $$.t = "d"; $$.c = $1.c; }
  | TK_CSTRING { $$.v = $1.v; $$.t = "s"; $$.c = $1.c; }
  | TK_VERDADE { $$.v = $1.v; $$.t = "b"; $$.c = $1.c; }
  | TK_MENTIRA { $$.v = $1.v; $$.t = "b"; $$.c = $1.c; }
  ;

NOME_VAR : TK_ID { $$.v = $1.v; $$.t = consulta_ts( $1.v ).t; $$.c = $1.c; }
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
  cerr << "  temp: " << atr.var_temp << endl;
}

void yyerror( const char* st )
{
  printf( "Linha: %d, [%s]: %s\n", nlinha, yytext,st);
  exit(0);
}

void error( string st )
{
  cout << "Linha: " << nlinha << ", [" << yytext << "]: "<< st << "\n";
  exit(0);
}


void preload() {
  // Resultados para o operador "+"
  tipo_opr["i+i"] = "i";
  tipo_opr["i+d"] = "d";
  tipo_opr["d+i"] = "d";
  tipo_opr["d+d"] = "d";
  tipo_opr["s+s"] = "s";
  tipo_opr["c+s"] = "s";
  tipo_opr["s+c"] = "s";
  tipo_opr["c+c"] = "s";
 
 // Resultados para o operador "-"
  tipo_opr["i-i"] = "i";
  tipo_opr["i-d"] = "d";
  tipo_opr["d-i"] = "d";
  tipo_opr["d-d"] = "d";
  
  // Resultados para o operador "*"
  tipo_opr["i*i"] = "i";
  tipo_opr["i*d"] = "d";
  tipo_opr["d*i"] = "d";
  tipo_opr["d*d"] = "d";
  
  // Resultados para o operador "/"
  tipo_opr["i/i"] = "d";
  tipo_opr["i/d"] = "d";
  tipo_opr["d/i"] = "d";
  tipo_opr["d/d"] = "d";

  // Resultados para o operador "%"
  tipo_opr["i%i"] = "i";
  
  // Resultados para o operador "<"
  tipo_opr["i<i"] = "b";
  tipo_opr["i<d"] = "b";
  tipo_opr["d<i"] = "b";
  tipo_opr["d<d"] = "b";
  tipo_opr["c<c"] = "b";
  tipo_opr["i<c"] = "b";
  tipo_opr["c<i"] = "b";

  // Resultados para o operador ">"
  tipo_opr["i>i"] = "b";
  tipo_opr["i>d"] = "b";
  tipo_opr["d>i"] = "b";
  tipo_opr["d>d"] = "b";
  tipo_opr["c>c"] = "b";
  tipo_opr["i>c"] = "b";
  tipo_opr["c>i"] = "b";

    // Resultados para o operador "<="
  tipo_opr["i<=i"] = "b";
  tipo_opr["i<=d"] = "b";
  tipo_opr["d<=i"] = "b";
  tipo_opr["d<=d"] = "b";
  tipo_opr["c<=c"] = "b";
  tipo_opr["i<=c"] = "b";
  tipo_opr["c<=i"] = "b";

  // Resultados para o operador ">="
  tipo_opr["i>=i"] = "b";
  tipo_opr["i>=d"] = "b";
  tipo_opr["d>=i"] = "b";
  tipo_opr["d>=d"] = "b";
  tipo_opr["c>=c"] = "b";
  tipo_opr["i>=c"] = "b";
  tipo_opr["c>=i"] = "b";

  // Resultados para o operador "!="
  tipo_opr["i!=i"] = "b";
  tipo_opr["i!=d"] = "b";
  tipo_opr["d!=i"] = "b";
  tipo_opr["d!=d"] = "b";
  tipo_opr["c!=c"] = "b";
  tipo_opr["i!=c"] = "b";
  tipo_opr["c!=i"] = "b";

  // Resultados para o operador "&&"
  tipo_opr["b&&b"] = "b";

  // Resultados para o operador "||"
  tipo_opr["b||b"] = "b";

  tipos["i"] = "int";
  tipos["d"] = "double";
  tipos["c"] = "char";
  tipos["s"] = "string";
  tipos["b"] = "int";
}

int existe_ts(string nome_var){
  return (tabela_simbolos.find(nome_var) != tabela_simbolos.end());
}

TipoGeral consulta_ts( string nome_var ) {
  if(!existe_ts(nome_var)){
    error("A variável "+nome_var+" não foi declarada no escopo do programa");
  }

//  for(map<string, TipoGeral >::const_iterator it = tabela_simbolos.begin();
//    it != tabela_simbolos.end(); ++it)
//  {
//    std::cout << it->first << ":" << it->second.t << "\n";
//  }

  return tabela_simbolos[nome_var];
}

void inserir_ts( string nome_var , TipoGeral tipo) {
  tabela_simbolos[nome_var] = tipo;
}

string gera_nome_var_temp( string tipo ) {
  static int n = 0;
  string nome = "t" + tipo + "_" + toString( ++n );
  return nome; 
}

string gera_label( string tipo ) {
  static int n = 0;
  string nome = "l_" + tipo + "_" + toString( ++n );
  return nome;
}

Atributos cria_variavel(string tipo, vector<string> lista, int dim, int s1, int s2){
  Atributos result = Atributos();
  vector<string>::iterator it;
  for( it = lista.begin(); it != lista.end(); it++){
    
    if(existe_ts(*it)){
      error("A variável já foi declarada no programa!");
    }

    if( dim == 0){
     result.c = result.c + tipos[tipo] + " " + *it  + ";\n";
     inserir_ts(*it,TipoGeral(tipo));
    }else if( dim == 1){
     result.c = result.c + tipos[tipo] + " " + *it + "["+toString(s1)+"]" + ";\n";
     inserir_ts(*it,TipoGeral(tipo,s1));
    }else if( dim == 2){
      result.c = result.c + tipos[tipo] + " " + *it + "["+toString(s1)+"]" + "["+toString(s2)+"]" + ";\n";
      inserir_ts(*it,TipoGeral(tipo, s1,s2));
    }
  }
  return result;
}

string gera_saida_dados(string saida){
    return "cout << " + saida + " << endl;";
}

Atributos gera_codigo_opr(Atributos s1, string opr, Atributos s2){
  Atributos result;
  string typeOfOpr =  s1.t + opr + s2.t;
  result.t = tipo_opr[typeOfOpr]; 
  result.v = gera_nome_var_temp(result.t);
  result.var_temp = s1.var_temp + s2.var_temp + "  " + tipos[result.t] + " " + result.v + ";\n";

  if( typeOfOpr.compare("s+s") != 0){
    result.c = s1.c + s2.c + "  " + result.v + " = " + s1.v + opr + s2.v + ";\n";
  }else{
    result.c = s1.c + s2.c + "  " + result.v + " = " + s1.v + opr + s2.v + ";\n";    
  }
  
  return result;
}

Atributos gera_codigo_teste_vetor(string nome_var, Atributos s1,Atributos s2) {
  Atributos ss;
  TipoGeral aux = consulta_ts(nome_var);

  string label_else = gera_label( "acessa_vetor" );
  string label_end = gera_label( "saida" );
  
  ss.c = s2.c + 
         // "  " + s2.v + " = !" + s2.v + ";\n\n" +
         "  if( " + s2.v + " >= "+ toString(aux.tam[0]) +") goto " + label_else + ";\n" +
         "  goto "+label_end+"; \n" + 
         label_else + ":;\n" +
         "  cout << \"Excedeu tamanho do vetor! \";\n" +
         "  cout << \"" + nome_var + "[\";\n"+
         "  cout << " +  s2.v + ";\n" + 
         "  cout << \"]\\n\";\n"+
         "  goto l_exit;\n" +
         label_end + ":;\n"; 

  ss.v = s1.v + '[' + s2.v + ']';
  ss.t = s1.t; 
  ss.var_temp = s2.var_temp; 
         
  return ss;       
}

string toString(int n){
  char buff[100];
  sprintf(buff,"%d",n);
  return buff;
}

int toInt(string valor){
  int aux = -1;
  if( sscanf(valor.c_str(), "%d", &aux) != 1 )
    error("Número Inválido: " + valor);
  return aux;
}

int main( int argc, char* argv[] )
{
  preload();
  yyparse();
}
