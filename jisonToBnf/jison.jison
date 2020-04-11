
%lex
DIGIT1to9                   [1-9]
DIGIT                       [0-9]
DIGITS                      (?:{DIGIT}+)
INT                         (?:{DIGIT1to9}{DIGITS}|{DIGIT}|"-"{DIGIT1to9}{DIGITS}|"-"{DIGIT})
FRAC                        (?:\.{DIGITS})
EXP                         (?:{E}{DIGITS})
E                           [eE][+-]?
HEX_DIGIT                   [0-9a-f]
NUMBER                      (?:{INT}{FRAC}{EXP}|{INT}{EXP}|{INT}{FRAC}|{INT})
UNESCAPEDCHAR               [ -!#-\[\]-~]
ESCAPEDCHAR                 \\["\\bfnrt/]
UNICODECHAR                 \\u{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}
CHAR                        {UNESCAPEDCHAR}|{ESCAPEDCHAR}|{UNICODECHAR}
CHARS                       {CHAR}+
DBL_QUOTE                   ["]
A_Z                         [A-Z]
a_z                         [a-z]
LETTER                      {A_Z}|{a_z}
NAME                        {LETTER}+
LINE_CHAR                   [ -9<-z~]
LINE_CHARS                  {LINE_CHAR}+
O_S                            [{]
O_E                            [}]
M                           [:]
F                           [;]
N                           [\n]
LINE_CHAR_M_F              {LINE_CHAR}|{M}|{F}|{N}
LINE_CHAR_M_FS              {LINE_CHAR_M_F}+
CODE_SEGMENT                {O_S}{LINE_CHAR_M_FS}{O_E}

%%
{DBL_QUOTE}{DBL_QUOTE}|{DBL_QUOTE}{CHARS}{DBL_QUOTE}      return 'STRING_LIT'
{NUMBER}                                                   return 'NUMBER_LIT'
"%start"                                       return 'START_SYMBOL'
"%%"                                           return 'GRAMMAR_START'
":"                                            return ':'
";"                                            return ';'
"|"                                            return '|'
"{"                                            return '{'
"}"                                            return '}'
{LINE_CHARS}                                    return 'LINE_CHARS'
{LINE_CHAR_M_FS}                                return 'LINE_CHAR_M_FS'
\/(?:[^\/]|"\\/")*\/                           return 'REGEX'
[ \t\n]+                                    /* ignore whitespace */
/lex

%token STRING_LIT NUMBER_LIT CODE
%token NAME GRAMMAR_START START_SYMBOL
%token INTEGER_TYPE NUMBER_TYPE BOOLEAN_TYPE NULL_TYPE ANY_TYPE STRING_TYPE JSON_TYPE
%token TRUE FALSE NULL
%left COMMA
%left COLON

%start jisonGrammar
%%

jisonGrammar
    : START_SYMBOL LINE_CHARS GRAMMAR_START segments
        {return $4;}
    ;
segments
    :segment segments
        {
            $$ = `${$1}\n segment\n${$2}`;
        }
    |segment
        {
            $$ = `${$1}`;
        }
    ;
segment
    :LINE_CHARS ':' lines ';'
    {
        $$ = `${$1}\n\t${$3}`;
    }
    ;
lines
    :line '|' lines
    {
        $$ = `${$1}\n\t${$3}`;
    }
    |line
    {
        $$ = `${$1}\n`;
    }
    ;
line
    :LINE_CHARS codes
    {
        $$ = `${$1}`;
    }
    |LINE_CHARS
    {
        $$ = `${$1}`;
    }
    ;
codes
    :'{' LINE_CHAR_M_FS '}'
    |'{' LINE_CHAR_M_FS codes LINE_CHAR_M_FS '}'
    |'{' codes LINE_CHAR_M_FS '}'
    |'{' LINE_CHAR_M_FS codes '}'
    ;
