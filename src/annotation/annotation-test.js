let jison = require("jison");
let fs = require("fs");
let path = require('path');
let jisonFile = path.resolve(__dirname, 'annotation.jison');
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
    let osonText = fs.readFileSync(osonFile, "utf8");
    let annotationArray = osonText.split('@');
    // console.log(annotationArray)
    annotationArray = annotationArray.slice(1);
    annotationArray.forEach(v=>{
        let processValue= '@'+v.trim();
        if (processValue.length===0){
            //skip the blank line
            return;
        }
        let result = JSON.stringify(parser.parse(processValue), undefined, "    ");
        console.log(`${processValue}:`,result);
    })
}



//test

printRun('a.annotation')
