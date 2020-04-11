
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
ESCAPEDCHAR                 \\["\\bfnrt/]
UNICODECHAR                 \\u{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}
UNESCAPEDCHAR               [ -!#-\[\]-~]
CHAR                        {UNESCAPEDCHAR}|{ESCAPEDCHAR}|{UNICODECHAR}
CHARS                       {CHAR}+
MODIFIED_VALUE_CHAR         {UNESCAPED_CHAR_WITHOUT_AT}|{ESCAPEDCHAR}|{UNICODECHAR}
MODIFIED_KEY_CHAR           {UNESCAPED_CHAR_WITHOUT_QM}|{ESCAPEDCHAR}|{UNICODECHAR}
DBL_QUOTE                   ["]


%%
{DBL_QUOTE}{MODIFIED_KEY_CHARS}{KEY_ANNOTATION_SYMBOL}{DBL_QUOTE}      return 'ANNOTATED_KEY_STRING'
{VALUE_ANNOTATION_SYMBOL}{MODIFIED_VALUE_CHAR}{CHARS}|{VALUE_ANNOTATION_SYMBOL}{MODIFIED_VALUE_CHAR}    return 'OSON_ANNOTATION'
{MODIFIED_VALUE_CHAR}                              return 'MODIFIED_VALUE_CHAR'
{MODIFIED_KEY_CHAR}                              return 'MODIFIED_KEY_CHAR'
"true"                                                return 'TRUE'
"false"                                            return 'FALSE'
"null"                                            return 'NULL'
"Integer"                                         return 'INTEGER_TYPE'
"Number"                                         return 'NUMBER_TYPE'
"Boolean"                                         return 'BOOLEAN_TYPE'
"Null"                                         return 'NULL_TYPE'
"Any"                                         return 'ANY_TYPE'
"String"                                         return 'STRING_TYPE'
"Integer"                                         return 'INTEGER_TYPE'
"JSON"                                         return 'JSON_TYPE'
{VALUE_ANNOTATION_SYMBOL}{VALUE_ANNOTATION_SYMBOL}    return '@@'
{KEY_ANNOTATION_SYMBOL}{KEY_ANNOTATION_SYMBOL}        return '??'
"{"                                            return '{'
"}"                                            return '}'
"["                                             return '['
"]"                                            return ']'
","                                            return ','
":"                                            return ':'
{DBL_QUOTE}                                    return 'DBL_QUOTE'
\/(?:[^\/]|"\\/")*\/                           return 'REGEX'
[ \t\n]+                                    /* ignore whitespace */
/*.                                               return 'INVALID'*/
/lex

%token ANNOTATED_KEY_STRING OSON_ANNOTATION
%token DBL_QUOTE
%token MODIFIED_CHAR
%token TRUE FALSE NULL
%left O_BEGIN O_END A_BEGIN A_END
%left COMMA
%left COLON

%start osonSchema
%%
osonSchema
    :osonValue
    {
       return $1;
    }
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
    :'{' '}'
        {
            $$ = new yy.Node("object",undefined,[]);
        }
    |'{' osonMembers '}'
        {
            $$ = new yy.Node("object",undefined,$2);
        }
    ;
osonArray
    :'[' ']'
        {
            $$ = new yy.Node("array",undefined,[]);
        }
    |'[' osonElements ']'
        {
            $$ = new yy.Node("array",undefined,$2);
        }
    ;
annotatedValue
    :DBL_QUOTE modifiedValueChars OSON_ANNOTATION DBL_QUOTE
        {
            // @@ to @
            $$ = {
                     //return "" if no example
                     jsonExample: yy.Node.getOriValue($2),
                     osonAnnotation: $3
                 }
        }
    |modifiedValueString
        {
            // todo: must: @@ to @ !!!
            $$ =$1
        }
    ;
osonMembers
    :osonMember ',' osonMembers
    {$$ = $3; $$.unshift($1);}
    |osonMember
    {$$ = [$1];}
    ;
osonElements
    :osonValue ',' osonElements
    {$$ = $3; $$.unshift($1);}
    |osonValue
    {$$ = [$1];}
    ;
modifiedValueString
    : DBL_QUOTE DBL_QUOTE
    {$$='';}
    | DBL_QUOTE modifiedValueChars DBL_QUOTE
    {$$=`${$2}`;}
    ;
osonMember
    :annotatedKey ':' osonValue
    {
        //named_entries for object entries[annotatedKey]={propertiesName,optional} [osonValue]=Value(type:...)
        $$ = {
            annotatedKey:$1,
            osonValue:$3
        };
    }
    ;
modifiedValueChars
    :singleModifiedValueChar modifiedValueChars
    {$$=$1+$2;}
    |
    {$$='';}
    ;
singleModifiedValueChar
    :MODIFIED_VALUE_CHAR
    {$$ = $1;}
    |'@' '@'
    {$$ = '@';}
    ;
annotatedKey
    :modifiedKeyString
    {
        // todo: must: ?? to ? !!!
        // don't need to handle "...":"@*", handle it in value part
        // remove '?' and change '??' to '?', use "optional: true" to mark it.
        $$ = {
            text: yy.Node.getOriKey($1),
            optional: true
        }
    }
    ;
modifiedKeyString
    : DBL_QUOTE DBL_QUOTE
    {$$='';}
    | DBL_QUOTE modifiedKeyChars DBL_QUOTE
    {$$=`${$2}`;}
    ;
modifiedKeyChars
    :singleModifiedKeyChar modifiedKeyChars
    {$$=$1+$2;}
    |
    {$$='';}
    ;
singleModifiedKeyChar
    :MODIFIED_KEY_CHAR
    {$$ = $1;}
    |'?' '?'
    {$$ = '?';}
    ;
