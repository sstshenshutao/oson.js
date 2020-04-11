>doc complete!  

>array:    
items:{anyof{}} maybe need to be changed to ???    
  
>JSON type:  
"thisJson": {  
        "?": "@Json",  
        "type": "array@Json",  
      "contains": {  
        "type": "number@Json",  
        "@Json": "@Json"  
      }  
    }    
"thisJson": {  
        "type": "array@Json",  
      "contains": {  
        "type": "number@Json",  
      }  
    }  
thisJson:object properties:{type:array contains:object properties:type:number}  
for array:  
"thisJson": [  
  "@Json","hi","hello"  
]  
"thisJson":["hi","hello"]  
          
        "type": "array@Json",  
      "contains": {  
        "type": "number@Json",  
        "@Json": "@Json"  
      }  
    }