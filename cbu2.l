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
나누기 	{return(DIV); }
더하기	{return(ADD); }
빼기	{return(SUB); }
:=		{return(ASSGN); }
;		{return(STMTEND); }
시작	{return(START); }
끝		{return(END); }
출력	{return(PRINT); }
만약|만일	{return(IF); }
는|is	{return(IS); }
보다	{return(THEN); }
초과면|크다면|크면		{return(GT); }
미만이면|작다면|작으면	{return(LT); }
이상이면|크거나같으면|크거나같다면	{return(GE); }
이하면|작거나같으면|작거나같다면	{return(LE); }
같다면|같으면	{return(EQ); }
다르면|다르다면|틀리면|틀리다면 {return(NE); }
이다	{return(IFEND); }
"("		{return(OPT); }
")"		{return(CPT); }
{id}		{temp=insertsym(yytext); yylval=MakeNode(ID, temp); return(ID);}
{digit}+	{sscanf(yytext, "%d", &temp); yylval=MakeNode(NUM, temp); return(NUM);}
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