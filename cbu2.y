%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DEBUG	0

#define	 MAXSYM	100
#define	 MAXSYMLEN	20
#define	 MAXTSYMLEN	15
#define	 MAXTSYMBOL	MAXSYM/2

#define STMTLIST 500

typedef struct nodeType {
	int token;
	int tokenval;
	struct nodeType *son;
	struct nodeType *brother;
	} Node;

#define YYSTYPE Node*
	
int tsymbolcnt=0;
int errorcnt=0;

int cnt=0;		//스택에 삽입할 번호
int top=-1;		//스택의 탑표시
int stack[1000];	//LABEL에 사용

FILE *yyin;
FILE *fp;

extern char symtbl[MAXSYM][MAXSYMLEN];
extern int maxsym;
extern int lineno;

void DFSTree(Node*);
Node * MakeOPTree(int, Node*, Node*);
Node * MakeNode(int, int);
Node * MakeListTree(Node*, Node*);
void codegen(Node* );
void prtcode(int, int);

void	dwgen();
int	gentemp();
void	assgnstmt(int, int);
void	numassgn(int, int);
void	addstmt(int, int, int);
void	substmt(int, int, int);
int		insertsym(char *);

void Push(int num)
{
	stack[++top] = num;
}
void Pop()
{
	top--;
}
%}

%token	ADD SUB MUL DIV PRINT GT LT GE LE EQ NE ASSGN ID NUM STMTEND START END ID2
%token	IF IS THEN IFEND AA SA MA DA INC DEC ID3
%token	DURING DEND REPEAT

%%
program	: START stmt_list END	{ if (errorcnt==0) {codegen($2); dwgen();} }
		;

stmt_list: 	stmt_list stmt 	{$$=MakeListTree($1, $2);}
		|	stmt			{$$=MakeListTree(NULL, $1);}
		| 	error STMTEND	{ errorcnt++; yyerrok;}
		;

stmt	: 	ID ASSGN expr STMTEND	{$1->token = ID2; $$=MakeOPTree(ASSGN, $1, $3);}
		|	PRINT factor STMTEND		{$$=MakeOPTree(PRINT, $2, NULL);}
		|	IF condition stmt_list IFEND	{$$=MakeOPTree(IF, $2, $3); }
		|	condition DURING stmt_list DEND	{$$=MakeOPTree(DURING, $1, $3); }
		|	ID INC STMTEND	{$1->token = ID3; $$=MakeOPTree(INC, $1, NULL);}
		|	ID DEC STMTEND	{$1->token = ID3; $$=MakeOPTree(DEC, $1, NULL);}
		|	ID AA expr STMTEND	{$1->token = ID3; $$=MakeOPTree(AA, $1, $3);}
		|	ID SA expr STMTEND	{$1->token = ID3; $$=MakeOPTree(SA, $1, $3);}
		|	ID MA expr STMTEND	{$1->token = ID3; $$=MakeOPTree(MA, $1, $3);}
		|	ID DA expr STMTEND	{$1->token = ID3; $$=MakeOPTree(DA, $1, $3);}
		;

condition	:	expr IS expr THEN EQ	{$$=MakeOPTree(EQ, $1, $3); }
			|	expr IS expr THEN NE	{$$=MakeOPTree(NE, $1, $3); }
			|	expr IS expr THEN GT	{$$=MakeOPTree(GT, $1, $3); }
			|	expr IS expr THEN LT	{$$=MakeOPTree(LT, $1, $3); }
			|	expr IS expr THEN GE	{$$=MakeOPTree(GE, $1, $3); }
			|	expr IS expr THEN LE	{$$=MakeOPTree(LE, $1, $3); }
			;

expr	: 	expr ADD term		{ $$=MakeOPTree(ADD, $1, $3); }
		|	expr SUB term		{ $$=MakeOPTree(SUB, $1, $3); }
		|	term
		;

term	:	term MUL factor 	{ $$=MakeOPTree(MUL, $1, $3); }
		|	term DIV factor		{ $$=MakeOPTree(DIV, $1, $3); }
		|	factor
		;

factor	:	ID		{ /* ID node is created in lex */ }
		|	NUM		{ /* NUM node is created in lex */ }
		;


%%
int main(int argc, char *argv[]) 
{
	printf("\nsample CBU compiler v2.0\n");
	printf("(C) Copyright by Jae Sung Lee (jasonlee@cbnu.ac.kr), 2022.\n");
	
	if (argc == 2)
		yyin = fopen(argv[1], "r");
	else {
		printf("Usage: cbu2 inputfile\noutput file is 'a.asm'\n");
		return(0);
		}
		
	fp=fopen("a.asm", "w");
	
	yyparse();
	
	fclose(yyin);
	fclose(fp);

	if (errorcnt==0) 
		{ printf("Successfully compiled. Assembly code is in 'a.asm'.\n");}
}

yyerror(s)
char *s;
{
	printf("%s (line %d)\n", s, lineno);
}

Node * MakeOPTree(int op, Node* operand1, Node* operand2)
{
Node * newnode;

	newnode = (Node *)malloc(sizeof (Node));
	newnode->token = op;
	newnode->tokenval = op;
	newnode->son = operand1;
	newnode->brother = NULL;
	operand1->brother = operand2;
	return newnode;
}

Node * MakeNode(int token, int operand)
{
Node * newnode;

	newnode = (Node *) malloc(sizeof (Node));
	newnode->token = token;
	newnode->tokenval = operand; 
	newnode->son = newnode->brother = NULL;
	return newnode;
}

Node * MakeListTree(Node* operand1, Node* operand2)
{
Node * newnode;
Node * node;

	if (operand1 == NULL){
		newnode = (Node *)malloc(sizeof (Node));
		newnode->token = newnode-> tokenval = STMTLIST;
		newnode->son = operand2;
		newnode->brother = NULL;
		return newnode;
		}
	else {
		node = operand1->son;
		while (node->brother != NULL) node = node->brother;
		node->brother = operand2;
		return operand1;
		}
}

void codegen(Node * root)
{
	DFSTree(root);
}

void DFSTree(Node * n)
{
	if (n==NULL) return;
	
   	if (n->token == DURING)	//반복문 시작위치
		fprintf(fp, "LABEL LOOP%d\n", cnt+1);

	DFSTree(n->son);
	prtcode(n->token, n->tokenval);
	DFSTree(n->brother);
	
}

void prtcode(int token, int val)
{
	switch (token) {
	case ID:
		fprintf(fp,"RVALUE %s\n", symtbl[val]);
		break;
	case ID2:
		fprintf(fp, "LVALUE %s\n", symtbl[val]);
		break;
	case ID3:	//증감 및 할당연산시 사용
		fprintf(fp, "LVALUE %s\n", symtbl[val]);
		fprintf(fp,"RVALUE %s\n", symtbl[val]);
		break;
	case NUM:
		fprintf(fp, "PUSH %d\n", val);
		break;
	case ADD:
		fprintf(fp, "+\n");
		break;
	case SUB:
		fprintf(fp, "-\n");
		break;
	case ASSGN:
		fprintf(fp, ":=\n");
		break;
	case MUL:	//곱하기
		fprintf(fp, "*\n");
		break;
	case DIV:	//나누기
		fprintf(fp, "/\n");
		break;
	case PRINT:	//출력
		fprintf(fp, "OUTNUM\n");
		break;
	case IF:		//만일
      	fprintf(fp, "LABEL OUT%d\n", stack[top]);
		Pop();
		break;
	case EQ:	//같다면
		cnt++; Push(cnt);
      	fprintf(fp, "-\n");
      	fprintf(fp, "GOTRUE OUT%d\n", stack[top]);
		break;
	case NE:	//다르면 다르다면
		cnt++; Push(cnt);
      	fprintf(fp, "-\n");
      	fprintf(fp, "GOFALSE OUT%d\n", stack[top]);
		break;
	case GT:	//초과면 크다면
		cnt++; Push(cnt);
		fprintf(fp, "-\n");
		fprintf(fp, "COPY\n");
		fprintf(fp, "GOMINUS OUT%d\n", stack[top]);
		fprintf(fp, "GOFALSE OUT%d\n", stack[top]);
		break;
	case LT:		//미만이면 작다면
		cnt++; Push(cnt);
		fprintf(fp, "-\n");
		fprintf(fp, "COPY\n");
		fprintf(fp, "GOPLUS OUT%d\n", stack[top]);
		fprintf(fp, "GOFALSE OUT%d\n", stack[top]);
		break;
	case GE:	//이상이면 크거나같다면
		cnt++;	Push(cnt);
		fprintf(fp, "-\n");
		fprintf(fp, "GOMINUS OUT%d\n", stack[top]);
		break;
	case LE:		//이하면 작거나같으면
		cnt++;	Push(cnt);
		fprintf(fp, "-\n");
		fprintf(fp, "GOPLUS OUT%d\n", stack[top]);
		break;
	case AA:	//	+=
		fprintf(fp, "+\n");
		fprintf(fp, ":=\n");
		break;
	case SA:	//	-=
		fprintf(fp, "-\n");
		fprintf(fp, ":=\n");
		break;
	case MA:	//	*=
		fprintf(fp, "*\n");
		fprintf(fp, ":=\n");
		break;
	case DA:	//	/=
		fprintf(fp, "/\n");
		fprintf(fp, ":=\n");
		break;
	
	case INC:		//증가++
		fprintf(fp, "PUSH 1\n");
		fprintf(fp, "+\n");
		fprintf(fp, ":=\n");
		break;
	case DEC:		//감소--
		fprintf(fp, "PUSH 1\n");
		fprintf(fp, "-\n");
		fprintf(fp, ":=\n");
		break;
	case DURING:	//~동안
		fprintf(fp, "GOTO LOOP%d\n", stack[top]);
		fprintf(fp, "LABEL OUT%d\n", stack[top]);
		Pop();
		break;
	case STMTLIST:
	default:
		break;
	};
}


/*
int gentemp()
{
char buffer[MAXTSYMLEN];
char tempsym[MAXSYMLEN]="TTCBU";

	tsymbolcnt++;
	if (tsymbolcnt > MAXTSYMBOL) printf("temp symbol overflow\n");
	itoa(tsymbolcnt, buffer, 10);
	strcat(tempsym, buffer);
	return( insertsym(tempsym) ); // Warning: duplicated symbol is not checked for lazy implementation
}
*/
void dwgen()
{
int i;
	fprintf(fp, "HALT\n");
	fprintf(fp, "$ -- END OF EXECUTION CODE AND START OF VAR DEFINITIONS --\n");

// Warning: this code should be different if variable declaration is supported in the language 
	for(i=0; i<maxsym; i++) 
		fprintf(fp, "DW %s\n", symtbl[i]);
	fprintf(fp, "END\n");
}
