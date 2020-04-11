let jison = require("jison");
let fs = require("fs");
let path = require('path');
let jisonFile = path.resolve(__dirname, '../jisons/oson2.jison');
let bnf = fs.readFileSync(jisonFile, "utf8");
let parser = new jison.Parser(bnf);
let genParser = parser.generate();
console.log("genParser",genParser);
