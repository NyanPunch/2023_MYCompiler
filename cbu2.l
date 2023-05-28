%{
#include <string.h>
#include "cbu2.h"
#define MAXSYM	100
#define	MAXSYMLEN	20
char symtbl[MAXSYM][MAXSYMLEN];
int lineno=1;
int insertsym();
int maxsym=0;
char s[MAXSYMLEN];
int temp;

%}
sp		[ \t]
ws		{sp}+
nl		\n
eletter	[A-Za-z]
hletter	[\xb0-\xfe][\xa0-\xfe]
letter	({eletter}|{hletter})
digit	[0-9]
id		{letter}({letter}|{digit})*
%%
{ws}	{/* do nothing */}
{nl}		{lineno++; }
곱하기 	{return(MUL); }
"*"		{return(MUL); }
나누기 	{return(DIV); }
"/"		{return(DIV); }
더하기	{return(ADD); }
"+"		{return(ADD); }
빼기	{return(SUB); }
"-"		{return(SUB); }
:=		{return(ASSGN); }
;		{return(STMTEND); }
시작	{return(START); }
끝		{return(END); }
출력	{return(PRINT); }
만약에|만일	{return(IF); }
if		{return(IF); }
은|는|is	{return(IS); }
보다|then	{return(THEN); }
이다|ifend	{return(IFEND); }
초과면|초과인		{return(GT); }
크다면|크면	|큰		{return(GT); }
">"					{return(GT); }
미만이면|미만인	{return(LT); }
작다면|작으면|작은	{return(LT); }
"<"					{return(LT); }
이상이면|이상인	{return(GE); }
크거나같으면|크거나같다면	{return(GE); }
">="				{return(GE); }
이하면|이하인		{return(LE); }
작거나같으면|작거나같다면	{return(LE); }
"<="				{return(LE); }
같다면|같으면|같은	{return(EQ); }
"=="				{return(EQ); }
다르면|다르다면|틀리면|틀리다면 {return(NE); }
"!="				{return(NE); }
동안	{return(DURING); }
반복한다	{return(DEND);}
"+="	{return(AA); }
"-="	{return(SA); }
"*="	{return(MA); }
"/="	{return(DA); }
"++"	{return(INC); }
"--"		{return(DEC);}
{id}		{temp=insertsym(yytext); yylval=MakeNode(ID, temp); return(ID);}
{digit}+		{sscanf(yytext, "%d", &temp); yylval=MakeNode(NUM, temp); return(NUM);}
.		{printf("invalid token %s\n", yytext); }
%%

int insertsym(s)
char *s;
{
int i;

	for(i=0;i<maxsym; i++) {
		if(strcmp(s, symtbl[i])==0) return(i);
		}
	if (i<MAXSYM-1) {
		strcpy(symtbl[maxsym],s);
		maxsym++;
		return(maxsym-1);
		}
	else
		{printf("symbol table overflow\n");}
	return(0);
}

yywrap() {}