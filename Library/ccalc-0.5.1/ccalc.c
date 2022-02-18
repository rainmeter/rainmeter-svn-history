#include <stdio.h>
#include <string.h>
#include <sys/timeb.h>
#include "mparser.h"

#ifdef __WIN32__
#include <windows.h>
#define ftime _ftime
#endif /* __WIN32__ */

#define WITH_TEST 1

#ifdef WITH_TEST
/* multiarg test function  */
char* dummy( int paramcnt, double *args, hqStrMap *strparams, double *result );

char expr[] =
    "dummy(5) + CoS(PI+4) - round(25,-1) + LN(E**neG(2.5)) - (3/2) ^((1*2/3/4/*5*/))";
char funcnames[] =
    "DUMMY\000";
char* (*funcaddrs[])() = {
    &dummy };
#endif

hqStrMap* strmap;

const int repeats = 8;

char buffer[256];

char *translate( char *str )
{
#ifdef __WIN32__
    CharToOem( str, buffer );
    return buffer;
#else
    return str;
#endif
}

void printbin( int x )
{
    char *ch = buffer+40;
    *ch = '\0';
    *--ch = 'b';
    do {
	*--ch = '0' + (x & 1);
	x >>= 1;
    } while ( x );
    printf( ch );
}
            
int main( int argc, char **argv )
{
    char *ErrMsg, *expression;
    hqMathParser *parser;
    double result;
    int outbase = 0;

    if (argc < 2 || (strcmp( argv[1], "--help" )==0) ) {
	printf( "Usage: ccalc [--hex|--oct|--dec|--bin] <expression>\n" );
	printf( "    or ccalc --help\t- This text\n" );
#ifdef WITH_TEST
	printf( "    or ccalc --test\t- Test calculation speed\n" );
#endif
	return 1;
    }
    parser = MathParser_Create( NULL /*moreletters*/ );

#ifdef WITH_TEST
    strmap = Strmap_CreateFromChain( sizeof(void*), funcnames, funcaddrs );
    parser->ExtFunctions = strmap;

    if (strcmp( argv[1], "--test" )==0) {
	double cps;
	int i, msec;
	size_t time1, time2;
	struct timeb tb;
	ftime( (void*) &tb );
	time1 = tb.time * 1000 + tb.millitm;
        for (i=0; i<0xFFF*repeats; i++) {
	    ErrMsg = MathParser_Parse( parser, expr, &result );
	    if ( ErrMsg == NULL ) {
		if ((i & 0xFFF) == 0xFFF) {
	    	    printf( "." );
		    fflush( stdout );
		}
	    } else {
		puts( translate( ErrMsg ) );
	    	return 1;
	    }
        }
	ftime( (void*) &tb );
	time2 = tb.time * 1000 + tb.millitm;
	msec = (int)(time2 - time1);
	cps = (msec==0) ? -1 : (double)(0xFFF*repeats)*1000/(double)msec;
	printf( "\n%d calculations / %d millisec; %G c/s\n",
		0xFFF*repeats, msec, cps );

    } else
#endif
    if (strcmp( argv[1], "--bin" )==0) {
	expression = argv[2];
	outbase = 2;
	goto calc;
    } else if (strcmp( argv[1], "--oct" )==0) {
	expression = argv[2];
	outbase = 8;
	goto calc;
    } else if (strcmp( argv[1], "--dec" )==0) {
	expression = argv[2];
	outbase = 10;
	goto calc;
    } else if (strcmp( argv[1], "--hex" )==0) {
	expression = argv[2];
	outbase = 16;
	goto calc;
    } else {
	expression = argv[1];
calc:  	ErrMsg = MathParser_Parse( parser, expression, &result );
    	if ( ErrMsg == NULL )
	    switch (outbase) {
		case 0:
		    printf( "%.15G\n", result );
		    break;
		case 2:
		    printbin( (int)result );
		    break;
		case 8:
		    printf( "0%o\n", (int)result );
		    break;
		case 10:
		    printf( "%d\n", (int)result );
		    break;
		case 16:
		    printf( "0x%X\n", (int)result );
		    break;
	    }
    	else {
	    puts( translate( ErrMsg ) );
	    return 1;
	}
    }
    MathParser_Destroy( parser );
    StrMap_Destroy( strmap );
    return 0;
}

/* this function is completely for test purposes */

char* dummy( int paramcnt, double *args, hqStrMap *strparams, double *result )
{
    if (paramcnt>1)
	return "#Invalid parameters count!";

    if (paramcnt==0) {
	*result = 0.0;
	return NULL;
    }
    if (*args==DblNiN) { 
        int len;
	char *str = StrMap_GetString( strparams, 0, &len, NULL );
        fwrite( str, 1, len, stdout );
	puts("\n");
	return NULL;
    }
    *result = *args;
    return NULL;
}
