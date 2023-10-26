({
	getURLParameter : function(param) {
		console.log('getURLParamter '+param);
		let returnedParam = decodeURIComponent
                ((new RegExp('[?|&]'+param+'=' + '([^&;]+?)(&|#|;|$)').
					exec(location.search)||[,""])[1].replace(/\+/g, '%20'))||null;
		console.log('getURLParamter '+param + ': '+returnedParam);
		return returnedParam;
					
	},

})