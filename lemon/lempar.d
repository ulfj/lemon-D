/* D language driver template for the LEMON parser generator.
** The author disclaims copyright to this source code.
*/

/* First off, code is included that follows the "include" declaration
** in the input grammar file.
*/

import std.stdio;
import core.stdc.stdlib;

/* Memory allocation routines used by the parser by defult
*/
struct DefaultAllocator {

    static void* alloc(size_t sz) {
        return core.stdc.stdlib.malloc(sz);
    }

    static void free(void* p) {
        core.stdc.stdlib.free(p);
    }

    static void* realloc(void* p, size_t sz) {
        return core.stdc.stdlib.realloc(p, sz);
    }
}

%%

alias ParseEx!(DefaultAllocator)	Parse;

class ParseEx(MT = DefaultAllocator) {

    /* Next is all token values, in a form suitable for use by makeheaders.
    ** This section will be null unless lemon is run with the -m switch.
    */

    /*
    ** These constants (all generated automatically by the parser generator)
    ** specify the various kinds of tokens (terminals) that the parser
    ** understands.
    **
    ** Each symbol here is a terminal symbol in the grammar.
    */

%%

    /* The next thing included is series of defines which control
    ** various aspects of the generated parser.
    **    YYCODETYPE         is the data type used for storing terminal
    **                       and nonterminal numbers. "ubyte" is used
    **                       if there are fewer than 250 terminals
    **                       and nonterminals.  "int" is used otherwise.
    **    YYNOCODE           is a number of type YYCODETYPE which corresponds
    **                       to no legal terminal or nonterminal number.  This
    **                       number is used to fill in empty slots of the hash
    **                       table.
    **    YYFALLBACK         If defined, this indicates that one or more tokens
    **                       have fall-back values which should be used if the
    **                       original value of the token will not parse.
    **    YYACTIONTYPE       is the data type used for storing terminal
    **                       and nonterminal numbers.  "ubyte" is
    **                       used if there are fewer than 250 rules and
    **                       states combined.  "int" is used otherwise.
    **    ParseTOKENTYPE     is the data type used for minor tokens given
    **                       directly to the parser from the tokenizer.
    **    YYMINORTYPE        is the data type used for all minor tokens.
    **                       This is typically a union of many types, one of
    **                       which is ParseTOKENTYPE.  The entry in the union
    **                       for base tokens is called "yy0".
    **    YYSTACKDEPTH       is the maximum depth of the parser's stack.  If
    **                       zero the stack is dynamically sized using realloc()
    **    YYNSTATE           the combined number of states.
    **    YYNRULE            the number of rules in the grammar
    **    YYERRORSYMBOL      is the code number of the error symbol.  If not
    **                       defined, then do no error processing.
    */

%%

    enum YY_NO_ACTION     = YYNSTATE + YYNRULE + 2;
    enum YY_ACCEPT_ACTION = YYNSTATE + YYNRULE + 1;
    enum YY_ERROR_ACTION  = YYNSTATE + YYNRULE;

    /* The yyzerominor constant is used to initialize instances of
    ** YYMINORTYPE objects to zero.
    */
    static immutable YYMINORTYPE yyzerominor = { 0 };

    /* Define the yytestcase() macro to be a no-op if is not already defined
    ** otherwise.
    **
    ** Applications can choose to define yytestcase() in the %include section
    ** to a macro that can assist in verifying code coverage.  For production
    ** code the yytestcase() macro should be turned off.  But it is useful
    ** for testing.
    */
    static if (!is(typeof(yytestcase))) {
        void yytestcase(int X) {
        }
    }

    /* Next are the tables used to determine what action to take based on the
    ** current state and lookahead token.  These tables are used to implement
    ** functions that take a state number and lookahead value and return an
    ** action integer.
    **
    ** Suppose the action integer is N.  Then the action is determined as
    ** follows
    **
    **   0 <= N < YYNSTATE                  Shift N.  That is, push the lookahead
    **                                      token onto the stack and goto state N.
    **
    **   YYNSTATE <= N < YYNSTATE+YYNRULE   Reduce by rule N-YYNSTATE.
    **
    **   N == YYNSTATE+YYNRULE              A syntax error has occurred.
    **
    **   N == YYNSTATE+YYNRULE+1            The parser accepts its input.
    **
    **   N == YYNSTATE+YYNRULE+2            No such action.  Denotes unused
    **                                      slots in the yy_action[] table.
    **
    ** The action table is constructed as a single large table named yy_action[].
    ** Given state S and lookahead X, the action is computed as
    **
    **      yy_action[ yy_shift_ofst[S] + X ]
    **
    ** If the index value yy_shift_ofst[S]+X is out of range or if the value
    ** yy_lookahead[yy_shift_ofst[S]+X] is not equal to X or if yy_shift_ofst[S]
    ** is equal to YY_SHIFT_USE_DFLT, it means that the action is not in the table
    ** and that yy_default[S] should be used instead.
    **
    ** The formula above is for computing the action when the lookahead is
    ** a terminal symbol.  If the lookahead is a non-terminal (as occurs after
    ** a reduce action) then the yy_reduce_ofst[] array is used in place of
    ** the yy_shift_ofst[] array and YY_REDUCE_USE_DFLT is used in place of
    ** YY_SHIFT_USE_DFLT.
    **
    ** The following are the tables generated in this section:
    **
    **  yy_action[]        A single table containing all actions.
    **  yy_lookahead[]     A table containing the lookahead for each entry in
    **                     yy_action.  Used to detect hash collisions.
    **  yy_shift_ofst[]    For each state, the offset into yy_action for
    **                     shifting terminals.
    **  yy_reduce_ofst[]   For each state, the offset into yy_action for
    **                     shifting non-terminals after a reduce.
    **  yy_default[]       Default action for each state.
    */

%%

    /* The next table maps tokens into fallback tokens.  If a construct
    ** like the following:
    **
    **      %fallback ID X Y Z.
    **
    ** appears in the grammar, then ID becomes a fallback token for X, Y,
    ** and Z.  Whenever one of the tokens X, Y, or Z is input to the parser
    ** but it does not parse, the type of the token is changed to ID and
    ** the parse is retried before an error is thrown.
    */

    static if (YYFALLBACK == true) {
        static immutable YYCODETYPE yyFallback[] = {
%%
        };
    } /* YYFALLBACK */

    /* The following structure represents a single element of the
    ** parser's stack.  Information stored includes:
    **
    **   +  The state number for the parser at this level of the stack.
    **
    **   +  The value of the token stored at this level of the stack.
    **      (In other words, the "major" token.)
    **
    **   +  The semantic value stored at this level of the stack.  This is
    **      the information used by the action routines in the grammar.
    **      It is sometimes called the "minor" token.
    */

    struct yyStackEntry {
        YYACTIONTYPE stateno;  /* The state-number */
        YYCODETYPE major;      /* The major token value. This is the code number
		                          for the token at this stack level */
        YYMINORTYPE minor;     /* The user-supplied minor token value.  This
		                          is the value of the token  */
    }

    /* The state of the parser is completely contained in an instance of
    ** the following structure
    */
    struct yyParser {
        int yyidx;                    /* Index of top element in stack */
        static if (is(typeof(YYTRACKMAXSTACKDEPTH) == enum)) {
            int yyidxMax;             /* Maximum value of yyidx */
        }
        int yyerrcnt;                 /* Shifts left before out of the error */
        static if (YYSTACKDEPTH <= 0) {
            int yystksz;                  /* Current side of the stack */
            yyStackEntry *yystack;        /* The parser's stack */
        } else {
            yyStackEntry yystack[YYSTACKDEPTH];  /* The parser's stack */
        }
    }

    yyParser parser_;

    debug {
        std.stdio.File* yyTraceFILE = null;
        string yyTracePrompt;

        /*
        ** Turn parser tracing on by giving a stream to which to write the trace
        ** and a prompt to preface each trace message.  Tracing is turned off
        ** by making either argument NULL
        **
        ** Inputs:
        ** <ul>
        ** <li> A FILE* to which trace output should be written.
        **      If NULL, then tracing is turned off.
        ** <li> A prefix string written at the beginning of every
        **      line of trace output.  If NULL, then tracing is
        **      turned off.
        ** </ul>
        **
        ** Outputs:
        ** None.
        */
        void ParseTrace(std.stdio.File* TraceFILE, string zTracePrompt) {
            yyTraceFILE = TraceFILE;
            yyTracePrompt = zTracePrompt;
            if (yyTraceFILE == null)
                yyTracePrompt = string();
            else if (yyTracePrompt == 0)
                yyTraceFILE = null;
        }

        /* For tracing shifts, the names of all terminals and nonterminals
        ** are required.  The following table supplies these names
        */

        static immutable string[] yyTokenName = {
%%
        };

        /* For tracing reduce actions, the names of all rules are required.
        */

        static immutable string[] yyRuleName[] = {
%%
        };
    } // debug


    static if (YYSTACKDEPTH <= 0) {
        /* Try to increase the size of the parser stack.
        */
        private void yyGrowStack() {
            int newSize = parser_.yystksz*2 + 100;
            yyStackEntry* pNew = cast(yyStackEntry*)MT.realloc(parser_.yystack, newSize * sizeof(pNew[0]));

            if (pNew !is null) {
                parser_.yystack = pNew;
                parser_.yystksz = newSize;
                debug if (yyTraceFILE !is null) {
                    yyTraceFILE.writef("%sStack grows to %d entries!\n", yyTracePrompt, p.yystksz);
                }
            }
        }
    } // YYSTACKDEPTH <= 0

    /*
    ** This function constructs a new parser.
    */

    this() {
        parser_.yyidx = -1;
        static if (is(typeof(YYTRACKMAXSTACKDEPTH) == enum)) {
            parser_.yyidxMax = 0;
        }
        static if (YYSTACKDEPTH<=0) {
            parser_.yystack = NULL;
            parser_.yystksz = 0;
            yyGrowStack();
        }
    }

    /* The following function deletes the value associated with a
    ** symbol.  The symbol can be either a terminal or nonterminal.
    ** "yymajor" is the symbol code, and "yypminor" is a pointer to
    ** the value.
    */
    private void yy_destructor(
        YYCODETYPE yymajor,     /* Type code for object to destroy */
        YYMINORTYPE *yypminor   /* The object to be destroyed */
    ) {
        switch (yymajor) {
            /* Here is inserted the actions which take place when a
            ** terminal or non-terminal is destroyed.  This can happen
            ** when the symbol is popped from the stack during a
            ** reduce or during error processing or when a parser is
            ** being destroyed before it is finished parsing.
            **
            ** Note: during a reduce, the only symbols destroyed are those
            ** which appear on the RHS of the rule, but which are not used
            ** inside the C code.
            */
%%
        default:
            break;   /* If no destructor action specified: do nothing */
        }
    }

    /*
    ** Pop the parser's stack once.
    **
    ** If there is a destructor routine associated with the token which
    ** is popped from the stack, then call it.
    **
    ** Return the major token number for the symbol popped.
    */
    private int yy_pop_parser_stack() {
        YYCODETYPE yymajor;
        yyStackEntry* yytos = &parser_.yystack[parser_.yyidx];
        if (parser_.yyidx < 0)
            return 0;
        debug if (yyTraceFILE && parser_.yyidx >= 0) {
            yyTraceFILE.writef("%sPopping %s\n", yyTracePrompt, yyTokenName[yytos.major]);
        }
        yymajor = yytos.major;
        yy_destructor(yymajor, &yytos.minor);
        parser_.yyidx--;
        return yymajor;
    }

    /*
    ** Destroy the parser.  Destructors are all called for
    ** all stack elements before shutting the parser down.
    */

    ~this() {
        while (parser_.yyidx >= 0)
            yy_pop_parser_stack();
        static if (YYSTACKDEPTH <= 0) {
            MT.free(parser_.yystack);
        }
    }

    /*
    ** Return the peak depth of the stack for a parser.
    */
    static if (is(typeof(YYTRACKMAXSTACKDEPTH) == enum)) {
        int ParseStackPeak() {
            return parser_.yyidxMax;
        }
    }

    /*
    ** Find the appropriate action for a parser given the terminal
    ** look-ahead token iLookAhead.
    **
    ** If the look-ahead token is YYNOCODE, then check to see if the action is
    ** independent of the look-ahead.  If it is, return the action, otherwise
    ** return YY_NO_ACTION.
    */
    private int yy_find_shift_action(YYCODETYPE iLookAhead) { /* The look-ahead token */
        int i;
        int stateno = parser_.yystack[parser_.yyidx].stateno;

        if (stateno > YY_SHIFT_COUNT || (i = yy_shift_ofst[stateno]) == YY_SHIFT_USE_DFLT) {
            return yy_default[stateno];
        }
        debug assert(iLookAhead != YYNOCODE);
        i += iLookAhead;
        if (i < 0 || i >= YY_ACTTAB_COUNT || yy_lookahead[i]!=iLookAhead) {
            if (iLookAhead > 0) {
                static if (is(typeof(YYFALLBACK) == enum)) {
                    YYCODETYPE iFallback;            /* Fallback token */
                    if (iLookAhead < yyFallback.length && (iFallback = yyFallback[iLookAhead]) != 0) {
                        debug if (yyTraceFILE) {
                            yyTraceFILE.writef("%sFALLBACK %s => %s\n", yyTracePrompt, yyTokenName[iLookAhead], yyTokenName[iFallback]);
                        }
                        return yy_find_shift_action(iFallback);
                    }
                }
                static if (is(typeof(YYWILDCARD) == enum)) {{
                        int j = i - iLookAhead + YYWILDCARD;
                        bool f = true;
                        static if (YY_SHIFT_MIN + YYWILDCARD < 0) {
                            f = j >= 0;
                        }
                        static if (YY_SHIFT_MAX + YYWILDCARD >= YY_ACTTAB_COUNT) {
                            f = f && (j < YY_ACTTAB_COUNT);
                        }
                        f = f && (yy_lookahead[j] == YYWILDCARD);
                        if (f) {
                            debug if (yyTraceFILE) {
                                yyTraceFILE.writef("%sWILDCARD %s => %s\n", yyTracePrompt, yyTokenName[iLookAhead], yyTokenName[YYWILDCARD]);
                            }
                            return yy_action[j];
                        }
                    }
                }
            }
            return yy_default[stateno];
        } else {
            return yy_action[i];
        }
    }

    /*
    ** Find the appropriate action for a parser given the non-terminal
    ** look-ahead token iLookAhead.
    **
    ** If the look-ahead token is YYNOCODE, then check to see if the action is
    ** independent of the look-ahead.  If it is, return the action, otherwise
    ** return YY_NO_ACTION.
    */

    private int yy_find_reduce_action(
        int stateno,              /* Current state number */
        YYCODETYPE iLookAhead     /* The look-ahead token */
    ) {
        int i;
        static if (is(typeof(YYERRORSYMBOL) == enum)) {
            if (stateno > YY_REDUCE_COUNT) {
                return yy_default[stateno];
            }
        } else {
            debug assert(stateno <= YY_REDUCE_COUNT);
        }
        i = yy_reduce_ofst[stateno];
        debug assert(i != YY_REDUCE_USE_DFLT);
        debug assert(iLookAhead != YYNOCODE);
        i += iLookAhead;
        static if (is(typeof(YYERRORSYMBOL) == enum)) {
            if (i < 0 || i >= YY_ACTTAB_COUNT || yy_lookahead[i] != iLookAhead) {
                return yy_default[stateno];
            }
        } else {
            debug assert(i >= 0 && i < YY_ACTTAB_COUNT);
            debug assert(yy_lookahead[i] == iLookAhead);
        }
        return yy_action[i];
    }

    /*
    ** The following routine is called if the stack overflows.
    */
    private void yyStackOverflow(YYMINORTYPE *yypMinor) {
        parser_.yyidx--;
        debug if (yyTraceFILE) {
            yyTraceFILE.writef("%sStack Overflow!\n", yyTracePrompt);
        }
        while (parser_.yyidx>=0)
            yy_pop_parser_stack();
        /* Here code is inserted which will execute if the parser
        ** stack every overflows */
%%
    }

    /*
    ** Perform a shift action.
    */
    private void yy_shift(
        int yyNewState,               /* The new state to shift in */
        int yyMajor,                  /* The major token to shift in */
        YYMINORTYPE *yypMinor         /* Pointer to the minor token to shift in */
    ) {
        yyStackEntry *yytos;
        parser_.yyidx++;
        static if (is(typeof(YYTRACKMAXSTACKDEPTH) == enum)) {
            if (parser_.yyidx > parser_.yyidxMax) {
                parser_.yyidxMax = parser_.yyidx;
            }
        }
        static if (YYSTACKDEPTH > 0) {
            if (parser_.yyidx >= YYSTACKDEPTH) {
                yyStackOverflow(yypMinor);
                return;
            }
        } else {
            if (parser_.yyidx >= parser_.yystksz) {
                yyGrowStack();
                if (parser_.yyidx >= parser_.yystksz) {
                    yyStackOverflow(yypMinor);
                    return;
                }
            }
        }
        yytos = &parser_.yystack[parser_.yyidx];
        yytos.stateno = cast(YYACTIONTYPE)yyNewState;
        yytos.major = cast(YYCODETYPE)yyMajor;
        yytos.minor = *yypMinor;
        debug if (yyTraceFILE && parser_.yyidx > 0) {
            int i;
            yyTraceFILE.writef("%sShift %d\n", yyTracePrompt, yyNewState);
            yyTraceFILE.writef("%sStack:", yyTracePrompt);
            for (i = 1; i <= parser_.yyidx; i++)
                yyTraceFILE.writef(" %s",yyTokenName[parser_.yystack[i].major]);
            yyTraceFILE.writef("\n");
        }
    }

    /* The following table contains information about every rule that
    ** is used during the reduce.
    */
    struct RuleInfo {
        YYCODETYPE lhs;       /* Symbol on the left-hand side of the rule */
        ubyte nrhs;			/* Number of right-hand side symbols in the rule */
    }
	immutable RuleInfo[] yyRuleInfo = [
%%
    ];

    /*
    ** Perform a reduce action and the shift that must immediately
    ** follow the reduce.
    */
    private void yy_reduce(
        int yyruleno                 /* Number of the rule by which to reduce */
    ) {
        int yygoto;                     /* The next state */
        int yyact;                      /* The next action */
        YYMINORTYPE yygotominor;        /* The LHS of the rule reduced */
        yyStackEntry *yymsp;            /* The top of the parser's stack */
        int yysize;                     /* Amount to pop the stack */

        yymsp = &parser_.yystack[parser_.yyidx];
        debug if (yyTraceFILE && yyruleno >= 0 && yyruleno < yyRuleName.length) {
            yyTraceFILE.writef("%sReduce [%s].\n", yyTracePrompt, yyRuleName[yyruleno]);
        }

        switch (yyruleno) {
            /* Beginning here are the reduction cases.  A typical example
            ** follows:
            **   case 0:
            **  #line <lineno> <grammarfile>
            **     { ... }           // User supplied code
            **  #line <lineno> <thisfile>
            **     break;
            */
%%
        }

        yygoto = yyRuleInfo[yyruleno].lhs;
        yysize = yyRuleInfo[yyruleno].nrhs;
        parser_.yyidx -= yysize;
        yyact = yy_find_reduce_action(yymsp[-yysize].stateno, cast(YYCODETYPE)yygoto);
        if (yyact < YYNSTATE) {

            /* If we are not debugging and the reduce action popped at least
            ** one element off the stack, then we can push the new element back
            ** onto the stack here, and skip the stack overflow test in yy_shift().
            ** That gives a significant speed improvement. */

            debug {
                yy_shift(yyact,yygoto,&yygotominor);
            }
            else {
                if (yysize) {
                    parser_.yyidx++;
                    yymsp -= yysize-1;
                    yymsp.stateno = cast(YYACTIONTYPE)yyact;
                    yymsp.major = cast(YYCODETYPE)yygoto;
                    yymsp.minor = yygotominor;
                } else {
                    yy_shift(yyact,yygoto,&yygotominor);
                }
            }
        } else {
            debug assert(yyact == YYNSTATE + YYNRULE + 1);
            yy_accept();
        }
    }

    /*
    ** The following code executes when the parse fails
    */
    static if (!is(typeof(YYNOERRORRECOVERY) == enum)) {
        private void yy_parse_failed() {

            debug if (yyTraceFILE) {
                yyTraceFILE.writef("%sFail!\n", yyTracePrompt);
            }

            while (parser_.yyidx >= 0)
                yy_pop_parser_stack();

            /* Here code is inserted which will be executed whenever the
            ** parser fails */

%%
        }
    }

    /*
    ** The following code executes when a syntax error first occurs.
    */
    private void yy_syntax_error(
        int yymajor,                   /* The major type of the error token */
        YYMINORTYPE yyminor            /* The minor type of the error token */
    ) {
        alias yyminor.yy0 TOKEN;
%%
    }

    /*
    ** The following is executed when the parser accepts
    */
    private void yy_accept() {

        debug if (yyTraceFILE) {
            yyTraceFILE.writef("%sAccept!\n", yyTracePrompt);
        }

        while (parser_.yyidx >= 0)
            yy_pop_parser_stack();

        /* Here code is inserted which will be executed whenever the
        ** parser accepts */

%%
    }

    /* The main parser program.
    ** The first argument is a pointer to a structure obtained from
    ** "ParseAlloc" which describes the current state of the parser.
    ** The second argument is the major token number.  The third is
    ** the minor token.  The fourth optional argument is whatever the
    ** user wants (and specified in the grammar) and is available for
    ** use by the action routines.
    **
    ** Inputs:
    ** <ul>
    ** <li> A pointer to the parser (an opaque structure.)
    ** <li> The major token number.
    ** <li> The minor token number.
    ** <li> An option argument of a grammar-specified type.
    ** </ul>
    **
    ** Outputs:
    ** None.
    */
    void parse(
        int yymajor,                 /* The major token code number */
        ParseTOKENTYPE yyminor       /* The value for the token */
    ) {
        YYMINORTYPE yyminorunion;
        int yyact;            /* The parser action. */
        int yyendofinput;     /* True if we are at the end of input */

        static if (is(typeof(YYERRORSYMBOL) == enum)) {
            int yyerrorhit = 0;   /* True if yymajor has invoked an error */
        }

        /* (re)initialize the parser, if necessary */
        if (parser_.yyidx < 0) {
            static if (YYSTACKDEPTH <= 0) {
                if (parser_.yystksz <= 0) {
                    /*memset(&yyminorunion, 0, sizeof(yyminorunion));*/
                    yyminorunion = yyzerominor;
                    yyStackOverflow(&yyminorunion);
                    return;
                }
            }
            parser_.yyidx = 0;
            parser_.yyerrcnt = -1;
            parser_.yystack[0].stateno = 0;
            parser_.yystack[0].major = 0;
        }
        yyminorunion.yy0 = yyminor;
        yyendofinput = (yymajor == 0);

        debug if (yyTraceFILE) {
            yyTraceFILE.writef("%sInput %s\n",yyTracePrompt,yyTokenName[yymajor]);
        }

        do {
            yyact = yy_find_shift_action(cast(YYCODETYPE)yymajor);
            if (yyact < YYNSTATE) {
                debug assert(!yyendofinput);  /* Impossible to shift the $ token */
                yy_shift(yyact, yymajor, &yyminorunion);
                parser_.yyerrcnt--;
                yymajor = YYNOCODE;
            } else if (yyact < YYNSTATE + YYNRULE) {
                yy_reduce(yyact - YYNSTATE);
            } else {
                debug assert(yyact == YY_ERROR_ACTION);

                debug if (yyTraceFILE) {
                    fprintf(yyTraceFILE,"%sSyntax Error!\n", yyTracePrompt);
                }

                static if (is(typeof(YYERRORSYMBOL) == enum)) {

                    /* A syntax error has occurred.
                    ** The response to an error depends upon whether or not the
                    ** grammar defines an error token "ERROR".
                    **
                    ** This is what we do if the grammar does define ERROR:
                    **
                    **  * Call the %syntax_error function.
                    **
                    **  * Begin popping the stack until we enter a state where
                    **    it is legal to shift the error symbol, then shift
                    **    the error symbol.
                    **
                    **  * Set the error count to three.
                    **
                    **  * Begin accepting and shifting new tokens.  No new error
                    **    processing will occur until three tokens have been
                    **    shifted successfully.
                    **
                    */

                    if (parser_.yyerrcnt < 0) {
                        yy_syntax_error(yymajor, yyminorunion);
                    }

                    int yymx = parser_.yystack[parser_.yyidx].major;
                    if (yymx == YYERRORSYMBOL || yyerrorhit) {

                        debug if (yyTraceFILE) {
                            yyTraceFILE.writef("%sDiscard input token %s\n", yyTracePrompt,yyTokenName[yymajor]);
                        }

                        yy_destructor(cast(YYCODETYPE)yymajor, &yyminorunion);
                        yymajor = YYNOCODE;
                    } else {
                        while (parser_.yyidx >= 0 && yymx != YYERRORSYMBOL && (yyact = yy_find_reduce_action(parser_.yystack[parser_.yyidx].stateno, YYERRORSYMBOL)) >= YYNSTATE) {
                            yy_pop_parser_stack();
                        }
                        if (parser_.yyidx < 0 || yymajor == 0) {
                            yy_destructor(cast(YYCODETYPE)yymajor, &yyminorunion);
                            yy_parse_failed();
                            yymajor = YYNOCODE;
                        } else if (yymx != YYERRORSYMBOL) {
                            YYMINORTYPE u2;
                            u2.YYERRSYMDT = 0;
                            yy_shift(yyact, YYERRORSYMBOL, &u2);
                        }
                    }
                    parser_.yyerrcnt = 3;
                    yyerrorhit = 1;
                } else if (is(typeof(YYNOERRORRECOVERY) == enum)) {

                    /* If the YYNOERRORRECOVERY macro is defined, then do not attempt to
                    ** do any kind of error recovery.  Instead, simply invoke the syntax
                    ** error routine and continue going as if nothing had happened.
                    **
                    ** Applications can set this macro (for example inside %include) if
                    ** they intend to abandon the parse upon the first syntax error seen.
                    */
                    yy_syntax_error(yymajor, yyminorunion);
                    yy_destructor(cast(YYCODETYPE)yymajor, &yyminorunion);
                    yymajor = YYNOCODE;
                } else {
                    /* This is what we do if the grammar does not define ERROR:
                    **
                    **  * Report an error message, and throw away the input token.
                    **
                    **  * If the input token is $, then fail the parse.
                    **
                    ** As before, subsequent error messages are suppressed until
                    ** three input tokens have been successfully shifted.
                    */
                    if (parser_.yyerrcnt <= 0) {
                        yy_syntax_error(yymajor, yyminorunion);
                    }
                    parser_.yyerrcnt = 3;
                    yy_destructor(cast(YYCODETYPE)yymajor, &yyminorunion);
                    if (yyendofinput) {
                        yy_parse_failed();
                    }
                    yymajor = YYNOCODE;
                }
            }
        } while (yymajor != YYNOCODE && parser_.yyidx >= 0);
    }

} // struct Parse

