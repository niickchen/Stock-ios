<!doctype html>
<html lang="en">

<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://code.jquery.com/jquery-3.1.1.min.js"></script>
<script src="https://code.highcharts.com/stock/highstock.js"></script>
<script src="https://code.highcharts.com/stock/modules/exporting.js"></script>
<script>

function callNativeApp (messageToPost) {
    try {
        webkit.messageHandlers.callbackHandler.postMessage(JSON.stringify(messageToPost));
    } catch(err) {
        console.log('Error from current.js');
        console.log(err);
    }
}

// load data from Swift and plot
function reloadPrice(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0]
    var timesdaily = data[1]
    timesdaily = timesdaily['Time Series (Daily)'];
    var dates = data[2].slice(0, 121).reverse()
    var prices = [];
    var volumes = [];
    for (let i = 0; i < 121; i++) {
        prices[i] = parseFloat((Math.round(parseFloat(timesdaily[dates[i]][
                                                                           '4. close'
                                                                           ]) * 100) / 100).toFixed(2));
        volumes[i] = parseFloat(timesdaily[dates[i]]['5. volume']);
    }
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    var options = {
    chart: {
    zoomType: "x"
    },
    title: {
    text: symbol + ' Stock Price and Volume'
    },
    subtitle: {
    useHTML: true,
    text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
        /*
         style: {
         a:hover: 'black'
         }
         */
    },
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
    yAxis: [{
            //min: minp - (maxp-minp)/12 - (maxp-minp)/6,
            //max: (maxp-minp)/12 + maxp,
            tickAmount: 5,
            title: {
            text: 'Stock Price'
            }
            }, {
            min: 0,
            //max: 7*maxv,
            gridLineWidth: 0,
            opposite: true,
            title: {
            text: 'Volume'
            },
            tickAmount: 5
            }],
    tooltip: {
    shared: false
    },
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
    plotOptions: {
    column: {
    pointPadding: 0.2,
    borderWidth: 0
    },
    area: {
    marker: {
    enabled: false,
    symbol: 'circle',
    radius: 2,
    states: {
    hover: {
    enabled: true
    }
    }
    },
    fillOpacity: 0.25
    }
    },
    series: [{
             name: 'Price',
             data: prices,
             color: '#66a9ff',
             type: 'area',
             tooltip: {
             valueDecimals: 2
             }
             }, {
             name: 'Volume',
             data: volumes,
             color: '#FF0000',
             type: 'column',
             yAxis: 1
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
}

function reloadMACD(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0]
    var macdData = data[1]
    macdData = macdData['Technical Analysis: MACD'];
    var dates = data[2].slice(0, 121).reverse()
    var macd = [];
    var hist = [];
    var signal = [];
    for (let i = 0; i < 121; i++) {
        var datedData = macdData[dates[i]];
        macd[i] = parseFloat(datedData['MACD']);
        hist[i] = parseFloat(datedData['MACD_Hist']);
        signal[i] = parseFloat(datedData['MACD_Signal']);
    }
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    var options = {
    chart: {
    type: 'line',
    zoomType: "x"
    },
    title: {
    text: 'Moving Average Convergence/Divergence (MACD)'
    },
    subtitle: {
    useHTML: true,
    text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
    },
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
    yAxis: {
    tickAmount: 5,
    title: {
    text: 'MACD'
    }
    },
    tooltip: {
    shared: false
    },
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
    plotOptions: {
    line: {
    dataLabels: {
    enabled: false
    },
    marker: {
    lineWidth: 0,
    enabled: false,
    symbol: 'square',
    states: {
    hover: {
    enabled: true
    }
    }
    }
    }
    },
    series: [{
             name: symbol + ' MACD',
             data: macd,
             color: '#ff0000',
             lineWidth: 2,
             marker: {
             radius: 1.5
             }
             }, {
             name: symbol + ' MACD_Hist',
             data: hist,
             color: '#ffc34d',
             lineWidth: 2,
             marker: {
             radius: 1.5
             }
             }, {
             name: symbol + ' MACD_Signal',
             data: signal,
             color: '#66a9ff',
             lineWidth: 2,
             marker: {
             radius: 1.5
             }
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
    
}

function reloadRSI(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0]
    var tdata = data[1]
    tdata = tdata['Technical Analysis: RSI'];
    var dates = data[2].slice(0, 121).reverse()
    var rsiData = [];
    for (let i = 0; i < 121; i++) {
        rsiData[i] = parseFloat(tdata[dates[i]].RSI);
    }
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    var options = {
    chart: {
    type: 'line',
    zoomType: "x"
    },
    title: {
    text: 'Relative Strength Index (RSI)'
    },
    subtitle: {
    useHTML: true,
    text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
    },
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
    yAxis: {
    tickAmount: 8,
    title: {
    text: 'RSI'
    }
    },
    tooltip: {
    shared: false
    },
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
    plotOptions: {
    line: {
    dataLabels: {
    enabled: false
    },
    marker: {
    lineWidth: 0,
    enabled: false,
    symbol: 'square',
    states: {
    hover: {
    enabled: true
    }
    }
    }
    }
    },
    series: [{
             name: symbol,
             data: rsiData,
             color: '#66a9ff',
             lineWidth: 2,
             marker: {
             radius: 1.5
             }
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
    
}

function reloadSMA(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0]
    var dates = data[2].slice(0, 121).reverse()
    var SMAData = [];
    var smaData = data[1]['Technical Analysis: SMA'];
    
    for (let i = 0; i < 121; i++) {
        SMAData[i] = parseFloat(smaData[dates[i]].SMA);
        
    }
    
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    var options = {
    chart: {
    type: 'line',
    zoomType: "x"
    },
        
    title: {
    text: 'Simple Moving Average (SMA)'
    },
        
    subtitle: {
    useHTML: true,
    text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
    },
        
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
        
    yAxis: {
        
    tickAmount: 5,
    title: {
    text: 'SMA'
    }
    },
        
    tooltip: {
    shared: false
    },
        
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
        
    plotOptions: {
    line: {
    dataLabels: {
    enabled: false
    },
    marker: {
    lineWidth: 0,
    enabled: false,
    symbol: 'square',
    states: {
    hover: {
    enabled: true
    }
    }
    }
    }
    },
        
    series: [{
             name: symbol,
             data: SMAData,
             color: '#66a9ff',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
    
}

function reloadSTOCH(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0]
    var dates = data[2].slice(0, 121).reverse()
    
    var slowd = [];
    var slowk = [];
    
    var data = data[1]['Technical Analysis: STOCH'];
    for (let i = 0; i < 121; i++) {
        slowd[i] = parseFloat(data[dates[i]].SlowD);
        slowk[i] = parseFloat(data[dates[i]].SlowK);
    }
    
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    
    var options = {
    chart: {
    type: 'line',
    zoomType: "x"
    },
        
    title: {
    text: 'Stochastic Oscillator (STOCH)'
    },
        
    subtitle: {
    useHTML: true,
    text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
    },
        
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
        
    yAxis: {
        
    tickAmount: 6,
    title: {
    text: 'STOCH'
    }
    },
        
    tooltip: {
    shared: false
    },
        
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
        
    plotOptions: {
    line: {
    dataLabels: {
    enabled: false
    },
    marker: {
    lineWidth: 0,
    enabled: false,
    symbol: 'square',
    states: {
    hover: {
    enabled: true
    }
    }
    }
    }
    },
        
    series: [{
             name: symbol + " SlowK",
             data: slowk,
             color: '#ffb24d',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             },
             {
             name: symbol + " SlowD",
             data: slowd,
             color: '#66a9ff',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
    
}

function reloadEMA(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0]
    var dates = data[2].slice(0, 121).reverse()
    
    var emaData = data[1]['Technical Analysis: EMA'];
    var EMAData = [];
    
    for (let i = 0; i < 121; i++) {
        EMAData[i] = parseFloat(emaData[dates[i]].EMA);
        
    }
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    var options = {
    chart: {
    type: 'line',
    zoomType: "x"
    },
        
    title: {
    text: 'Exponential Moving Average (EMA)'
    },
        
    subtitle: {
    useHTML: true,
    text: '<a class="subtitle" href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
    },
        
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
        
    yAxis: {
        
    tickAmount: 5,
    title: {
    text: 'EMA'
    }
    },
        
    tooltip: {
    shared: false
    },
        
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
        
    plotOptions: {
    line: {
    dataLabels: {
    enabled: false
    },
    marker: {
    lineWidth: 0,
    enabled: false,
    symbol: 'square',
    states: {
    hover: {
    enabled: true
    }
    }
    }
    }
    },
        
    series: [{
             name: symbol,
             data: EMAData,
             color: '#66a9ff',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
    
}

function reloadCCI(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0]
    var dates = data[2].slice(0, 121).reverse()
    
    var cciData = data[1]['Technical Analysis: CCI'];
    var CCIData = [];
    
    for (let i = 0; i < 121; i++) {
        CCIData[i] = parseFloat(cciData[dates[i]].CCI);
        
    }
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    var options = {
    chart: {
    type: 'line',
    zoomType: "x"
    },
        
    title: {
    text: 'Commodity Channel Index (CCI)'
    },
        
    subtitle: {
    useHTML: true,
    text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
    },
        
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
        
    yAxis: {
        
    tickAmount: 4,
    title: {
    text: 'CCI'
    }
    },
        
    tooltip: {
    shared: false
    },
        
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
        
    plotOptions: {
    line: {
    dataLabels: {
    enabled: false
    },
    marker: {
    lineWidth: 0,
    enabled: false,
    symbol: 'square',
    states: {
    hover: {
    enabled: true
    }
    }
    }
    }
    },
        
    series: [{
             name: symbol,
             data: CCIData,
             color: '#66a9ff',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
    
}

function reloadBBANDS(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0];
    
    var dates = data[2].slice(0, 121).reverse();
    var BBANDSData = [];
    var bdata = data[1]['Technical Analysis: BBANDS'];
    var lower = [];
    var upper = [];
    var middle = [];
    
    for (let i = 0; i < 121; i++) {
        middle[i] =parseFloat(bdata[dates[i]]['Real Middle Band']);
        upper[i] = parseFloat(bdata[dates[i]]['Real Upper Band']);
        lower[i] = parseFloat(bdata[dates[i]]['Real Lower Band']);
    }
    
    
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    
    var options = {
    chart: {
    type: 'line',
    zoomType: "x"
    },
        
    title: {
    text: 'Bollinger Bands (BBANDS)'
    },
        
    subtitle: {
    useHTML: true,
    text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
    },
        
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
        
    yAxis: {
        
    tickAmount: 5,
    title: {
    text: 'BBANDS'
    }
    },
        
    tooltip: {
    shared: false
    },
        
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
        
    plotOptions: {
    line: {
    dataLabels: {
    enabled: false
    },
    marker: {
    lineWidth: 0,
    enabled: false,
    symbol: 'square',
    states: {
    hover: {
    enabled: true
    }
    }
    }
    }
    },
        
    series: [{
             name: symbol + ' Real Middle Band',
             data: middle,
             color: '#ffc34d',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             },{
             name: symbol + ' Real Upper Band',
             data: upper,
             color: '#66a9ff',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             },{
             name: symbol + ' Real Lower Band',
             data: lower,
             color: '#ff0000',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
    
}

function reloadADX(sBinaryParam) {
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data[0];
    var ADXData = [];
    var dates = data[2].slice(0, 121).reverse()
    
    var adxData = data[1]['Technical Analysis: ADX'];
    for (let i = 0; i < 121; i++) {
        ADXData[i] = parseFloat(adxData[dates[i]]["ADX"]);
    }
    
    dates = dates.map(data => data.substring(5, 10).replace('-', '/'));
    var options = {
    chart: {
    type: 'line',
    zoomType: "x"
    },
        
    title: {
    text: 'Average Directional movement indeX (ADX)'
    },
        
    subtitle: {
    useHTML: true,
    text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
    },
        
    xAxis: {
    categories: dates,
    tickInterval: 5
    },
        
    yAxis: {
        
    tickAmount: 8,
    title: {
    text: 'ADX'
    }
    },
        
    tooltip: {
    shared: false
    },
        
    legend: {
    layout: 'horizontal',
    align: 'center',
    verticalAlign: 'bottom'
    },
        
    plotOptions: {
    line: {
    dataLabels: {
    enabled: false
    },
    marker: {
    lineWidth: 0,
    enabled: false,
    symbol: 'square',
    states: {
    hover: {
    enabled: true
    }
    }
    }
    }
    },
        
    series: [{
             name: symbol,
             data: ADXData,
             color: '#66a9ff',
             lineWidth: 2,
             marker:
             {
             radius: 1.5
             }
             }],
    };
    
    // send options back to Swift
    callNativeApp(options);
    
    // plot
    Highcharts.chart('container', options); // plot Highcharts
    
}

</script>
</head>

<body>
<div style="width: 100%; height:100%;" id="container"></div>
</body>

</html>



