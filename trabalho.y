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

enum TIPO { FUNCAO = -1, BASICO = 0, VETOR = 1, MATRIZ = 2 };

#define MAX_DIM 2
struct TipoGeral{
  string tipo_base;
  TIPO ndim;
  int tam[MAX_DIM];

  vector<TipoGeral> retorno; // usando vector por dois motivos:
  // 1) Para não usar ponteiros
  // 2) Para ser genérico. Algumas linguagens permitem mais de um valor
  //    de retorno.
  vector<TipoGeral> params;

  TipoGeral() {
    this->tipo_base = "";
    this->ndim = BASICO;
    this->tam[0] = -1;
    this->tam[1] = -1;
  } 

  TipoGeral(string tipo) {
    this->tipo_base = tipo;
    this->ndim = BASICO;
    this->tam[0] = (tipo.compare("s") == 0) ? 1 : -1;
    this->tam[1] = -1;
  }

  TipoGeral(string tipo, int v1) {
    this->tipo_base = tipo;
    this->ndim = VETOR;
    this->tam[0] = v1;
    this->tam[1] = -1;
  }

  TipoGeral(string tipo, int v1, int v2) {
    this->tipo_base = tipo;
    this->ndim = MATRIZ;
    this->tam[0] = v1;
    this->tam[1] = v2;
  }

  TipoGeral(TipoGeral retorno, vector<TipoGeral> params){
    this->ndim = FUNCAO;
    this->retorno.push_back( retorno );
    this->params = params;
    this->tipo_base = retorno.tipo_base;
    this->ndim = retorno.ndim;
    this->tam[0] = (retorno.tipo_base.compare("s") == 0) ? 1 : -1;
    this->tam[1] = -1;
  }

};

struct Atributos {
  string v, c; // Valor, tipo e código gerado.
  TipoGeral t;
  vector<string> lista_str; // Uma lista auxiliar para os nomes das variaveis.
  vector<TipoGeral>   lista_tipo; // Uma lista auxiliar para os nomes das variaveis.

  vector<Atributos> parametros; // Um vetor auxiliar para ajudar no tratamento de chamadas de funções

  string var_temp; // Variaveis temporárias criadas
  
  Atributos() { // Constutor vazio
    this->v = "";
    this->t = TipoGeral();
    this->c = "";
    this->var_temp = "";
  } 

  Atributos( string valor ) {
    this->v = valor;
    this->t = TipoGeral();
    this->c = "";
    this->var_temp = "";
  }

  Atributos( string valor, TipoGeral tipo ) {
    this->v = valor;
    this->t = tipo;
    this->c = "";
    this->var_temp = "";
  }

  Atributos( string valor, TipoGeral tipo, string codigo ) {
    this->v = valor;
    this->t = tipo;
    this->c = codigo;
    this->var_temp = "";
  }

  Atributos( string valor, TipoGeral tipo, string codigo, string var_temp) {
    this->v = valor;
    this->t = tipo;
    this->c = codigo;
    this->var_temp = var_temp;
  }
};


struct EstruturaSwitch{
  string v_exp;
  string label_exit;
};


// Variávei axiliares aos comando switch
EstruturaSwitch auxSwitch;
int label_swicth_flag = 0;

map< string, string > tipo_opr;

// Dicionário para os tipos da forma intermediária
map< string, string > tipos;

vector< map<string,TipoGeral> > tabela_simbolos;

// Declarar todas as funções que serão usadas.

// Funções que mexem na tabela_simbolos
TipoGeral consulta_ts( string nome_var );
void inserir_var_ts( string nome_var, TipoGeral tipo);
void inserir_funcao_ts( string nome_var, TipoGeral tipo);

void empilha_ts();
void desempilha_ts();

string declara_variavel( string nome, TipoGeral tipo );
Atributos cria_variavel(vector<string> lista, TipoGeral tipo);

string declara_funcao(string nome, TipoGeral tipo,vector<string> nomes, vector<TipoGeral> tipos );

// Código que geram novos símbolos, nomes para a forma intermediária
string gera_nome_var_temp( string tipo );
string gera_label(string tipo);

int testa_tipoVariavel(TipoGeral t1, TipoGeral t2);

// Função auxilixar para o comando fechamento_switch
string last_label_swicth();

// Funções que geram código para a forma intermediária
Atributos gera_codigo_opr(Atributos s1, string opr, Atributos s2);
Atributos gera_codigo_teste_vetor(Atributos s1,Atributos s2);
Atributos gera_codigo_teste_matrix(Atributos s1,Atributos s2,Atributos s3);
Atributos gera_codigo_if( Atributos expr, string cmd_then, string cmd_else );
Atributos gera_codigo_atrib(Atributos esquerda, Atributos direita);
Atributos gera_codigo_writeln(Atributos expr);
Atributos gera_codigo_write(Atributos expr);
Atributos gera_codigo_to_fora(Atributos expr);
Atributos gera_codigo_readln(Atributos expr, Atributos variavel_leitura);



// Funções auxiliares
string toString(int n);
int    toInt(string valor);
void   debug( string producao, Atributos atr );
void   error(string);

string clean_vars(string str);


string decls = 
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
%token TK_TRANQUILO TK_FAVORAVEL TK_DEVOLVE TK_INICIAR TK_FUNCAO

// Lista de parâmetros
%token TK_COM TK_TENTE 

// Varíáveis
%token TK_VARIAVEIS TK_TIPO_NUMERO TK_TIPO_NUMERO_COM_VIRGULA TK_TIPO_LETRA TK_TIPO_PALAVRA TK_TIPO_SIMOUNAO

// Entrada e Saida
%token TK_ESCREVEAI TK_LEISSOAI TK_ESCREVEAISEMPULARLINHA

// Comando de selecão
%token TK_SE TK_FAZ TK_SENAO TK_TOFORA 

// Comando de Repetição

// for, while, do_while
%token TK_ENQUANTO TK_VAI TK_ATE TK_FACA

// Comando de escolha
%token TK_CASO TK_ESCOLHE TK_ENTRE TK_VLW TK_PADRAO 

// Comando Break
%token TK_BELEZA 

// Comando return
%token TK_RETORNA

// Tipos de valores
%token TK_ID TK_CINT TK_CDOUBLE TK_ATRIB TK_CSTRING
%token TK_VERDADE TK_MENTIRA

// Parte dos operadores
%token TK_MAIG TK_MEIG TK_DIF TK_E TK_OU TK_IGUAL TK_PERTENCE

%left TK_E TK_OU
%nonassoc '<' '>' TK_MAIG TK_MEIG TK_IGUAL TK_DIF  TK_PERTENCE
%left '+' '-' 
%left '*' '/' '%'

%%

/* Escopo Principal */
S : {empilha_ts(); } DECLS MAIN
    {

      cout << decls << endl;
      cout << $2.c << endl;
      cout << $3.c << endl;     
    }
  ;

/* Declaração de variáveis e funções */
    
DECLS : DECL DECLS { $$.c = $1.c + $2.c;  }
      | { $$.c = ""; }
      ;  

DECL : BLOCO_VARS
     | FUNCTION
     ;

FUNCTION : { empilha_ts(); } TK_FUNCAO CABECALHO CORPO { desempilha_ts(); }';' {  $$.c = "\n" + $3.c + "{\n" + $4.c + "}\n\n"; }
         ;

CABECALHO : OPC_PARAMS TK_ID TK_DEVOLVE TIPO_VAR { $$.c = declara_funcao($2.v, TipoGeral($4.t), $1.lista_str, $1.lista_tipo ); }
          ;

OPC_PARAMS: TK_COM '(' PARAMS ')' TK_TENTE { $$ = $3; }
          | TK_TENTE { $$ = Atributos();}
          ;             

PARAMS : PARAM ';' PARAMS 
         { 
            $$.c = $1.c + $3.c; 
            // Juntando todos os parâmetros
            $$.lista_tipo = $1.lista_tipo;
            $$.lista_tipo.insert( $$.lista_tipo.end(), 
                                  $3.lista_tipo.begin(),  
                                  $3.lista_tipo.end() ); 

            $$.lista_str = $1.lista_str;
            $$.lista_str.insert( $$.lista_str.end(), 
                                 $3.lista_str.begin(),  
                                 $3.lista_str.end() ); 
         }
       | PARAM  { $$.c = $1.c; }
       | { $$.c = ""; }
       ;     
     
PARAM : TIPO_VAR TK_ID                                 
        { 
          $$ = Atributos();
          $$.lista_str.push_back($2.v);
          $$.lista_tipo.push_back(TipoGeral($1.t.tipo_base));
        }
      | TIPO_VAR '[' TK_CINT ']' TK_ID                 
        { 
          $$ = Atributos();
          $$.lista_str.push_back($5.v);
          $$.lista_tipo.push_back(TipoGeral($1.t.tipo_base,toInt($3.v)));
        }
      | TIPO_VAR '[' TK_CINT ']' '[' TK_CINT ']' TK_ID 
        {
          $$ = Atributos();
          $$.lista_str.push_back($8.v);
          $$.lista_tipo.push_back(TipoGeral($1.t.tipo_base,toInt($3.v),toInt($6.v)));
        }
      ;          

CORPO : BLOCO_VARS BLOCO { $$ = Atributos("",TipoGeral(),$1.c + $2.var_temp + $2.c); }
      | BLOCO            { $$ = Atributos("",TipoGeral(),$1.var_temp + $1.c); }
      ;          


BLOCO_VARS : TK_VARIAVEIS VARS { $$.c = $2.c; }
           ;

VARS : VAR ';' VARS { $$.c = $1.c + $3.c; }
     | VAR  { $$.c = $1.c; }
     | { $$.c = ""; }
     ;     
     
VAR : TIPO_VAR IDS                                 { $$ = cria_variavel($2.lista_str, TipoGeral($1.t ) ); }
    | TIPO_VAR '[' TK_CINT ']' IDS                 { $$ = cria_variavel($5.lista_str, TipoGeral($1.t.tipo_base,toInt($3.v)) ); }
    | TIPO_VAR '[' TK_CINT ']' '[' TK_CINT ']' IDS { $$ = cria_variavel($8.lista_str, TipoGeral($1.t.tipo_base,toInt($3.v),toInt($6.v))); }
    ;

TIPO_VAR : TK_TIPO_NUMERO             { $$ = $1; }
         | TK_TIPO_NUMERO_COM_VIRGULA { $$ = $1; }
         | TK_TIPO_LETRA              { $$ = $1; }
         | TK_TIPO_PALAVRA            { $$ = $1; }
         | TK_TIPO_SIMOUNAO           { $$ = $1; }
         ;
    
IDS : TK_ID ',' IDS { $3.lista_str.push_back($1.v); $$ = $3; }
    | TK_ID         { $1.lista_str.push_back($1.v); $$ = $1; }
    ; 

// Declaração  do método Principal

MAIN : TK_TENTE TK_INICIAR TK_DEVOLVE TIPO_VAR BLOCO_VARS BLOCO { $$.c = "int main("+ clean_vars($1.c) +"){\n" + $5.c + $6.var_temp + $6.c + "l_exit:;\n  return 0;\n}"; }
     | TK_TENTE TK_INICIAR TK_DEVOLVE TIPO_VAR BLOCO {  $$.c = "int main("+ clean_vars($1.c) +"){ \n" + $5.var_temp + $5.c + "}"; }  
     ;


BLOCO : TK_TRANQUILO CMDS TK_FAVORAVEL { $$.c = $2.c; $$.var_temp = $2.var_temp; }
      ;
      
CMDS : CMD ';' CMDS
       { $$.c = $1.c + $3.c; 
         $$.var_temp = $1.var_temp + $3.var_temp; }
     | { $$.c = ""; $$.var_temp = ""; }
     ;  
     
CMD : WRITELN
    | WRITE
    | READLN
    | ATRIB 
    | BLOCO 
    | CMD_FOR 
    | CMD_WHILE
    | CMD_DO_WHILE
    | CMD_SWICTH
    | CMD_IF
    | CMD_RETORNA
    | CMD_LING
    | CMD_TOFORA
    ; 


CMD_LING : TK_ID '(' PARAMS_FUNC ')'
         {
            TipoGeral funcao = consulta_ts($1.v);
            string variavel_resultado =  gera_nome_var_temp(funcao.tipo_base);

            if( funcao.params.size() != $3.parametros.size() )
              error("Número de parâmetros errado, Função: " + $1.v + " requer " + toString(funcao.params.size()) + " dado " + toString($3.parametros.size()));

            for( int i = 0; i < funcao.params.size(); i++){
              if( testa_tipoVariavel(funcao.params[i], $3.parametros[i].t) )
                error("Tipo de parâmetro errado: parâmetro " + toString(i+1) + " tipo errado,  esperado "+ funcao.params[i].tipo_base );
            }

            string aux = "  "+variavel_resultado +" = "+ $1.v+ "(";
            string code_ant = "";
            string var_temp_aux = declara_variavel(variavel_resultado, funcao);

            for( int i = 0; i < $3.parametros.size(); i++){
                code_ant = code_ant + $3.parametros[i].c;                
                aux = aux + $3.parametros[i].v + ((i != $3.parametros.size()-1)? ",": "");
                var_temp_aux = var_temp_aux + $3.parametros[i].var_temp;
            }

            aux = aux + ");\n";

            $$ = Atributos(variavel_resultado,funcao,code_ant + aux,var_temp_aux);
         }
         ;

PARAMS_FUNC : E ',' PARAMS_FUNC 
              { 
                 $$.parametros.push_back($1);
                 $$.parametros.insert( $$.parametros.end(), 
                                       $3.parametros.begin(),  
                                       $3.parametros.end() );
              }
            | E { $$.parametros.push_back($1); }
            | { $$ = Atributos(); }
            ;     

CMD_RETORNA : TK_RETORNA E { $$ = Atributos("",TipoGeral(), $2.c + "  return " + $2.v + ";\n",$2.var_temp); }
            ;

CMD_IF : TK_SE E TK_FAZ CMD
         { 
           if( testa_tipoVariavel($2.t,TipoGeral("b")) )
              error("Atribuição com tipos errados errados! "+ $2.t.tipo_base +" <- b");
           $$ = gera_codigo_if( $2, $4.c, "" ); 
           $$.var_temp = $2.var_temp + $4.var_temp; 
         }  
       | TK_SE E TK_FAZ CMD TK_SENAO CMD 
          { 
            if( testa_tipoVariavel($2.t,TipoGeral("b")) )
              error("Atribuição com tipos errados errados! "+ $2.t.tipo_base +" <- b");
            $$ = gera_codigo_if( $2, $4.c, $6.c ); 
            $$.var_temp = $2.var_temp + $4.var_temp + $6.var_temp; 
          }  
       ;

CMD_SWICTH : TK_ESCOLHE E { auxSwitch.label_exit = last_label_swicth(); auxSwitch.v_exp = $2.v; } TK_ENTRE CASES PADRAO TK_VLW 
              {  
                $$.var_temp = $2.var_temp + $5.var_temp + $6.var_temp;
                $$.c = $2.c + $5.c + $6.c + auxSwitch.label_exit + ":;\n";
              }
           ;

CASES : CASE CASES {  
                      $$.var_temp = $1.var_temp + $2.var_temp;
                      $$.c = $1.c + $2.c;
                   }
      | { }
      ; 

CASE : TK_CASO E ':' CMDS {  
                            string label_teste = gera_label( "teste_case" );
                            string label_fim = gera_label( "fim_case" );
                            string condicao = gera_nome_var_temp( "b" );

                            $$.var_temp = $2.var_temp + $4.var_temp;
                            $$.c = $2.c + 
                                    "  "+ condicao + " = " + auxSwitch.v_exp + " == " + $2.v +";\n"+
                                    "  "+ condicao + " = !" + condicao +";\n"+
                                    "  if(" + condicao + ") goto "+ label_fim + ";\n"
                                    + $4.c +
                                    label_fim+ ":;\n";
                            $$.var_temp = $2.var_temp + $4.var_temp + declara_variavel(condicao, TipoGeral("b"));
                          }
     | TK_CASO E ':' CMDS BELEZA {  
                                  string label_teste = gera_label( "teste_case" );
                                  string label_fim = gera_label( "fim_case" );
                                  string condicao = gera_nome_var_temp( "b" );

                                  $$.var_temp = $2.var_temp + $4.var_temp;
                                  $$.c = $2.c + 
                                          "  "+ condicao + " = " + auxSwitch.v_exp + " == " + $2.v +";\n"+
                                          "  "+ condicao + " = !" + condicao +";\n"+
                                          "  if(" + condicao + ") goto "+ label_fim + ";\n"
                                          + $4.c +
                                          "  goto " + auxSwitch.label_exit + ";\n" +
                                          label_fim+ ":;\n";
                                  $$.var_temp = $2.var_temp + $4.var_temp + declara_variavel(condicao, TipoGeral("b"));                                    
                                }
     ;

PADRAO : TK_PADRAO ':' CMDS {  
                            string label_fim = gera_label( "fim_case_padrao" );
                            $$.var_temp = $2.var_temp + $3.var_temp;
                            $$.c = $2.c + $3.c + label_fim+ ":;\n";
                            $$.var_temp = $2.var_temp + $3.var_temp;
                          }
     | TK_PADRAO ':' CMDS BELEZA {  
                                  string label_fim = gera_label( "fim_case_padrao" );
                                  $$.var_temp = $2.var_temp + $3.var_temp;
                                  $$.c = $2.c + $3.c + "  goto " + auxSwitch.label_exit + ";\n" + label_fim+ ":;\n";
                                  $$.var_temp = $2.var_temp + $4.var_temp;
                                }
     |
     ;

BELEZA : TK_BELEZA ';'
       ;

CMD_WHILE : TK_ENQUANTO E TK_FAZ CMD 
            {
              if( testa_tipoVariavel($2.t,TipoGeral("b")) )
                error("Atribuição com tipos errados errados! "+ $2.t.tipo_base +" <- b");

              string label_teste = gera_label( "teste_while" );
              string label_fim = gera_label( "fim_while" );
              string condicao = gera_nome_var_temp( "b" );

              $$.c =  label_teste + ":;\n" + 
                      $2.c + 
                      "  " +condicao+" = !" + $2.v + ";\n" + 
                      "  " + "if( " + condicao + " ) goto " + label_fim + ";\n" +
                      $4.c +
                      "  goto " + label_teste + ";\n" +
                      label_fim + ":;\n";  

              $$.var_temp = $4.var_temp + $2.var_temp + declara_variavel(condicao, TipoGeral("b"));
            }
          ;

CMD_DO_WHILE : TK_FAZ BLOCO TK_ENQUANTO E  
            {
              if( testa_tipoVariavel($4.t,TipoGeral("b")) )
                error("Atribuição com tipos errados errados! "+ $2.t.tipo_base +" <- b");

              string label_inicio = gera_label( "inicio_do_while" );
              string condicao = gera_nome_var_temp( "b" );

              $$.c =  label_inicio + ":;\n" + 
                      $2.c + 
                      $4.c + 
                      "  " +condicao+" = " + $4.v + ";\n" + 
                      "  " + "if( " + condicao + " ) goto " + label_inicio + ";\n";  

              $$.var_temp = $4.var_temp + $2.var_temp + declara_variavel(condicao, TipoGeral("b"));
            }
          ;


CMD_FOR : TK_ENQUANTO NOME_VAR TK_ATRIB E TK_VAI TK_ATE E TK_FAZ CMD 
          { 
            TipoGeral ss("i");
            
            if( testa_tipoVariavel($2.t,ss) )
              error("Atribuição com tipos errados errados! "+ $2.t.tipo_base +" <- i");
            if( testa_tipoVariavel($4.t,ss) )
              error("Atribuição com tipos errados errados! "+ $4.t.tipo_base +" <- i");
            if( testa_tipoVariavel($7.t,ss) )
              error("Atribuição com tipos errados errados! "+ $7.t.tipo_base +" <- i");

            string var_fim = gera_nome_var_temp( $2.t.tipo_base);
            string label_teste = gera_label( "teste_for" );
            string label_fim = gera_label( "fim_for" );
            string condicao = gera_nome_var_temp( "b" );
          
            $$.c =  $4.c + $7.c +
                    "  " + $2.v + " = " + $4.v + ";\n" +
                    "  " + var_fim + " = " + $7.v + ";\n" +
                    label_teste + ":;\n" +
                    "  " +condicao+" = "+$2.v + " < " + var_fim + ";\n" + 
                    "  " +condicao+" = !"+condicao+ ";\n" + 
                    "  " + "if( " + condicao + " ) goto " + label_fim + ";\n" +
                    $9.c +
                    "  " + $2.v + " = " + $2.v + " + 1;\n" +
                    "  goto " + label_teste + ";\n" +
                    label_fim + ":;\n";  
            $$.var_temp = $4.var_temp + $7.var_temp + $9.var_temp + 
                           declara_variavel(var_fim, $2.t) + 
                           declara_variavel(condicao,TipoGeral("b"));
          }
        ;

READLN : TK_LEISSOAI '(' E ',' F ')' { $$ =  gera_codigo_readln($3,$5); }
        ;

WRITELN : TK_ESCREVEAI '(' E ')' { $$ =  gera_codigo_writeln($3); }
        ;

WRITE : TK_ESCREVEAISEMPULARLINHA '(' E ')' { $$ =  gera_codigo_write($3); }
      ;        

CMD_TOFORA : TK_TOFORA '(' E ')' { $$ =  gera_codigo_to_fora($3); }
      ;              
  
ATRIB : F TK_ATRIB E { $$ = gera_codigo_atrib($1,$3); } 
      ;   

E : E '+' E             { $$ = gera_codigo_opr( $1, "+" , $3 ); }
  | E '-' E             { $$ = gera_codigo_opr( $1, "-" , $3 ); }
  | E '*' E             { $$ = gera_codigo_opr( $1, "*" , $3 ); }
  | E '/' E             { $$ = gera_codigo_opr( $1, "/" , $3 ); }
  | E '%' E             { $$ = gera_codigo_opr( $1, "%" , $3 ); }
  | E '<' E             { $$ = gera_codigo_opr( $1, "<" , $3 ); }
  | E '>' E             { $$ = gera_codigo_opr( $1, ">" , $3 ); }
  | E TK_MEIG E         { $$ = gera_codigo_opr( $1, "<=", $3 ); }
  | E TK_MAIG E         { $$ = gera_codigo_opr( $1, ">=", $3 ); }
  | E TK_IGUAL E        { $$ = gera_codigo_opr( $1, "==", $3 ); }
  | E TK_DIF E          { $$ = gera_codigo_opr( $1, "!=", $3 ); }
  | E TK_E E            { $$ = gera_codigo_opr( $1, "&&" , $3 ); }
  | F TK_PERTENCE F     { $$ = gera_codigo_opr( $1, "in" , $3 ); } // Só posso fazer 'in' com variaveis e vetores
  | E TK_OU E           { $$ = gera_codigo_opr( $1, "||", $3 ); }
  | '(' E ')'           { $$ = $2; }
  | F                   { $$ = $1; }
  ;
  
F : NOME_VAR           { $$ = $1; }
  | NOME_VAR '[' E ']' { $$ = gera_codigo_teste_vetor($1,$3); }
  | NOME_VAR '[' E ']' '[' E ']'{ $$ = gera_codigo_teste_matrix($1,$3,$6); }
  | TK_CINT    { $$ = Atributos($1.v,TipoGeral("i"),$1.c); }
  | TK_CDOUBLE { $$ = Atributos($1.v,TipoGeral("d"),$1.c); }
  | TK_CSTRING { $$ = Atributos($1.v,TipoGeral("s"),$1.c); }
  | TK_VERDADE { $$ = Atributos($1.v,TipoGeral("b"),$1.c); }
  | TK_MENTIRA { $$ = Atributos($1.v,TipoGeral("b"),$1.c); }
  | CMD_LING   { $$ = $1;}
  ;

NOME_VAR : TK_ID { $$ = Atributos($1.v, consulta_ts( $1.v ),$1.c ); }                    
         ; 
  
%%
int nlinha = 1;

#include "lex.yy.c"

int yyparse();

string TipoGeralToString(TipoGeral tipo){
  return tipo.tipo_base + '(' + toString(tipo.ndim) + ',' + toString(tipo.tam[0]) + ',' + toString(tipo.tam[1]) + ')';
}

void debug( string producao, Atributos atr ) {
  cerr << "Debug: " << producao << endl;
  cerr << "  t: " << TipoGeralToString(atr.t) << endl;
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
  tipo_opr["s<s"] = "b";

  // Resultados para o operador ">"
  tipo_opr["i>i"] = "b";
  tipo_opr["i>d"] = "b";
  tipo_opr["d>i"] = "b";
  tipo_opr["d>d"] = "b";
  tipo_opr["c>c"] = "b";
  tipo_opr["i>c"] = "b";
  tipo_opr["c>i"] = "b";
  tipo_opr["s>s"] = "b";

    // Resultados para o operador "<="
  tipo_opr["i<=i"] = "b";
  tipo_opr["i<=d"] = "b";
  tipo_opr["d<=i"] = "b";
  tipo_opr["d<=d"] = "b";
  tipo_opr["c<=c"] = "b";
  tipo_opr["i<=c"] = "b";
  tipo_opr["c<=i"] = "b";
  tipo_opr["s<=s"] = "b";

  // Resultados para o operador ">="
  tipo_opr["i>=i"] = "b";
  tipo_opr["i>=d"] = "b";
  tipo_opr["d>=i"] = "b";
  tipo_opr["d>=d"] = "b";
  tipo_opr["c>=c"] = "b";
  tipo_opr["i>=c"] = "b";
  tipo_opr["c>=i"] = "b";
  tipo_opr["s>=s"] = "b";

  // Resultados para o operador "!="
  tipo_opr["i!=i"] = "b";
  tipo_opr["i!=d"] = "b";
  tipo_opr["d!=i"] = "b";
  tipo_opr["d!=d"] = "b";
  tipo_opr["c!=c"] = "b";
  tipo_opr["i!=c"] = "b";
  tipo_opr["c!=i"] = "b";
  tipo_opr["s!=s"] = "b";

  tipo_opr["i==i"] = "b";
  tipo_opr["i==d"] = "b";
  tipo_opr["d==i"] = "b";
  tipo_opr["d==d"] = "b";
  tipo_opr["c==c"] = "b";
  tipo_opr["i==c"] = "b";
  tipo_opr["c==i"] = "b";
  tipo_opr["s==s"] = "b";

  // Resultados para o operador "&&"
  tipo_opr["i%i"] = "i";

  // Resultados para o operador "&&"
  tipo_opr["b&&b"] = "b";

  // Resultados para o operador "||"
  tipo_opr["b||b"] = "b";

  // Resultados para o operador "in"
  tipo_opr["iini"] = "b";
  tipo_opr["dind"] = "b";

  tipos["i"] = "int";
  tipos["d"] = "double";
  tipos["c"] = "char";
  tipos["s"] = "char";
  tipos["b"] = "int";
}

void empilha_ts() {
  map< string, TipoGeral > novo;
  tabela_simbolos.push_back( novo );
}

void desempilha_ts() {
  tabela_simbolos.pop_back();
}

int existe_ts(string nome_var){
  for( int i = tabela_simbolos.size()-1; i >= 0; i-- )
    if( tabela_simbolos[i].find( nome_var ) != tabela_simbolos[i].end() )
      return 1;
  return 0;
}

string last_label_swicth(){
  static string result;

  if (!label_swicth_flag){
      result = gera_label("fechamento_switch");
      label_swicth_flag = 1;
  }
 
  return result;
}

void close_switch(){
  label_swicth_flag = 0;
}

TipoGeral consulta_ts( string nome_var ) {
  for( int i = tabela_simbolos.size()-1; i >= 0; i-- )
    if( tabela_simbolos[i].find( nome_var ) != tabela_simbolos[i].end() )
      return tabela_simbolos[i][ nome_var ];
    
//  if( tabela_simbolos.find( nome_var ) != tabela_simbolos.end() )
//      return tabela_simbolos[ nome_var ];
    error( "Variável não declarada: " + nome_var );
  
    return TipoGeral();
}

void inserir_var_ts( string nome_var, TipoGeral tipo ) {
  if( tabela_simbolos[tabela_simbolos.size()-1].find( nome_var ) != tabela_simbolos[tabela_simbolos.size()-1].end() )
    error( "Variável já declarada: " + nome_var + 
          " (" + tabela_simbolos[tabela_simbolos.size()-1][ nome_var ].tipo_base + ")" );   
  tabela_simbolos[tabela_simbolos.size()-1][ nome_var ] = tipo;

//  if( tabela_simbolos.find( nome_var ) != tabela_simbolos.end() )
//    error( "Variável já declarada: " + nome_var + 
//          " (" + tabela_simbolos[ nome_var ].tipo_base + ")" );   
//  tabela_simbolos[ nome_var ] = tipo;
}

string gera_nome_var_temp( string tipo ) {
  static int n = 0;
  string nome = "t" + tipo + "_" + toString( ++n );
  return nome; 
}

int testa_tipoVariavel(TipoGeral t1, TipoGeral t2){
  if( (t1.tipo_base.compare("d") == 0) && (t2.tipo_base.compare("i") == 0 ) ) {
    return 0;
  }

  if( t1.tipo_base.compare(t2.tipo_base) != 0){
    cerr << "Tipos errados!" << endl;
    cerr << TipoGeralToString(t1) << endl;
    cerr << TipoGeralToString(t2) << endl;
   // error("Atribuição com tipos errados errados! "+ t1.tipo_base +" <- "+ t2.tipo_base);
    return 1;
  }  
  return 0;
}


string gera_label( string tipo ) {
  static int n = 0;
  string nome = "l_" + tipo + "_" + toString( ++n );
  return nome;
}

string declara_variavel( string nome, TipoGeral tipo ) {
  if( tipos[ tipo.tipo_base ].compare("") == 0) 
    error( "Tipo inválido de variável: " + tipo.tipo_base );

  if( (tipo.tipo_base.compare("s") == 0)&&(tipo.ndim != 0) )
    error( "Tipo inválido, não suportado pela linguagem: vetor de string ");
    
  string indice;
   
  switch( tipo.ndim ) {
    case 0: indice = (tipo.tipo_base == "s" ? "[256]" : "");
            break;
              
    case 1: indice = "[" +toString(tipo.tam[0]*(tipo.tipo_base == "s" ? 256 : 1)) + "]";
            break; 
            
    case 2: indice = "[" +toString(tipo.tam[0]*tipo.tam[1]*(tipo.tipo_base == "s" ? 256 : 1)) + "]";
            break;
    
    default:
       error( "Bug muito sério..." );
  } 
  
  return tipos[ tipo.tipo_base ] + "  "+ nome + indice + ";\n";
}

void inserir_funcao_ts( string nome_func,TipoGeral retorno, vector<TipoGeral> params ) {
  if( tabela_simbolos[tabela_simbolos.size()-2].find( nome_func ) != tabela_simbolos[tabela_simbolos.size()-2].end() )
    error( "Função já declarada: " + nome_func );
    
  tabela_simbolos[tabela_simbolos.size()-2][ nome_func ] = TipoGeral( retorno, params );
}

string declara_param( string nome, TipoGeral tipo ) {

  if( tipos[ tipo.tipo_base ].compare("") == 0) 
    error( "Tipo inválido de parâmetro: " + tipo.tipo_base );

  if( (tipo.tipo_base.compare("s") == 0)&&(tipo.ndim != 0) )
    error( "Tipo inválido, não suportado pela linguagem: vetor de string ");
    
  string indice;
   
  switch( tipo.ndim ) {
    case 0: indice = (tipo.tipo_base.compare("s") == 0 ? "[256]" : "");
            break;
              
    case 1: indice = "[" +toString(tipo.tam[0]*(tipo.tipo_base == "s" ? 256 : 1)) + "]";
            break; 
            
    case 2: indice = "[" +toString(tipo.tam[0]*tipo.tam[1]*(tipo.tipo_base == "s" ? 256 : 1)) + "]";
            break;
    
    default:
       error( "Bug muito sério..." );
  } 
  
  return tipos[ tipo.tipo_base ] + "  "+ nome + indice;
}

string declara_funcao(string nome, TipoGeral tipo,vector<string> nomes_param, vector<TipoGeral> tipos_param ) {

  if( tipos[ tipo.tipo_base ].compare("") == 0 ) 
    error( "Tipo inválido de Função: " + tipo.tipo_base );
    
  if( nomes_param.size() != tipos_param.size() )
    error( "Bug no compilador! Nomes e tipos de parametros diferentes." );
      
  string aux = "";
  
  for( int i = 0; i < nomes_param.size(); i++ ) {
    aux += declara_param( nomes_param[i], tipos_param[i] ) + 
           (i == nomes_param.size()-1 ? " " : ", ");  
    inserir_var_ts( nomes_param[i],tipos_param[i]);  
  }

  inserir_funcao_ts( nome,tipo,tipos_param);
      
  return tipos[ tipo.tipo_base ]+(tipo.tipo_base.compare("s") == 0 ? "*" : "") + " " + nome + "(" + aux + ")";
}

Atributos cria_variavel(vector<string> lista, TipoGeral tipo){
  Atributos result = Atributos();
  vector<string>::iterator it;
  for( it = lista.begin(); it != lista.end(); it++){
    
    if(existe_ts(*it)){
      error("A variável já foi declarada no programa!");
    }

    result.c += declara_variavel(*it,tipo);
    inserir_var_ts(*it,tipo);
  }
  return result;
}

string gera_saida_dados(string saida){
    return "cout << " + saida + " << endl;";
}

Atributos gera_codigo_opr_vetor(Atributos s1, Atributos s2, Atributos result, string opr){
    string label_teste = gera_label( "teste_for_comparativo_array" );
    string label_fim = gera_label( "fim_for_comparativo_array" );
    string label_falso = gera_label( "expressao_falsa" );

    string condicao = gera_nome_var_temp( "b" );
    string controle = gera_nome_var_temp( "i" );
    string v1 = gera_nome_var_temp( s1.t.tipo_base );
    string v2 = gera_nome_var_temp( s1.t.tipo_base );
  
    result.c +=
            "  " +condicao+" = \""+ s1.t.tipo_base + "\" != \"" + s2.t.tipo_base + "\";\n" +    // Teste de tipo de vetores
            "  if( " + condicao + " ) goto " + label_falso + ";\n" +
            "  " +condicao+" = "+ toString(s1.t.tam[0]) + " != " + toString(s2.t.tam[0]) + ";\n" + // Teste de tamanho de vetores
            "  if( " + condicao + " ) goto " + label_falso + ";\n" +
            "  " + controle + " = 0 ;\n" +
            label_teste + ":;\n" +
            "  " +condicao+" = "+ controle + " < " + toString(s1.t.tam[0]) + ";\n" + 
            "  " +condicao+" = !"+condicao+ ";\n" + 
            "  if( " + condicao + " ) goto " + label_fim + ";\n";

    if ( (s1.t.tipo_base.compare("s") == 0)){          
      result.c += "  strncpy( " + v1 + ", " + s1.v + "[" + controle + "]" + ", 256 );\n" +
                  "  strncat( " + v1 + ", " + s2.v + "[" + controle + "]" + ", 256 );\n";
    }else{
      result.c += "  " + v1 + " = " + s1.v + "[" + controle + "];\n"+
                  "  " + v2 + " = " + s2.v + "[" + controle + "];\n";
    }

    result.c +=       
            "  " + condicao + " = " + v1 + " "+ opr +" " + v2 + ";\n"+
            "  " + condicao + " =  !" + condicao + ";\n" + 
            "  if( " + condicao + " ) goto " + label_falso + ";\n" +
            "  " + result.v + " = 1;\n" +
            "  " + controle + " = " + controle + " + 1;\n" +
            "  goto " + label_teste + ";\n" +
            label_falso + ":;\n"
            "  " + result.v + " = 0;\n" +
            label_fim + ":;\n";  
    result.var_temp += declara_variavel(condicao,TipoGeral("b")) +
                       declara_variavel(controle,TipoGeral("i")) +
                       declara_variavel(v1,TipoGeral(s1.t.tipo_base)) +
                       declara_variavel(v2,TipoGeral(s1.t.tipo_base));
    return result;
}


Atributos gera_codigo_opr_in_vetor(Atributos s1, Atributos s2, Atributos result){
    string label_teste = gera_label( "teste_for_comparativo_array" );
    string label_fim = gera_label( "fim_for_comparativo_array" );
    string label_falso = gera_label( "expressao_falsa" );

    string condicao = gera_nome_var_temp( "b" );
    string controle = gera_nome_var_temp( "i" );
    string v1 = gera_nome_var_temp( s1.t.tipo_base );
    string v2 = gera_nome_var_temp( s1.t.tipo_base );
  
    result.c +=
            "  " + controle + " = 0 ;\n" +
            "  " + v1 + " = " + s1.v + ";\n"+
            label_teste + ":;\n" +
            "  " +condicao+" = "+ controle + " < " + toString(s2.t.tam[0]) + ";\n" + 
            "  " +condicao+" = !"+condicao+ ";\n" + 
            "  if( " + condicao + " ) goto " + label_fim + ";\n";

    if ( (s1.t.tipo_base.compare("s") == 0)){          
      result.c += "  strncat( " + v1 + ", " + s2.v + "[" + controle + "]" + ", 256 );\n";
    }else{
      result.c += "  " + v2 + " = " + s2.v + "[" + controle + "];\n";
    }

    result.c +=       
            "  " + condicao + " = " + v1 + " == " + v2 + ";\n"+
            "  " + condicao + " =  !" + condicao + ";\n" + 
            "  if( " + condicao + " ) goto " + label_falso + ";\n" +
            "  " + result.v + " = 0;\n" +
            "  " + controle + " = " + controle + " + 1;\n" +
            "  goto " + label_teste + ";\n" +
            label_falso + ":;\n"
            "  " + result.v + " = 1;\n" +
            label_fim + ":;\n";  
    result.var_temp += declara_variavel(condicao,TipoGeral("b")) +
                       declara_variavel(controle,TipoGeral("i")) +
                       declara_variavel(v1,TipoGeral(s1.t.tipo_base)) +
                       declara_variavel(v2,TipoGeral(s1.t.tipo_base));
    return result;
}

Atributos gera_codigo_opr(Atributos s1, string opr, Atributos s2){
  Atributos result;
  string typeOfOpr =  s1.t.tipo_base + opr + s2.t.tipo_base;

  result.t = TipoGeral(tipo_opr[typeOfOpr]); 
  result.v = gera_nome_var_temp(result.t.tipo_base);
  result.var_temp = s1.var_temp + s2.var_temp + declara_variavel(result.v, TipoGeral(result.t) );
  result.c = s1.c + s2.c;

  if( opr.compare("in") == 0){
    if( (s1.t.ndim != 0)||((s2.t.ndim != 1)&&(s2.t.ndim != 2)) )
      error("operador in -> varivel in array; " + s1.v + " in " + s2.v);
    if(s1.t.tipo_base.compare(s2.t.tipo_base) != 0)
      error("operador in precisa de dois tipos iguais: " + s1.t.tipo_base + " in " + s2.t.tipo_base);

    result = gera_codigo_opr_in_vetor(s1,s2,result);
  }else if ( (s1.t.ndim == 1) && (s2.t.ndim == 1) && (opr.compare("==") == 0)){
      result = gera_codigo_opr_vetor(s1,s2,result,"==");
  } else if ( (s1.t.ndim == 1) && (s2.t.ndim == 1) && (opr.compare("!=") == 0)){
      result = gera_codigo_opr_vetor(s1,s2,result,"!=");
  } else if( typeOfOpr.compare("s+s") == 0){
    result.c += "  strncpy( " + result.v + ", " + s1.v + ", 256 );\n" +
                "  strncat( " + result.v + ", " + s2.v + ", 256 );\n";
  }else{
    result.c += "  " + result.v + " = " + s1.v + " " + opr + " " + s2.v + ";\n";                
  }
  
  return result;
}

Atributos gera_codigo_teste_vetor(Atributos nome_vetor,Atributos indice) {
  Atributos ss;
  TipoGeral aux = consulta_ts(nome_vetor.v);
  
  string label_else = gera_label( "erro_array_"+nome_vetor.v );
  string label_end = gera_label( "saida_vetor" );
  string variavel_teste =  gera_nome_var_temp("i");
  
  ss.c = indice.c + 
         "  " + variavel_teste + " = " + indice.v + " < "+ toString(aux.tam[0]) + ";\n"+
         "  " + variavel_teste + " = !" + variavel_teste + ";\n"+
         "  if( "+ variavel_teste +") goto " + label_else + ";\n" +
         "  goto "+label_end+"; \n" + 
         label_else + ":;\n" +
         "  cerr << \"Excedeu tamanho do vetor! \";\n" +
         "  cerr << \"" + nome_vetor.v + "[\";\n"+
         "  cerr << " +  indice.v + ";\n" + 
         "  cerr << \"]\\n\";\n"+
         "  exit(1);\n" +
         label_end + ":;\n";

  ss.v = nome_vetor.v + '[' + indice.v + "]";
  ss.t = aux; 
  ss.var_temp = indice.var_temp + declara_variavel(variavel_teste,TipoGeral("i")); 
         
  return ss;       
}

Atributos gera_codigo_teste_matrix( Atributos nome_vetor,Atributos indice1, Atributos indice2) {
  Atributos ss;
  TipoGeral aux = consulta_ts(nome_vetor.v);

  string label_else = gera_label( "erro_array_"+nome_vetor.v );
  string label_end = gera_label( "saida_matrix" );
  string variavel_teste =  gera_nome_var_temp("i");

  // Testa a dimensão 1 da matriz
  // Testa a dimensão 2 da matriz
  
  ss.c = indice1.c + indice2.c +
         "  " + variavel_teste + " = " + indice1.v + " < "+ toString(aux.tam[0]) + ";\n"+
         "  " + variavel_teste + " = !" + variavel_teste + ";\n"+
         "  if( "+ variavel_teste +") goto " + label_else + ";\n" +
         "  goto "+label_end+"; \n" + 
         "  " + variavel_teste + " = " + indice2.v + " < "+ toString(aux.tam[1]) + ";\n"+
         "  " + variavel_teste + " = !" + variavel_teste + ";\n"+
         "  if( "+ variavel_teste +") goto " + label_else + ";\n" +
         "  goto "+label_end+"; \n" + 
         label_else + ":;\n" +
         "  cerr << \"Excedeu tamanho do vetor! \";\n" +
         "  cerr << \"" + nome_vetor.v + "[\";\n"+
         "  cerr << " +  indice1.v + ";\n" + 
         "  cerr << \"][\";\n"+
         "  cerr << " +  indice2.v + ";\n" + 
         "  cerr << \"]\\n\";\n"+
         "  exit(1);\n" +
         label_end + ":;\n" + 
         "  "+ variavel_teste + " = " + indice1.v + '*' + toString(aux.tam[1]) + ";\n" +
         "  "+ variavel_teste + " = " + variavel_teste + '+' + indice2.v + ";\n";
         
  ss.v = nome_vetor.v + '[' + variavel_teste + ']';
  ss.t = aux; 
  ss.var_temp = nome_vetor.var_temp + indice1.var_temp + indice2.var_temp + declara_variavel(variavel_teste,TipoGeral("i")); 
         
  return ss;       
}

Atributos gera_codigo_if( Atributos expr, string cmd_then, string cmd_else ) {
  Atributos ss;
  string label_else = gera_label( "else" );
  string label_end = gera_label( "end" );
  
  ss.c = expr.c + 
         "  " + expr.v + " = !" + expr.v + ";\n" +
         "  if( " + expr.v + " ) goto " + label_else + ";\n" +
         cmd_then +
         "  goto " + label_end + ";\n" +
         label_else + ":;\n" +
         cmd_else +
         label_end + ":;\n";
         
  return ss;       
}

Atributos gera_codigo_atrib(Atributos esquerda, Atributos direita){
    Atributos ss;

    if( testa_tipoVariavel(esquerda.t,direita.t) ) 
    ;
    string variavel =  gera_nome_var_temp(esquerda.t.tipo_base);

    ss.c = esquerda.c + direita.c;
    if( esquerda.t.tipo_base.compare("s") == 0 && direita.t.tipo_base.compare("s") == 0){
      ss.c = ss.c + "  strncpy( " + esquerda.v + ", " + direita.v + ", 256 );\n";
    }else if( esquerda.t.ndim != 0 || direita.t.ndim != 0){
      ss.c = ss.c +  "  " + variavel + " = " + direita.v + ";\n" +
                     "  " + esquerda.v + " = " + variavel + ";\n";
    }else{
      ss.c = ss.c + "  " + esquerda.v + " = " + direita.v + ";\n";
    }
    
    ss.var_temp = esquerda.var_temp + direita.var_temp + declara_variavel(variavel,TipoGeral(esquerda.t.tipo_base));
    return ss;
}

Atributos gera_codigo_writeln(Atributos expr){
  Atributos ss;

  string variavel =  gera_nome_var_temp(expr.t.tipo_base);

  ss.c = expr.c;
  if( expr.t.ndim != 0){
      ss.c += "  " + variavel + " = " + expr.v + ";\n"+
              "  cout << " + variavel + ";\n  cout << endl;\n";
  }else{
      ss.c += "  cout << " + expr.v + ";\n  cout << endl;\n";
  }

  ss.var_temp = expr.var_temp 
                  + declara_variavel(variavel,TipoGeral(expr.t.tipo_base));
  return ss;
}

Atributos gera_codigo_write(Atributos expr){
  Atributos ss;

  string variavel =  gera_nome_var_temp(expr.t.tipo_base);

  ss.c = expr.c;
  if( expr.t.ndim != 0){
      ss.c += "  " + variavel + " = " + expr.v + ";\n"+
              "  cout << " + variavel + ";\n";
  }else{
      ss.c += "  cout << " + expr.v + ";\n";
  }

  ss.var_temp = expr.var_temp 
                  + declara_variavel(variavel,TipoGeral(expr.t.tipo_base));
  return ss;
}

Atributos gera_codigo_to_fora(Atributos expr){
  Atributos ss;

  string variavel =  gera_nome_var_temp(expr.t.tipo_base);

  ss.c = expr.c;
  if( expr.t.ndim != 0){
      ss.c += "  " + variavel + " = " + expr.v + ";\n"+
              "  exit(" + variavel + ");\n";
  }else{
      ss.c += "  exit(" + expr.v + ");\n";
  }

  ss.var_temp = expr.var_temp 
                  + declara_variavel(variavel,TipoGeral(expr.t.tipo_base));
  return ss;
}

Atributos gera_codigo_readln(Atributos expr, Atributos variavel_leitura){
  Atributos ss;
  
  string variavel_expr_temp =  gera_nome_var_temp(expr.t.tipo_base);
  string variavel_leitura_temp =  gera_nome_var_temp(variavel_leitura.t.tipo_base);

  ss.c = expr.c + variavel_leitura.c;
  if( expr.t.ndim != 0){
      ss.c += "  " + variavel_expr_temp + " = " + expr.v + ";\n"+
              "  cout << " + variavel_expr_temp + ";\n  cout << endl;\n";
  }else{
      ss.c += "  cout << " + expr.v + ";\n  cout << endl;\n";
  }

  if( variavel_leitura.t.ndim != 0){
      ss.c += "  cin >> " + variavel_leitura_temp + ";\n" +
              "  " + variavel_leitura.v  + " = " + variavel_leitura_temp + ";\n";
  }else{
      ss.c += "  cin >> " + variavel_leitura.v + ";\n";
  }  

  ss.var_temp = expr.var_temp  + variavel_leitura.var_temp
                       + declara_variavel(variavel_expr_temp,TipoGeral(expr.t.tipo_base))
                       + declara_variavel(variavel_leitura_temp,TipoGeral(variavel_leitura.t.tipo_base));
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

string replaceChar(string str, char find, char repl){
  string::iterator it;
  string aux = "";

  for(it = str.begin(); it != str.end(); it++)
      if ( *it == find) 
        aux = aux + repl;
      else
        aux = aux + *it; 

  return aux;
}

string clean_vars(string str){
    string aux  = replaceChar(str,';',',');
    string aux2 = replaceChar(aux,'\n','\0');
    size_t last = aux2.find_last_not_of(' ');
    return aux2.substr(0,last-1);
}


int main( int argc, char* argv[] )
{
  preload();
  yyparse();
}
