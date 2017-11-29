<!doctype html>
<html lang="en">

<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://code.jquery.com/jquery-3.1.1.min.js"></script>
<script src="https://code.highcharts.com/stock/highstock.js"></script>
<script src="https://code.highcharts.com/stock/modules/exporting.js"></script>
<script>
// load data from Swift and plot
function reloadData(sBinaryParam) {
    var historyData = [];
    // This 'atob' decodes the Base64 encoded data sent by swift
    var sDecodedParam = window.atob(sBinaryParam);
    var data = JSON.parse(sDecodedParam);
    var symbol = data['Meta Data']
    symbol = symbol['2. Symbol']
    // get 1000 price data points
    var dates = Object.keys(data['Time Series (Daily)'])
    dates.sort(function(a, b) {
               if (parseInt(a.substring(0, 4)) < parseInt(b.substring(0, 4)))
               return 1;
               else if (parseInt(a.substring(0, 4)) > parseInt(b.substring(0, 4)))
               return -1;
               else {
               if (parseInt(a.substring(5, 7)) < parseInt(b.substring(5, 7)))
               return 1;
               else if (parseInt(a.substring(5, 7)) > parseInt(b.substring(5, 7)))
               return -1;
               else {
               if (parseInt(a.substring(8, 10)) < parseInt(b.substring(8, 10)))
               return 1;
               else if (parseInt(a.substring(8, 10)) > parseInt(b.substring(8, 10)))
               return -1;
               else return 0;
               }
               }
               });
    let thousandDates = dates.slice(0, 1000).reverse();
    var timeseries = data['Time Series (Daily)'];
    for (let i = 0; i < thousandDates.length; i++) {
        historyData[i] = [new Date(thousandDates[i]).getTime(), parseFloat((Math.round(
                                                                                       parseFloat(timeseries[thousandDates[i]]['4. close']) * 100) / 100).toFixed(
                                                                                                                                                                  2))];
    }
    // plot
    Highcharts.stockChart('history-container', {
                          rangeSelector: {
                          selected: 0,
                          buttons: [{
                                    type: 'week',
                                    count: 1,
                                    text: '1w'
                                    }, {
                                    type: 'month',
                                    count: 1,
                                    text: '1m'
                                    }, {
                                    type: 'month',
                                    count: 3,
                                    text: '3m'
                                    }, {
                                    type: 'month',
                                    count: 6,
                                    text: '6m'
                                    }, {
                                    type: 'ytd',
                                    text: 'YTD'
                                    }, {
                                    type: 'year',
                                    count: 1,
                                    text: '1y'
                                    }, {
                                    type: 'all',
                                    text: 'All'
                                    }]
                          },
                          
                          chart: {
                             backgroundColor: '#eef3f9',
                          },
                          title: {
                          text: symbol + ' Stock Value'
                          },
                          subtitle: {
                          useHTML: true,
                          text: '<a href="https://www.alphavantage.co/" target="_blank" style="color:#0000EE;"> Source: Alpha Vantage </a>',
                          },
                          tooltip: {
                          shared: false,
                          split: false,
                          enabled: true
                          },
                          series: [{
                                   name: symbol,
                                   data: historyData,
                                   type: 'area',
                                   tooltip: {
                                   valueDecimals: 2
                                   }
                                   }]
                          });
}

</script>
</head>

<body style="background-color: RGB(238,243,249)">
<div style="width: 100%; height:100%;" id="history-container"></div>
</body>

</html>


