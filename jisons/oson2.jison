
%lex
KEY_ANNOTATION_SYMBOL       [\?]
VALUE_ANNOTATION_SYMBOL     [@]
DIGIT1to9                   [1-9]
DIGIT                       [0-9]
DIGITS                      (?:{DIGIT}+)
INT                         (?:{DIGIT1to9}{DIGITS}|{DIGIT}|"-"{DIGIT1to9}{DIGITS}|"-"{DIGIT})
FRAC                        (?:\.{DIGITS})
EXP                         (?:{E}{DIGITS})
E                           [eE][+-]?
HEX_DIGIT                   [0-9a-f]
UNESCAPED_CHAR_WITHOUT_AT   [ -!#-\?A-\[\]-~]
UNESCAPED_CHAR_WITHOUT_QM   [ -!#->@-\[\]-~]
UNESCAPED_CHAR_WITHOUT_BOTH [ -!#->A-\[\]-~]
UNESCAPED_CHAR_WITHOUT_BOTH_WS  [!#->A-\[\]-~]
ESCAPEDCHAR                 \\["\\bfnrt/]
ESCAPEDCHAR_WITHOUT_WS      \\["\\bf/]
UNICODECHAR                 \\u{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}
UNESCAPEDCHAR               [ -!#-\[\]-~]
CHAR                        {UNESCAPEDCHAR}|{ESCAPEDCHAR}|{UNICODECHAR}
CHARS                       {CHAR}+
MODIFIED_VALUE_CHAR         {UNESCAPED_CHAR_WITHOUT_AT}|{ESCAPEDCHAR}|{UNICODECHAR}
MODIFIED_KEY_CHAR           {UNESCAPED_CHAR_WITHOUT_QM}|{ESCAPEDCHAR}|{UNICODECHAR}
MODIFIED_BOTH_CHAR          {UNESCAPED_CHAR_WITHOUT_BOTH_WS}|{ESCAPEDCHAR_WITHOUT_WS}|{UNICODECHAR}
DBL_QUOTE                   ["]
ESCAPE_WS                   \\["\\rnt/]
SPACE                       [ ]
WSC                         {ESCAPE_WS}|{SPACE}
WS                          {WSC}+


%%
{VALUE_ANNOTATION_SYMBOL}                          return '@';
{KEY_ANNOTATION_SYMBOL}                          return '?';
{VALUE_ANNOTATION_SYMBOL}{VALUE_ANNOTATION_SYMBOL}    return '@@'
{KEY_ANNOTATION_SYMBOL}{KEY_ANNOTATION_SYMBOL}        return '??'
"{"                                            return '{'
"}"                                            return '}'
"["                                             return '['
"]"                                            return ']'
","                                            return ','
":"                                            return ':'
{WS}                                            return 'WS'
{MODIFIED_BOTH_CHAR}                             return 'MODIFIED_BOTH_CHAR';
{DBL_QUOTE}                                    return 'DBL_QUOTE'
\/(?:[^\/]|"\\/")*\/                           return 'REGEX'
[ \t\n]+                                    /* ignore whitespace */
/*.                                               return 'INVALID'*/
/lex

%token DBL_QUOTE
%token @ ? { } [ ] , : WS
%token MODIFIED_BOTH_CHAR
%token MODIFIED_CHAR
%token TRUE FALSE NULL
%left O_BEGIN O_END A_BEGIN A_END
%left COMMA
%left COLON

%start osonSchema
%%
osonSchema
    :osonElement
    {
       return $1;
    }
    ;
osonElement
    : WS osonValue WS
        {$$ = $2;}
    | WS osonValue
        {$$ = $2;}
    | osonValue WS
        {$$ = $1;}
    | osonValue
        {$$ = $1;}
    ;
osonValue
    :osonObject
    {
        $$ = $1;
    }
    |osonArray
    {
        $$ = $1;
    }
    |annotatedValue
    {
        $$ = $1;
    }
    ;
osonObject
    :'{' WS '}'
        {
            $$ = new yy.Node("object", undefined, []);
        }
    |'{' '}'
        {
            $$ = new yy.Node("object", undefined, []);
        }
    |'{' osonMembers '}'
        {
            $$ = new yy.Node("object", undefined, $2);
        }
    ;
osonArray
    :'[' WS ']'
        {
            $$ = new yy.Node("array", undefined, []);
        }
    |'[' ']'
        {
            $$ = new yy.Node("array", undefined, []);
        }
    |'[' osonElements ']'
        {
            $$ = new yy.Node("array", undefined, $2);
        }
    ;
annotatedValue
    :DBL_QUOTE closePart
        {
        //return something like:{
        //      "examples": "777",
        //      "osonAnnotation": "@Integer"
        //}
            $$ = $2;
        }
    ;
closePart
    :'@' '@' closePart
        {
            $$ = yy.Node.handleClosePart("examples",$1,$3);
        }
    |'@' osonAnnotation DBL_QUOTE
        {
            $$ = yy.Node.handleClosePart("annotation","@"+$2);
        }
    |singleModifiedValueChar closePart
        {
            $$ = yy.Node.handleClosePart("examples",$1,$2);
        }
    |DBL_QUOTE
        {
            $$ = '';
        }
    ;
singleModifiedValueChar
    :'?'
    {$$ = $1;}
    |normalChar
    {$$ = $1;}
    ;
osonAnnotation
    :singleModifiedValueChar normalChars
        {$$ = $1+$2;}
    ;
normalChars
    :normalChar normalChars
        {$$ = $1+$2;}
    |'@' normalChars
        {$$ = $1+$2;}
    |'?' normalChars
        {$$ = $1+$2;}
    |
        {$$ = '';}
    ;
normalChar
    :MODIFIED_BOTH_CHAR
    {$$ = $1;}
    |'{'
    {$$ = $1;}
    |'}'
    {$$ = $1;}
    |'['
    {$$ = $1;}
    |']'
    {$$ = $1;}
    |','
    {$$ = $1;}
    |':'
    {$$ = $1;}
    |WS
    {$$ = $1;}
    ;
osonMembers
    :osonMember ',' osonMembers
    {$$ = $3; $$.unshift($1);}
    |osonMember
    {$$ = [$1];}
    ;
osonElements
    :osonElement ',' osonElements
        {$$ = $3; $$.unshift($1);}
    |osonElement
        {$$ = [$1];}
    ;
osonMember
    :annotatedKey ':' osonElement
        {
           $$={key:$1,value:$3};
        }
    |WS annotatedKey WS ':' osonElement
        {
           $$={key:$2,value:$5};
        }
    |WS annotatedKey ':' osonElement
        {
           $$={key:$2,value:$4};
        }
    |annotatedKey WS ':' osonElement
        {
           $$={key:$1,value:$4};
        }
    ;
annotatedKey
    :DBL_QUOTE closeKey
    {
        $$ = $2;
    }
    ;
closeKey
    :DBL_QUOTE
        {
            $$ = '';
        }
    |singleModifiedKeyChar closeKey
        {
            $$ = yy.Node.handleCloseKey("key",$1,$2);
        }
    |'?' '?' closeKey
        {
            $$ = yy.Node.handleCloseKey("key",$1,$3);
        }
    |'?' DBL_QUOTE
        {
            $$ = yy.Node.handleCloseKey("optional",true);
        }
    ;
singleModifiedKeyChar
    :'@'
        {$$ = $1;}
    |normalChar
        {$$ = $1;}
    ;

