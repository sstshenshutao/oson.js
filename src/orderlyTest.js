let jison = require("jison");
let fs = require("fs");
let path = require('path');
let jisonFile = path.resolve(__dirname, 'oson2.jison');
let bnf = fs.readFileSync(jisonFile, "utf8");
let parser = new jison.Parser(bnf);
bindScope(parser, "Node", require('./scope'));

function bindScope(parser, scopeName, scope) {
    let yy = parser.yy;
    if (yy[scopeName]) {
        console.log(`${scopeName} exists`)
    } else {
        yy[scopeName] = scope
    }
}

function printRun(filename) {
    let path = require('path');
    let osonFile = path.resolve(__dirname, filename);
    let osonJSON = fs.readFileSync(osonFile, "utf8");
    let result = JSON.stringify(parser.parse(osonJSON), undefined, "    ");
    console.log(result);
}



//test

printRun('a.json')
