class Node {

    constructor(type, range, entries) {
        this.NOVALUE = {};
        this.json = {};
        this.json.type = type;
        if (type instanceof Array && type.length < 2) {
            throw new Error("must have at least two members in a union");
        }

        if (range) {
            this.addRange(range);
        }
        if (entries) {
            if (entries instanceof Array) {
                this.addMultipleEntries(entries);
            } else {
                this.addSingleEntries(entries);
            }

        }
        return this.json;
    }

    addMultipleEntries(entries) {
        for (let i = 0; i < entries.length; i++) {
            this.addSingleEntries(entries[i]);
        }
    }

    addSingleEntries(entry) {
        if (!this.json.type){
            //json-array or json-object: add the entry as element/key:value
            if (Array.isArray(this.json)){
                if (entry.type === 'array' || entry.type === 'object') {
                    this.json.push(entry);
                }else {
                    if(entry['osonAnnotation']==='@JSON'){
                        this.json.push(entry['examples']);
                    }else {
                        //pure-json
                        this.json.push(entry);
                    }
                }
            }else {
                if (entry['value'].type === 'array' || entry['value'].type === 'object') {
                    this.json[entry['key']['key']] = entry['value'];
                }else {
                    if(entry['value']['osonAnnotation']==='@JSON'){
                        this.json[entry['key']['key']]=entry['value']['examples'];
                    }else {
                        //pure-json
                        this.json[entry['key']['key']]=entry['value'];
                    }
                }
            }

        }else if (this.json.type === "array") {
            //unnamed_entry(osonValue)
            // if entry.type === array or object: already handled => directly add.
            if (entry.type === 'array' || entry.type === 'object') {
                // check "Tuple validation" or "List validation"
               if (this.json.items && this.json.items['anyOf']) {
                    // "List validation"
                    this.json.items['anyOf'].push(entry);
                } else {
                    // "Tuple validation"
                    this.json.items = this.json.items || [];
                    this.json.items.push(entry);
                }

            } else {
                // if entry.type !== array or object: not handled yet =>
                // entry can only be annotatedValue,because obj/array will be handled by "new Node"
                //todo: can tell diff between pure-json and non-parsed entry.
                if (entry['examples'] || entry['osonAnnotation']) {
                    if (entry['osonAnnotation']) {
                        // this entry has an "osonAnnotation"
                        // has annotation, by default "Tuple validation"
                        //todo: parse annotation
                        let annotation = this.parseAnnotation(entry['osonAnnotation']);
                        //handle type:json/additionalProperties
                        if (annotation['type'] === 'json') {
                            // oh no, this array is a normal json!
                            this.json.type=undefined;
                            // exampless to elements
                            let tmpArray= this.json.examples;
                            this.json =[];
                            for (let i = 0; i <tmpArray.length; i++) {
                                this.json.push(tmpArray[i]);
                            }
                            this.json.additionalItems = undefined;
                        } else if (annotation['type'] === 'additionalProperties') {
                            this.json.additionalItems = annotation['value'];
                        } else {
                            this.json.items = this.json.items || [];
                            this.json.items.push(annotation);
                            if (entry['examples']) {
                                // this entry has an examples, push to examples
                                let examples = getTypeValue(entry['examples'],annotation);
                                this.json.examples = this.json.examples || [];
                                this.json.examples.push(examples);
                            }
                        }
                    } else {
                        // has only examples, change "Tuple validation" to "List validation" via anyOf
                        //buffer items
                        let tmpArray = this.json.items;
                        this.json.items = {anyOf: tmpArray};
                        if (entry['examples']) {
                            // this entry has an examples, push to examples
                            this.json.examples = this.json.examples || [];
                            this.json.examples.push(entry['examples']);
                        }
                    }
                }
                else {
                    //pure-json
                    this.json.items = this.json.items || [];
                    this.json.items.push(entry);
                }
            }
        } else if (this.json.type === "object") {
            //named_entry
            if (!entry['value']) {console.log("debug",entry);}
            if (entry['value'].type === 'array' || entry['value'].type === 'object') {
                //add key: value
                this.json.properties = this.json.properties || {};
                this.json.required = this.json.required || [];
                if (!entry['key']['optional']){
                    this.json.required.push(entry['key']['key']);
                }
                this.json.properties[entry['key']['key']] = entry['value'];
            }else {
                // if entry.type !== array or object: not handled yet =>
                // should be something like :
                // {
                //     "key": {
                //         "key": "firstProp",
                //         "optional?": true
                //     },
                //     "value": {
                //         "examples": "777",
                //         "osonAnnotation": "@Integer"
                //     }
                // }
                //todo: can tell diff between pure-json and non-parsed entry.
                if (entry['key'] || entry['value']) {
                    if (!entry['key']['key'] && entry['key']['optional']){
                        // omg, the '' as key
                        if (entry['value']['osonAnnotation']==='@JSON'){
                            //omg, ("?":"@JSON"), the JSON-object!!!
                            this.json.type=undefined;
                            let tmpObj = this.json.properties;
                            this.json={};
                            for (let k in tmpObj){
                                this.json[k] = tmpObj[k];
                            }
                        }else {
                            //throw an exception! '?' can not be key!
                        }
                    }else {
                        let key = entry['key']['key'];
                        let optional = entry['key']['optional'];
                        let examples = entry['value']['examples'];
                        let annotation = this.parseAnnotation(entry['value']['osonAnnotation']);
                        examples = getTypeValue(examples,annotation);
                        if (examples){
                            annotation['examples'] = [examples];
                        }
                        //handle type:json/additionalProperties
                        if (annotation['type'] === 'json') {
                            // oh no, this value is a normal json => back string
                            //add key: examples
                            this.json.properties = this.json.properties || {};
                            this.json.properties[entry['key']['key']] =  examples;
                        } else if (annotation['type'] === 'additionalProperties') {
                            this.json.additionalProperties = annotation['value'];
                        } else {
                            this.json.properties = this.json.properties || {};
                            this.json.required = this.json.required || [];
                            if (!entry['key']['optional']){
                                this.json.required.push(entry['key']['key']);
                            }
                            this.json.properties[entry['key']['key']] = annotation;
                        }
                    }
                }
                else {
                    //pure-json
                    this.json.properties = this.json.properties || {};
                    this.json.required = this.json.required || [];
                    if (!entry['key']['optional']){
                        this.json.required.push(entry['key']['key']);
                    }
                    this.json.properties[entry['key']['key']] = entry['value'];
                }
            }
        }
        function getTypeValue(examples,annotation) {
            if (annotation['type'] === 'number'||annotation['type'] === 'integer'){
                examples=Number(examples);
            }else if (annotation['type'] === 'boolean'){
                examples= examples==='true';
            }
            return examples;
        }
    }
    parseAnnotation(annotation){
        let funcParse= require('oson.annotation.js.test');
        return funcParse(annotation);
    }

    addRange(tuple) {
        var suf = this.json.type === 'array' ? 'Items' : this.json.type === 'string' ? 'Length' : 'imum';
        if (tuple[0] !== null) this.json['min' + suf] = tuple[0];
        if (tuple[1] !== null) this.json['max' + suf] = tuple[1];
    }

    testPrint(text) {
        console.log(text);
    }

    static getOriValue(valueStr) {
        return changeValueEscape(valueStr);

        function changeValueEscape(valueStr) {
            return valueStr.replace(/@@/g, "@");
        }
    }

    static handleClosePart(type, str, rest) {
        if (type === 'annotation') {
            return {osonAnnotation: str};
        } else if (type === 'examples') {
            let wholeObj = rest.examples ? rest : {
                examples: typeof rest === 'string' ? rest : '',
                osonAnnotation: rest['osonAnnotation']
            };
            wholeObj.examples = str + wholeObj.examples;
            return wholeObj;
        }
    }

    static handleCloseKey(type, str, rest) {
        if (type === 'optional') {
            return {optional: str}
        } else if (type === 'key') {
            let wholeObj = rest.key ? rest : {
                key: typeof rest === 'string' ? rest : '',
                optional: rest['optional']
            };
            wholeObj.key = str + wholeObj.key;
            return wholeObj
        }
    }

    static getOriKey(keyStr) {
        // skip last '?'
        return changeKeyEscape(keyStr.slice(1, keyStr.length - 2))

        function changeKeyEscape(keyStr) {
            return keyStr.replace(/\?\?/g, "?");
        }
    }

    static unionType(nodeMain, node) {
        nodeMain.type = Array.isArray(nodeMain.type) ? nodeMain.type : [nodeMain.type];
        nodeMain.type.unshift(node.type);
    }

    static addOptional(node, optional) {
        //todo: handle optionalPerlRegex, optionalExtraProperties
    }

    static addSuffix(node, objSuffix) {

    }
}
;
module.exports = Node;
