
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


%%
{DBL_QUOTE}{DBL_QUOTE}|{DBL_QUOTE}{CHARS}{DBL_QUOTE}      return 'STRING_LIT'
{NUMBER}                                                   return 'NUMBER_LIT'
"true"                                                return 'TRUE'
"false"                                            return 'FALSE'
"null"                                            return 'NULL'
"Integer"                                         return 'INTEGER_TYPE'
"Number"                                         return 'NUMBER_TYPE'
"Boolean"                                         return 'BOOLEAN_TYPE'
"Null"                                         return 'NULL_TYPE'
"Any"                                         return 'ANY_TYPE'
"String"                                         return 'STRING_TYPE'
"JSON"                                         return 'JSON_TYPE'
"{"                                            return '{'
"}"                                            return '}'
"="                                            return '='
"["                                             return '['
"]"                                            return ']'
"("                                            return '('
")"                                            return ')'
"|"                                            return '|'
"`"                                            return '`'
","                                            return ','
":"                                            return ':'
"*"                                            return '*'
"@"                                            return '@'
\/(?:[^\/]|"\\/")*\/                           return 'REGEX'
[ \t\n]+                                    /* ignore whitespace */
/lex

%token STRING_LIT NUMBER_LIT
%token CHAR
%token INTEGER_TYPE NUMBER_TYPE BOOLEAN_TYPE NULL_TYPE ANY_TYPE STRING_TYPE JSON_TYPE
%token TRUE FALSE NULL
%left COMMA
%left COLON

%start annotationObject
%%

annotationObject
    :'@' annotation
        {return $2;}
    ;
annotation
    :annotationType
    {
        $$ = $1;
    }
    ;
annotationType
    :unionType
    {
        $$ = $1;
    }
    |basicType
    {
        $$ = $1;
    }
    ;
unionType
    :'(' basicType ')' '|' unionType
    {
        yy.Node.unionType($5,$2);
        $$ = $5;
    }
    |'(' basicType ')'
    {
        $$ = $2;
    }
    ;
basicType
    :basicTypePrefix basicTypeSuffix
    {
        $$ = $1;
        yy.Node.addSuffix($1,$2);
    }
    ;
basicTypePrefix
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
    |'*' optionalTypeTuple
        {
            $$ = new yy.Node("additionalProperties",undefined,[]);
            yy.Node.addOptional($$,$2);
        }
    ;
optionalTypeTuple
    : unionType
    {
        $$ = {optionalTypeTuple:$1};
    }
    |#nothing
    {
        $$ = {optionalTypeTuple:true};
    }
    ;
basicTypeSuffix
    :optionalEnumValues optionalDefaultValue
    {
        $$={};
        if ($1) {$$.optionalEnumValues = $1;}
        if ($2) {$$.optionalDefaultValue = $2;}
    }
    ;
optionalEnumValues
    :'{' elements '}'
    {
        $$ = JSON.parse(`[${$2}]`);
    }
    |'{' '}'
    {
        $$ = [];
    }
    |#nothing
    ;
optionalDefaultValue
    :'=' json_value
    {
        $$ = JSON.parse($2);
    }
    |#nothing
    ;
optionalRange
    :'[' json_number ',' json_number ']'
    {
        //console.log("optionalRange:",$2,$4)
        $$ = [JSON.parse($2),JSON.parse($4)];
    }
    |'[' json_number ',' ']'
    {
        $$ = [JSON.parse($2),null];
    }
    |'[' ',' json_number ']'
    {
        $$ = [null,JSON.parse($4)];
    }
    |'[' ',' ']'
    {
        $$ = [null,null];
    }
    |#nothing
    ;
optionalPerlRegex
    :REGEX
    {
        $$ = {optionalPerlRegex:$1.slice(1,$1.length-1)};
    }
    |#nothing
    ;
optionalExtraProperties
    :'`' json_object '`'
    {
        $$ = {optionalExtraProperties:JSON.parse($2)}
    }
    |#nothing
    ;



elements
    :json_value
    {
        $$ = $1;
    }
    |json_value ',' elements
    {
        $$ = $1+','+$3;
    }
    ;
json_value
    :json_string
    {$$ = $1;}
    |json_number
    {$$ = $1;}
    |json_object
    {$$ = $1;}
    |json_array
    {$$ = $1;}
    |TRUE
    {$$ = $1;}
    |FALSE
    {$$ = $1;}
    |NULL
    {$$ = $1;}
    ;
json_number
    : NUMBER_LIT
        {$$ = $1;}
    ;
json_array
    :'[' ']'
    {
        $$ = `[]`
    }
    |'[' elements ']'
    {
        $$ = `[ ${$2} ]`
    }
    ;
json_object
    :'{' '}'
    {
        $$ = `{}`
    }
    |'{' members '}'
    {
        $$ = `{ ${$2} }`
    }
    ;
members
    :pair
    {
        $$ = $1;
    }
    |pair ',' members
    {
        $$ = $1+','+$3;
    }
    ;
pair
    :STRING_LIT ':' json_value
    {
        $$ = `${$1} : ${$3}`
    }
    ;
json_string
    :STRING_LIT
    { $$ = $1;}
    ;
