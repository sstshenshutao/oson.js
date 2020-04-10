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

        if (this.json.type === "array") {
            //unnamed_entry
            if (entry['basicExample'] && entry['basicType']) {
                // {"example":"777","type":{"type":"integer"}}
                // to
                // {"type":"integer",
                // "example":"777"
                // }
                // console.log("debug", entry);
                entry = {
                    example: entry['basicExample'],
                    type: entry['basicType']['type']
                }
            }
            if ((entry.type) && entry.type === "additionalProperties") {
                this.json.additionalItems = entry.value;
            } else {
                this.json.items = this.json.items || [];
                this.json.items.push(entry);
            }
        } else if (this.json.type === "object") {
            //named_entry
            let key = entry[0];
            let value = entry[1];
            if (value['basicExample'] && value['basicType']) {
                // {"example":"777","type":{"type":"integer"}}
                // to
                // {"type":"integer",
                // "example":"777"
                // }
                value = {
                    example: value['basicExample'],
                    type: value['basicType']['type']
                }
            }
            // console.log("debugKEYVALUE", key, value);
            this.json.additionalProperties = false;
            this.json.properties = this.json.properties || {};
            this.json.required = this.json.required || [];
            if (value.type && value.type === "additionalProperties") {
                // don't add it.
                this.json.additionalProperties = value.value;
            } else {
                if (!key.optional) {
                    this.json.required.push(key.text);
                }
                this.json.properties[key.text] = value;
            }
        }

    }

    addEntries(entries) {
        //todo:rewrite handle type==='json'
        //todo:rewrite handle example!!!

        if (this.json.type === "array") {
            this.json.additionalItems = false;
            if (!(entries instanceof Array)) {
                if ((entries.type) && entries.type === "additionalProperties") {
                    this.json.additionalItems = true;
                } else {
                    this.json.items = entries;
                }
            } else if (entries.length > 0) {
                for (let j = 0; j < entries.length; j++) {
                    if (entries[j].type && entries[j].type === "additionalProperties") {
                        // remove them.
                        entries.splice(j, 1);
                        this.json.additionalItems = true;
                    }
                }
                if (entries.length > 0) {
                    this.json.items = entries;
                }
            }

        } else if (this.json.type === "object") {
            this.json.additionalProperties = false;
            this.json.properties = {};
            this.json.required = [];

            for (let i = 0; i < entries.length; i++) {
                let value = entries[i][1];
                if (value.type && value.type === "additionalProperties") {
                    // don't add it.
                    this.json.additionalProperties = true;
                } else {
                    if (!entries[i][0].optional) {
                        this.json.required.push(entries[i][0].text);
                    }
                    this.json.properties[entries[i][0].text] = value;
                }
            }
        }
    }

    addRange(tuple) {
        var suf = this.json.type === 'array' ? 'Items' : this.json.type === 'string' ? 'Length' : 'imum';
        if (tuple[0] !== null) this.json['min' + suf] = Number(tuple[0]);
        if (tuple[1] !== null) this.json['max' + suf] = Number(tuple[1]);
    }

    testPrint(text) {
        console.log(text);
    }

    static getOriValue(valueStr) {
        // skip first '"' and last '@'
        return changeValueEscape(valueStr.slice(1, valueStr.length - 1));

        function changeValueEscape(valueStr) {
            return valueStr.replace(/@@/g, "@");
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
        //node is the first priority
        //merge two nodes. type[optional]/suffix
        for (let k in node) {
            if (k === 'type') {
                nodeMain.type = Array.isArray(nodeMain.type) ? nodeMain.type : [nodeMain.type];
                unshift(nodeMain.type, node.type);
                continue;
            }
            if (k === 'enum') {
                nodeMain['enum'] = unshiftSet(nodeMain['enum'], node['enum']);
                continue;
            }
            nodeMain[k] = node[k];
        }

        function unshiftSet(set, set2) {
            return set2.filter(x => !set.includes(x)).concat(set);
        }

        function unshift(set, ele) {
            if (!set.includes(ele)) {
                set.unshift(ele);
            }
        }
    }

    static addOptional(node, optional) {
        if (!optional) {
            return;
        }
        //todo: handle optionalPerlRegex, optionalExtraProperties, addtional's value
        if (optional['optionalPerlRegex']) {
            node['pattern'] = optional['optionalPerlRegex'];
        }
        // if (optional['optionalExtraProperties']) {
        //     // clearNode
        //     for (let k in node) {
        //         node[k] = undefined;
        //     }
        //     // console.log("-----------------------------");
        //     // console.log(optional['optionalExtraProperties']);
        //     // console.log("-----------------------------");
        //     let newNode = optional['optionalExtraProperties'];
        //     for (let k in newNode) {
        //         node[k] = newNode[k];
        //     }
        // }
        if (optional['optionalTypeTuple']) {
            node['value'] = optional['optionalTypeTuple'];
        }

    }

    static addSuffix(node, objSuffix) {
        // "enum": ["red", "amber", "green"]
        if (objSuffix['optionalEnumValues']) {
            // if (node.type === 'integer') {
            //     node['enum'] = objSuffix['optionalEnumValues'].map(x => Number(x));
            // } else {
            node['enum'] = objSuffix['optionalEnumValues'];
            // }
        }
        if (objSuffix['optionalDefaultValue']) {
            node['default'] = objSuffix['optionalDefaultValue'];
        }
    }
}
module.exports = Node;
// console.log(Node.getOriValue("\"@"));
// console.log(JSON.parse("\"aa\""))
