/* part of objc2pp - an obj-c 2 preprocessor */

main()
{
	extern int yyparse();
	extern void scaninit(void);
#if 0
	extern int yydebug;
	yydebug=1;
#endif
	scaninit();
	return(yyparse());
}

