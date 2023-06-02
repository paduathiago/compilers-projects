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
int nested_comments = 0;
int long_str_error();
void read_char(char ch);

%}

SINGLE_TOKENS ["{"|"}"|"("|")"|":"|";"|"@"|","|"."|"+"|"-"|"*"|"/"|"="|"<"|">"]

/* 
 *  The multiple-character operators. 
 */
DARROW     =>
ASSIGN     <-
LE         <=   

DIGIT      [0-9]
OBJID      [a-z][a-zA-Z0-9_]*
TYPEID     [A-Z][a-zA-Z0-9_]*

%x STR COMMENT TREAT_STR_ERROR DASH_COMMENT

%%

[ \t\r\n\f\v]+ {/*skip whitespace*/}

\n          { curr_lineno++; }

{DARROW}		{ return (DARROW); }
{ASSIGN}		{ return (ASSIGN); }
{LE}		    { return (LE); }

{DIGIT}+ {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (INT_CONST);
}

{SINGLE_TOKENS} { return int(yytext[0]); }

 /*  
  *  The following are reserved words
  *  Keywords are case-insensitive except for the values true and false,
  *  which must begin with a lower-case letter.
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
[tT][hH][eE][nN]	                { return (THEN); }
[wW][hH][iI][lL][eE]	            { return (WHILE); }
[cC][aA][sS][eE]	                { return (CASE); }
[eE][sS][aA][cC]	                { return (ESAC); }
[nN][eE][wW]	                    { return (NEW); }
[oO][fF]	                        { return (OF); }
[nN][oO][tT]	                    { return (NOT); }

{TYPEID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (TYPEID);
}

{OBJID} {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (OBJECTID);
}

  /*  STRINGS */
\" {string_buf_ptr = string_buf; BEGIN(STR);}

<STR>{
  \" {
    *string_buf_ptr = '\0';
    cool_yylval.symbol = idtable.add_string(string_buf);
    BEGIN(INITIAL);
    return (STR_CONST);
  }

  <<EOF>> {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(INITIAL);
    return (ERROR);
  }

  \0 {
    cool_yylval.error_msg = "Null character in string";
    BEGIN(TREAT_STR_ERROR);
    return(ERROR);
  }

  \n {
    cool_yylval.error_msg = "Unterminated string constant";
    curr_lineno++;
    BEGIN(INITIAL);
    return (ERROR);
  }

  /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c. 
  */

  \\n {
    curr_lineno++;
    read_char('\n');
  }
  \\t {read_char('\t');}
  \\r {read_char('\r');}
  \\b {read_char('\b');}
  \\f {read_char('\f');}

  \\(.|\n) { read_char(yytext[1]); }

  /* Reads all other characters */
  [^\\\n\"]+ {  
    char *yptr = yytext;
    while (*yptr){
      read_char(*yptr);
      yptr++;
    }
  }  
}

 /* Comments begin with -- and extend to the end of the line */
"--" { BEGIN(DASH_COMMENT); }

<DASH_COMMENT>{
	\n {
    curr_lineno++;
    BEGIN(INITIAL);
  }
  .*	
}

"*)" {
  cool_yylval.error_msg = "Unmatched *)";
  return (ERROR);
}

 /*Comments can also be enclosed in (* and *) */
"(*" { 
  ++nested_comments;
  BEGIN(COMMENT); 
}

<COMMENT>{
  /* Patterns not followed by actions do nothing */
  
  [^*\n]*
  [^*\n]*\n  { ++curr_lineno; }
  "*"+[^*)\n]* 
  "*"+[^*)\n]*\n { ++curr_lineno; }
  "*"+")" {
    --nested_comments;
    if (nested_comments == 0)
      BEGIN(INITIAL);
  }
  <<EOF>> {
    cool_yylval.error_msg = "EOF in comment";
    BEGIN(INITIAL);
    return (ERROR);
  }
}

<TREAT_STR_ERROR>{
  \n {
    curr_lineno++;
    BEGIN(INITIAL);
  }

  \\\"

  \" { BEGIN(INITIAL); }
  
  .+ 
}

. {
  cool_yylval.error_msg = yytext;
  return (ERROR);
}

%%

int long_str_error()
{
  cool_yylval.error_msg = "String constant too long";
  BEGIN(TREAT_STR_ERROR);
  return (ERROR);
}

void read_char(char ch)
{
  if (string_buf_ptr - string_buf >= MAX_STR_CONST) {
    long_str_error();
  }
  *string_buf_ptr++ = ch;
}
