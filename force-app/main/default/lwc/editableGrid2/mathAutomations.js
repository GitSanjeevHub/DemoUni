function sum(grid, addends, index){
    var sum = 0;
    for (var k=0; k<addends.length; k++){
        let addend = addends[k];
        
        var addendValue;
        if (addend.staticValue)
            addendValue = addend.staticValue;
        else {
            let sourceName = addend.source;
            addendValue = grid.getSourceEntityValueByName(sourceName, index, addend.fieldName);
        }
        //grid.customLog('addendValue '+addendValue);
        sum += parseFloat(addendValue);
        
    }
    //grid.customLog('Sum '+sum);
    sum = 1 * Number.parseFloat(sum).toFixed(2);

    return sum;
}


function multiply(grid, factors, index){

    var product = 1;

    for (var l=0; l<factors.length; l++){

        console.log('factor '+l);
        let factor = factors[l];
        var value;

        if (factor.staticValue){
            value = factor.staticValue;
        }
        else {
            let factorSourceName = factor.source;
            //grid.customLog(factorSourceName);
            value = grid.getSourceEntityValueByName(factorSourceName, index, factor.fieldName);
        }
        //grid.customLog('value '+value);
        
        product = (product * value);
        //grid.customLog('Running product is '+product);
    }

    product = 1 * Number.parseFloat(product).toFixed(2);

    return product;

}

export {sum, multiply};