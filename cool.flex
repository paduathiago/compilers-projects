/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */

%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */
/*
   The two statements below are here just so this program will compile.
   You may need to change or remove them on your final code.
*/
#define yywrap() 1
#define YY_SKIP_YYWRAP

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

DIGIT      [0-9]
OBJID      [a-z][a-zA-Z0-9_]*
TYPEID     [A-Z][a-zA-Z0-9_]*
DARROW  =>

%%

[ \t\r\n\f\v]+  ;  /*skip whitespace*/

 /*
  *  Nested comments
  */

{DIGIT}+ {
  cool_yylval.symbol = atoi(yytext);
  return (INT_CONST);
}

{TYPEID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (TYPEID);
}

{OBJID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (OBJECTID);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c. 
  */

"\"[^\b\f\n\r\t\v]*\"" {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (STR_CONST);
}

 /*
  *  The multiple-character operators.
  */

{DARROW}		{ return (DARROW); }

/*single-character tokens */
"{"             { return LBRACE; }
"}"             { return RBRACE; }
"("             { return LPAREN; }
")"             { return RPAREN; }
";"             { return SEMICOLON; }
":"             { return COLON; }
","             { return COMMA; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULT; }
"/"             { return DIV; }
"="             { return EQUALS; }
"<"             { return LESS_THAN; }
"@"             { return AT; }

/*  The following are reserved words
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
*/

"t[rR][uU][eE]" {
  cool_yylval.boolean = 1;
  return (BOOL_CONST);
}
"f[aA][lL][sS][eE]" {
  cool_yylval.boolean = 0;
  return (BOOL_CONST);
}
"class"       { return (CLASS); }
"else" 			  { return (ELSE); }
"fi"          { return (FI); }
"if"          { return (IF); }
"in"          { return (IN); }
"inherits"    { return (INHERITS); } 
"isvoid"      { return (ISVOID); } 
"let"         { return (LET); }
"loop"        { return (LOOP); }
"pool"        { return (POOL); }
"then"        { return (THEN); }
"while"       { return (WHILE); }
"case"        { return (CASE); }
"esac"        { return (ESAC); }
"new"         { return (NEW); }
"of"          { return (OF); }
"not"         { return (NOT); }

/* Comments begin with -- and extend to the end of the line */
"--".*          ;

/*Comments can also be enclosed in (* and *) */
"(*"            {
  int comment_depth = 1;
  while (comment_depth > 0) {
    int c = input();
    if (c == EOF) {
      cool_yylval.error_msg = "EOF in comment";
      return (ERROR);
    }
    if (c == '(') {
      c = input();
      if (c == EOF) {
        cool_yylval.error_msg = "EOF in comment";
        return (ERROR);
      }
      if (c == '*') {
        comment_depth++;
      }
    }
    if (c == '*') {
      c = input();
      if (c == EOF) {
        cool_yylval.error_msg = "EOF in comment";
        return (ERROR);
      }
    }
      if (c == ')') {
        comment_depth--;
      }
    }
  }


%%
