
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
{MODIFIED_BOTH_CHAR}                             return 'MODIFIED_BOTH_CHAR';
{DBL_QUOTE}                                    return 'DBL_QUOTE'
\/(?:[^\/]|"\\/")*\/                           return 'REGEX'
[ \t\n]+                                    /* ignore whitespace */
/*.                                               return 'INVALID'*/
/lex

%token DBL_QUOTE
%token '@' '?' '{' '}' '[' ']' ',' ':'
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
    : wsc osonValue wsc
        {$$ = $2;}
    | wsc osonValue
        {$$ = $2;}
    | osonValue wsc
        {$$ = $1;}
    | osonValue
        {$$ = $1;}
    ;
osonValue
    :osonObject
    {
        $$ = $1
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
    :'{' wsc '}'
        {
            $$ = "osonObject:{EMPTY}";
        }
    |'{' '}'
        {
            $$ = "osonObject:{EMPTY}";
        }
    |'{' osonMembers '}'
        {
            $$ = $2;
        }
    ;
osonArray
    :'[' wsc ']'
        {
            $$ = `ARRAY:[EMPTY]`;
        }
    |'[' ']'
        {
            $$ = `ARRAY:[EMPTY]`;
        }
    |'[' osonElements ']'
        {
            $$ = $2;
        }
    ;
annotatedValue
    :DBL_QUOTE closePart
        {
            $$ = $2;
        }
    ;
closePart
    :'@' '@' closePart
        {
            $$ = yy.Node.handleClosePart("example",$1,$3);
        }
    |'@' osonAnnotation DBL_QUOTE
        {
            $$ = yy.Node.handleClosePart("annotation","@"+$2);
        }
    |singleModifiedValueChar closePart
        {
            $$ = yy.Node.handleClosePart("example",$1,$2);
        }
    |DBL_QUOTE
        {
            $$ = '';
        }
    ;
singleModifiedValueChar
    :MODIFIED_BOTH_CHAR
    {$$ = $1;}
    |wsc
    {$$ = $1;}
    |'?'
    {$$ = $1;}
    ;
osonAnnotation
    :singleModifiedValueChar normalChars
        {$$ = $1+$2;}
    ;
normalChars
    :normalChar normalChars
        {$$ = $1+$2;}
    |
        {$$ = '';}
    ;
normalChar
    :MODIFIED_BOTH_CHAR
    {$$ = $1;}
    |wsc
    {$$ = $1;}
    |'@'
    {$$ = $1;}
    |'?'
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
    |wsc annotatedKey wsc ':' osonElement
        {
           $$={key:$2,value:$5};
        }
    |wsc annotatedKey ':' osonElement
        {
           $$={key:$2,value:$4};
        }
    |annotatedKey wsc ':' osonElement
        {
           $$={key:$1,value:$4};
        }
    ;
annotatedKey
    :DBL_QUOTE closeKey
    {
        // todo: must: ?? to ? !!! already done in singleModifiedKeyChar
        // don't need to handle "...":"@*", handle it in value part
        // remove '?' and change '??' to '?', use "optional: true" to mark it.
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
    :MODIFIED_BOTH_CHAR
        {$$ = $1;}
    |wsc
        {$$ = $1;}
    |'@'
        {$$ = $1;}
    ;
wsc
    :'\n'
    |'\t'
    |' '
    |'\r'
    ;
