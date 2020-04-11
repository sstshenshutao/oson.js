let parse = require('oson.js');
function toJsonSchema(osonText){
    let jsonSchema =parse(osonText);
    return JSON.stringify(jsonSchema, undefined, "    ");
}
window.onload = function () {
    document.getElementById("button").onclick = function () {
        try {
            let result = toJsonSchema(document.getElementById("osonAnnotation").value);
            document.getElementById("jsonschema").value = result;
        } catch(e) {
            document.getElementById("jsonschema").value = e;
        }
    };
};
