// skip until %start;
function convert(filename) {
    let fs = require("fs");
    let path = require('path');
    let osonFile = path.resolve(__dirname, filename);
    let inputText = fs.readFileSync(osonFile, "utf8");
    let startIndex =inputText.indexOf("%start");
    let newText = inputText.slice(startIndex);
    // console.log(newText);
    let jison = require("jison");
    let jisonFile = path.resolve(__dirname, 'jison.jison');
    let bnf = fs.readFileSync(jisonFile, "utf8");
    let parser = new jison.Parser(bnf);
    console.log(parser.parse(newText));
}

convert('oson.annotation.jison');

