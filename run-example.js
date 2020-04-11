let parse = require('./index');
let jsonSchema = parse("{\n" +
    "        \"objInsideArray?\":  \"simple@String\"\n" +
    "      }")
console.log(JSON.stringify(jsonSchema, undefined, "    "));

