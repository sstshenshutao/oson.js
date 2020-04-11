
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
UNESCAPEDCHAR               [ -!#->A-\[\]-~]
ESCAPEDCHAR                 \\["\\bfnrt/]
UNICODECHAR                 \\u{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}
CHAR                        {UNESCAPEDCHAR}|{ESCAPEDCHAR}|{UNICODECHAR}|"??"|"@@"
CHARS                       {CHAR}+
DBL_QUOTE                   ["]


%%
{DBL_QUOTE}{CHARS}{KEY_ANNOTATION_SYMBOL}{DBL_QUOTE}      return 'annotatedKeyString'
{DBL_QUOTE}{VALUE_ANNOTATION_SYMBOL}|{DBL_QUOTE}{CHARS}{VALUE_ANNOTATION_SYMBOL}   return 'openAnnotatedValueString'
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
"{"                                            return '{'
"}"                                            return '}'
"["                                             return '['
"]"                                            return ']'
","                                            return ','
":"                                            return ':'
{DBL_QUOTE}                                    return 'DBL_QUOTE'
{CHAR}                                         return 'CHAR'
\/(?:[^\/]|"\\/")*\/                           return 'REGEX'
[ \t\n]+                                    /* ignore whitespace */
/*.                                               return 'INVALID'*/
/lex

%token INT FRAC EXP
%token annotatedKeyString openAnnotatedValueString
%token DBL_QUOTE
%token CHAR
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
    |annotatedString
        {
            $$ = $1;
        }
    ;
annotatedString
    :openAnnotatedValueString annotation DBL_QUOTE
        {
            // @@ to @
            $$ = {
                     //return "" if no example
                     basicExample: yy.Node.getOriValue($1),
                     basicType: $2
                 }
        }
    |string
        {
            // @@ to @, don't need if there is no '@'
            $$ =$1
        }
    ;
annotation
    :osonType suffix
    ;
suffix
    :optionalEnumValues optionalDefaultValue
    ;
optionalDefaultValue
    :'=' json_value
    |
    ;
json_value
    :string
    {$$ = $1;}
    |json_number
    |json_object
    |json_array
    |"true"
    |"false"
    |"null"
    ;
json_array
    :'[' ']'
    |'[' elements ']'
    ;
elements
    :json_value
    |json_value ',' elements
    ;
json_object
    :'{' '}'
    |'{' members '}'
    ;
members
    :pair
    |pair ',' members
    ;
pair
    :string ':' json_value
    ;
optionalEnumValues
    :'{' elements '}'
    |'{' '}'
    |
    ;
osonType
    :unionType
    |basicType
    ;
basicType
    :INTEGER_TYPE optionalRange
        {
            $$ = new yy.Node("integer",$2,[]);
        }
    |NUMBER_TYPE optionalRange
        {
            $$ = new yy.Node("number",$2,[]);
        }
    |BOOLEAN_TYPE
        {
            $$ = new yy.Node("boolean",undefined,[]);
        }
    |NULL_TYPE
        {
            $$ = new yy.Node("null",undefined,[]);
        }
    |ANY_TYPE
        {
            $$ = new yy.Node("any",undefined,[]);
        }
    |STRING_TYPE optionalRange optionalPerlRegex
        {
            $$ = new yy.Node("string",$2,[]);
            yy.Node.addOptional($$,$3);
        }
    |JSON_TYPE optionalExtraProperties
        {
            $$ = new yy.Node("json",undefined,[]);
            yy.Node.addOptional($$,$2);
        }
    |'*'
    {
        $$ = new yy.Node("additionalProperties",undefined,[]);
    }
    ;
optionalExtraProperties
    :'`' json_object '`'
    |
    ;
optionalPerlRegex
    :REGEX
    |
    ;
optionalRange
    :'[' json_number ',' json_number ']'
    |'[' json_number ',' ']'
    |'[' ',' json_number ']'
    |'[' ',' ']'
    |
    ;
unionType
    :'(' basicType ')' '|' unionType
    |'(' basicType ')'
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
osonElements
    :osonValue ',' osonElements
    {$$ = $3; $$.unshift($1);}
    |osonValue
    {$$ = [$1];}
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
osonMembers
    :osonMember ',' osonMembers
    {$$ = $3; $$.unshift($1);}
    |osonMember
    {$$ = [$1];}
    ;
osonMember
    :annotatedKey ':' osonValue
    {
        //named_entries for object entries[0]={propertiesName,optional} [1]=Value(type:...)
        $$ = [$1,$3];
    }
    ;
annotatedKey
    :annotatedKeyString
    {
        // don't need to handle "...":"@*", handle it in value part
        // remove '?' and change '??' to '?', use "optional: true" to mark it.
        $$ = {
            text: yy.Node.getOriKey($1),
            optional: true
        }
    }
    |string
    {
        //don't need "??" -> "?", if there is no ? at end.
        $$ = {
             text: $1,
             optional: false
        }
    }
    ;
json_number
    : number
        {$$ = $1;}
    ;
string
    : DBL_QUOTE DBL_QUOTE
    {$$='';}
    | DBL_QUOTE chars DBL_QUOTE
    {$$=`${$2}`;}
    ;
chars
    :CHAR chars
    {$$=$1+$2;}
    |CHAR
    {$$=$1;}
    ;
number
    :INT FRAC EXP
    |INT EXP
    |INT FRAC
    |INT
    ;
