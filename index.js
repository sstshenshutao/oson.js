let osonParser = require('./src/oson-parser');
let scope = require('./src/scope');
let newParser = osonParser;
bindScope(newParser, "Node", scope);

function bindScope(parser, scopeName, scope) {
    let yy = parser.yy;
    if (yy[scopeName]) {
        console.log(`${scopeName} exists`)
    } else {
        yy[scopeName] = scope
    }
}

function parse(shortText) {

    return newParser.parse(shortText);

}

module.exports = parse;
