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

DARROW     =>
ASSIGN     <-
LE         <=   

DIGIT      [0-9]
OBJID      [a-z][a-zA-Z0-9_]*
TYPEID     [A-Z][a-zA-Z0-9_]*

%%

[ \t\r\n\f\v]+  ;  /*skip whitespace*/

{DARROW}		{ return (DARROW); }
{ASSIGN}		{ return (ASSIGN); }
{LE}		    { return (LE); }

{DIGIT}+ {
   cool_yylval.symbol = idtable.add_string(yytext);
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
  cool_yylval.boolean = true;
  return (BOOL_CONST);
}
"f[aA][lL][sS][eE]" {
  cool_yylval.boolean = false;
  return (BOOL_CONST);
}
[cC][lL][aA][sS][sS]	            { return (CLASS); }
[eE][lL][sS][eE] 			            { return (ELSE); }
[fF][iI]                          { return (FI); }
[iI][fF]                          { return (IF); }
[Ii][Nn]                          { return (IN); }
[iI][nN][hH][eE][rR][iI][tT][sS]  { return (INHERITS); } 
[iI][sS][vV][oO][iI][dD]	        { return (ISVOID); } 
[lL][eE][tT]                      { return (LET); }
[lL][oO][oO][pP]	                { return (LOOP); }
[pP][oO][oO][lL]	                { return (POOL); }
[tT][hH][eE][nN]	                { return {THEN}; }
[wW][hH][iI][lL][eE]	            { return (WHILE); }
[cC][aA][sS][eE]	                { return (CASE); }
[eE][sS][aA][cC]	                { return (ESAC); }
[nN][eE][wW]	                    { return (NEW); }
[oO][fF]	                        { return (OF); }
[nN][oO][tT]	                    { return (NOT); }

/* Comments begin with -- and extend to the end of the line */
"--".*          ;

/*Comments can also be enclosed in (* and *) */
"(*"            {

  int input()
  {
    int c = getc(fin);
    if (c == '\n') {
      curr_lineno++;
    }
    return c;
  }

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
