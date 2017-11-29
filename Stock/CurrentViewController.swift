//
//  CurrentViewController.swift
//  Stock
//
//  Created by Nick on 11/25/17.
//  Copyright © 2017 Xinyu Chen. All rights reserved.
//

import UIKit
import WebKit
import Toaster
import FacebookShare

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: range.lowerBound)
        let idx2 = index(startIndex, offsetBy: range.upperBound)
        return String(self[idx1..<idx2])
    }
    var count: Int { return characters.count }
}

extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension BinaryInteger {
    var formattedWithSeparator: String {
        return Formatter.withSeparator.string(for: self) ?? ""
    }
}

class CurrentViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate, WKScriptMessageHandler {
    

    var stockdata: [String: [String: AnyObject]] = [:]
    var error: [String: Bool] = [:]
    var input: String = ""
    var tsdData: [String: AnyObject] = [:]
    var tsdError = false
    
    var timer: Timer?
    var fbTimer: Timer?
    var loaded = false
    
    let rowNumber = 8
    var change: Int = 0
    let numOfPickerComponents = 1
    var selectedPickerValue = 0 // the value picker picked, may not be changed to currently
    var dates: [String] = []
    var currentValidPickerValue = 0 // the value changed to
    
    var plotOptions = ""
    var chartLink = ""
    
    // This is bad. This is real bad.
    // TODO: Should have used customized cell to implement two columns.
    let rowHeader = ["Stock Symbol      ", "Last Price              ", "Change                  ", "Timestamp           ", "Open                       ", "Close                      ", "Day's Range         ", "Volume                   "]
    var rowContent: [String] = ["", "", "", "", "", "", "", ""]
    let pickerData = ["Price", "SMA", "EMA", "STOCH", "RSI", "ADX", "CCI", "BBANDS", "MACD"]
    let urls = [TIME_SERIES_DAILY_URL, SMA_URL, EMA_URL, STOCH_URL, RSI_URL, ADX_URL, CCI_URL, BBANDS_URL, MACD_URL]
    
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var picker: UIPickerView!
    
    @IBAction func change(_ sender: Any) {
        switch selectedPickerValue {
        case 0:
            // symbol, data, dates
            currentValidPickerValue = 0
            loaded = false
            
        case 1:
            currentValidPickerValue = 1
            loaded = false
            
        case 2:
            currentValidPickerValue = 2
            loaded = false
            
        case 3:
            currentValidPickerValue = 3
            loaded = false
            
        case 4:
            currentValidPickerValue = 4
            loaded = false
            
        case 5:
            currentValidPickerValue = 5
            loaded = false
            
        case 6:
            currentValidPickerValue = 6
            loaded = false
            
        case 7:
            currentValidPickerValue = 7
            loaded = false
            
        case 8:
            currentValidPickerValue = 8
            loaded = false
            
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loaded = false
        
        // Do any additional setup after loading the view.
        setupTableView()
        setUpWebView()
        setupPickerView()
        
        // plot charts
        var when = DispatchTime.now() + 2 // delay 2 seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            if !self.tsdError {
                let data = [self.rowContent[0], self.tsdData, self.dates] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadPrice")
            }
        }
        
        when = when + 0.5
        DispatchQueue.main.asyncAfter(deadline: when) {
            if !self.tsdError {
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                self.retrieveChartPicture()
                
                //self.activityIndicator.isHidden = true
            }
            
            
            // fetch indicator data
            self.fetchData(SMA_URL)
            self.fetchData(EMA_URL)
            self.fetchData(STOCH_URL)
            self.fetchData(RSI_URL)
            self.fetchData(ADX_URL)
            self.fetchData(CCI_URL)
            self.fetchData(BBANDS_URL)
            self.fetchData(MACD_URL)
        }
        
        
        
        // timer to check if received data
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.dismissSpinnerAndShowCharts), userInfo: nil, repeats: true)
    }
    
    @IBOutlet weak var star: UIButton!
    @IBAction func starred(_ sender: Any) {
    }
    @IBAction func shareToFacebook(_ sender: Any) {
        if currentValidPickerValue == 0 {
            if loaded && !self.tsdError {
                // timer to check if received link
                fbTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.receivedLinkAndPostToFaceBook), userInfo: nil, repeats: true)
            }
        } else{
            if loaded && !self.error[self.urls[currentValidPickerValue]]! {
                // timer to check if received link
                fbTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.receivedLinkAndPostToFaceBook), userInfo: nil, repeats: true)
            }
        }
        
    }
    
    func invokeFacebookShareDialog(link: String) {
        // FB SDK to invoke share dialog
        let content = LinkShareContent(url: URL(string: link)!)
        let shareDialog = ShareDialog(content: content)
        shareDialog.failsOnInvalidData = true
        shareDialog.completion = { result in
            // Handle share results
        }

        try? shareDialog.show()
        
    }
    
    @objc func receivedLinkAndPostToFaceBook() {
        if chartLink == "Error" {
            fbTimer?.invalidate()
            fbTimer = nil
            displayToastMessage("Error sharing to Facebook")
        } else if chartLink.count > 5 {
            
            fbTimer?.invalidate()
            fbTimer = nil
            invokeFacebookShareDialog(link: chartLink)
        }
    }
    
    func retrieveChartPicture() {
        let urlstring = SERVER_URL + FACEBOOK_SHARE_URL
        let url = URL(string: urlstring)
        if plotOptions.count > 0 {
            httpPost(datastring: "['title':['text':'Solar Employment Growth by Sector, 2010-2016']", url: url!)
        }
    }
    
    func httpPost(datastring: String, url: URL) {
        if datastring.count > 0 {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = datastring.data(using: .utf8)
            
            URLSession.shared.getAllTasks { (openTasks: [URLSessionTask]) in
                NSLog("open tasks: \(openTasks)")
            }
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                // check for any errors
                guard error == nil else {
                    self.chartLink = "Error"
                    print("error calling POST")
                    return
                }
                // make sure we got data
                guard let responseData = data else {
                    self.chartLink = "Error"
                    print("Error: did not receive data. [POST]")
                    return
                }
                // parse the result as JSON, since that's what the API provides
                do {
                    guard let json = try JSONSerialization.jsonObject(with: responseData, options: [])
                        as? [String: AnyObject] else {
                            self.chartLink = "Error"
                            print("error trying to convert data to JSON dictionary. [POST]")
                            
                            return
                    }
            
                    
                    // extract data if no error
                    self.chartLink = json["link"] as! String
                    
                    
                } catch {
                    self.chartLink = "Error"
                    print("error trying to convert data to JSON. [POST]")
                    return
                }
            })
            task.resume()
        }
    }
    
    func displayToastMessage(_ userMessage: String) {
        let toast = Toast(text: userMessage)
        ToastView.appearance().bottomOffsetPortrait = CGFloat(160)
        ToastView.appearance().font = UIFont(name: "AvenirNext-Medium", size: 17)
        toast.show()
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @objc func dismissSpinnerAndShowCharts() {
        if loaded {
            return
        }
        webView.isHidden = true
        activityIndicator.isHidden = false
        
        
        switch currentValidPickerValue {
        case 0:
            if !tsdError {
                let data = [self.rowContent[0], self.tsdData, self.dates] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadPrice")
                loaded = true
                webView.isHidden = false
                activityIndicator.isHidden = true
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                // clear plot options
                plotOptions = ""
            }
        case 1:
            if self.error[SMA_URL] != nil && !self.error[SMA_URL]! {
                let tdata = self.stockdata[SMA_URL]!
                let data = [self.rowContent[0], tdata, getDates(tdata["Technical Analysis: SMA"] as! [String : AnyObject])] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadSMA")
                loaded = true
                
                activityIndicator.isHidden = true
                webView.isHidden = false
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else if self.error[SMA_URL] != nil && self.error[SMA_URL]! {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                // clear plot options
                plotOptions = ""
            }
            
        case 2:
            if self.error[EMA_URL] != nil && !self.error[EMA_URL]! {
                let data = [self.rowContent[0], self.stockdata[EMA_URL]!, getDates(self.stockdata[EMA_URL]!["Technical Analysis: EMA"] as! [String : AnyObject])] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadEMA")
                loaded = true
                activityIndicator.isHidden = true
                webView.isHidden = false
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else if self.error[EMA_URL] != nil && self.error[EMA_URL]! {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                plotOptions = ""
            }
        case 3:
            if self.error[STOCH_URL] != nil && !self.error[STOCH_URL]! {
                let data = [self.rowContent[0], self.stockdata[STOCH_URL]!, getDates(self.stockdata[STOCH_URL]!["Technical Analysis: STOCH"] as! [String : AnyObject])] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadSTOCH")
                loaded = true
                activityIndicator.isHidden = true
                webView.isHidden = false
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else if self.error[STOCH_URL] != nil && self.error[STOCH_URL]! {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                plotOptions = ""
            }
        case 4:
            if self.error[RSI_URL] != nil && !self.error[RSI_URL]! {
                let data = [self.rowContent[0], self.stockdata[RSI_URL]!, getDates(self.stockdata[RSI_URL]!["Technical Analysis: RSI"] as! [String : AnyObject])] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadRSI")
                loaded = true
                activityIndicator.isHidden = true
                webView.isHidden = false
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else if self.error[RSI_URL] != nil && self.error[RSI_URL]! {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                plotOptions = ""
            }
        case 5:
            if self.error[ADX_URL] != nil && !self.error[ADX_URL]! {
                let data = [self.rowContent[0], self.stockdata[ADX_URL]!, getDates(self.stockdata[ADX_URL]!["Technical Analysis: ADX"] as! [String : AnyObject])] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadADX")
            loaded = true
                activityIndicator.isHidden = true
                webView.isHidden = false
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else if self.error[ADX_URL] != nil && self.error[ADX_URL]! {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                plotOptions = ""
            }
        case 6:
            if self.error[CCI_URL] != nil && !self.error[CCI_URL]! {
                let data = [self.rowContent[0], self.stockdata[CCI_URL]!, getDates(self.stockdata[CCI_URL]!["Technical Analysis: CCI"] as! [String : AnyObject])] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadCCI")
            loaded = true
                activityIndicator.isHidden = true
                webView.isHidden = false
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else if self.error[CCI_URL] != nil && self.error[CCI_URL]! {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                plotOptions = ""
            }
        case 7:
            if self.error[BBANDS_URL] != nil && !self.error[BBANDS_URL]! {
                let data = [self.rowContent[0], self.stockdata[BBANDS_URL]!, getDates(self.stockdata[BBANDS_URL]!["Technical Analysis: BBANDS"] as! [String : AnyObject])] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadBBANDS")
            loaded = true
                activityIndicator.isHidden = true
                webView.isHidden = false
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else if self.error[BBANDS_URL] != nil && self.error[BBANDS_URL]! {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                plotOptions = ""
            }
        case 8:
            if self.error[MACD_URL] != nil && !self.error[MACD_URL]! {
                let data = [self.rowContent[0], self.stockdata[MACD_URL]!, getDates(self.stockdata[MACD_URL]!["Technical Analysis: MACD"] as! [String : AnyObject])] as [Any]
                self.evaluateJavaScriptForData(data: data as [AnyObject], function: "reloadMACD")
            loaded = true
                activityIndicator.isHidden = true
                webView.isHidden = false
                
                // clear chart link
                self.chartLink = ""
                
                // http post to get chart link
                retrieveChartPicture()
            } else if self.error[MACD_URL] != nil && self.error[MACD_URL]! {
                webView.isHidden = true
                loaded = true
                displayToastMessage("Failed to load data and display the chart.")
                activityIndicator.isHidden = true
                plotOptions = ""
            }
        default:
            break
        }
    }
    
    func fetchData(_ url: String) {
        // get URL string
        let urlstring = (SERVER_URL + url + input)
        let requestURL = URL(string: urlstring)
        
        // make http get request
        var request = URLRequest(url: requestURL ?? URL(string: SERVER_URL + AUTO_URL)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: requestURL ?? URL(string: SERVER_URL + AUTO_URL)!){
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET")
                print(url)
                print(error!)
                self.error[url] = true
                
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                print(url)
                self.error[url] = true
                return
            }
            // parse the result as JSON, since that's what the API provides
            do {
                guard let json = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: AnyObject] else {
                        print("error trying to convert data to JSON dictionary")
                        print(url)
                        self.error[url] = true
                        
                        return
                }
                
                // if json contains error message
                if json["Error Message"] != nil || json.count == 0 || json["Error"] != nil {
                    print(url)
                    self.error[url] = true
                    return
                }
                
                // extract data if no error
                self.stockdata[url] = json
                self.error[url] = false
                
                
                
            } catch  {
                print("error trying to convert data to JSON")
                print(url)
                self.error[url] = true
                
                return
            }
        }
        
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    func setupPickerView() {
        picker.delegate = self
        picker.dataSource = self
        selectedPickerValue = 0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return numOfPickerComponents
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPickerValue = row
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // process table data
        var metadata = tsdData["Meta Data"] as? [String: String] ?? [:]
        var tsd = tsdData["Time Series (Daily)"] as? [String: [String: String]] ?? [:]
        if tsd.count > 0 {
            dates = getDates(tsd as [String : AnyObject])
            
            let lastDayData = tsd[dates[0]]!
            let previousDayData = tsd[dates[1]]!
            let lastPrice = Double(lastDayData["4. close"]!)
            let open = Double(lastDayData["1. open"]!)
            let lastClose = Double(previousDayData["4. close"]!)
            let high = Double(lastDayData["2. high"]!)
            let low = Double(lastDayData["3. low"]!)
            let volume = Int(lastDayData["5. volume"]!)?.formattedWithSeparator
            let timestamp: String
            let changeValue = lastPrice! - lastClose!
            let changePercent = changeValue / lastClose! * 100
            if changeValue < 0 {
                change = -1
            } else if changeValue > 0 {
                change = 1
            } else {
                change = 0
            }
            
            if metadata["3. Last Refreshed"]!.count > 12 {
                timestamp = metadata["3. Last Refreshed"]! + " EST"
            } else {
                timestamp = metadata["3. Last Refreshed"]! + " 16:00:00 EST"
            }
            
            if metadata["3. Last Refreshed"]!.count > 12 {
                rowContent = [metadata["2. Symbol"] ?? "", String(format: "%.2f", lastPrice!), String(format: "%.2f", changeValue) + " (" + String(format: "%.2f", changePercent) + "%)", timestamp, String(format: "%.2f", open!), String(format: "%.2f", lastClose!), String(format: "%.2f", low!) + String(format: "%.2f", high!), volume!]
            } else {
                rowContent = [metadata["2. Symbol"] ?? "", String(format: "%.2f", lastPrice!), String(format: "%.2f", changeValue) + " (" + String(format: "%.2f", changePercent) + "%)", timestamp, String(format: "%.2f", open!), String(format: "%.2f", lastPrice!), String(format: "%.2f", low!) + " - " + String(format: "%.2f", high!), volume!]
            }
        }
        
        
        
        return rowNumber
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        let formattedString = NSMutableAttributedString()
        formattedString.bold(rowHeader[indexPath.row]).normal(rowContent[indexPath.row])
        cell.textLabel!.attributedText = formattedString
        cell.contentView.layoutMargins.right = 0
        cell.textLabel!.numberOfLines = 0
        cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        // show change indicator arrow
        if indexPath.row == 2 && change > 0 {
            let image: UIImage = UIImage(named: "up_arrow")!
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(x: 235, y: 7, width: 20, height: 20)
            cell.contentView.addSubview(imageView)
        } else if indexPath.row == 2 && change < 0{
            let image: UIImage = UIImage(named: "down_arrow")!
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(x: 235, y: 7, width: 20, height: 20)
            cell.contentView.addSubview(imageView)
        }
        
        return cell
    }

    func getDates(_ dict: [String: AnyObject]) -> [String] {
        var dates = Array(dict.keys)
        dates = dates.sorted { (a, b) -> Bool in
            if (Int(a[0..<4])! < Int(b[0..<4])!) {
                return false;
            }
            else if (Int(a[0..<4])! > Int(b[0..<4])!) {
                return true;
            }
            else {
                if (Int(a[5..<7])! < Int(b[5..<7])!) {
                    return false;
                }
                else if (Int(a[5..<7])! > Int(b[5..<7])!) {
                    return true;
                }
                else {
                    if (Int(a[8..<10])! < Int(b[8..<10])!) {
                        return false;
                    }
                    else if (Int(a[8..<10])! > Int(b[8..<10])!) {
                        return true;
                    }
                    else {
                        return true;
                    }
                }
            } }
        return dates
    }
    
    func setUpWebView() {
        // setup webView
        webView.scrollView.bounces = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        loadHTML()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        fbTimer?.invalidate()
        fbTimer = nil
        timer?.invalidate()
        timer = nil
    }
    
    override func loadView() {
        super.loadView()
        
        // listen for callback from javascript
        self.webView.configuration.userContentController.add(self, name: "callbackHandler")
        
        activityIndicator.color = UIColor.green
    }
    
    func loadHTML() {
        let jsfile = loadFile("current")
        webView.loadHTMLString(jsfile, baseURL: nil)
        
        
    }
    
    func loadFile(_ filename: String) -> String {
        if let path = Bundle.main.path(forResource: filename, ofType: "js")
        {
            do
            {
                let str = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
                return str
            }
            catch
            {
                
            }
        }
        
        return ""
    }
    
    func evaluateJavaScriptForData(data: [AnyObject], function: String) {
        // Convert swift data into encoded json
        let serializedData = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        let encodedData = serializedData.base64EncodedString(options: .endLineWithLineFeed)
        // This WKWebView API to calls 'reloadData' function defined in js
        webView.evaluateJavaScript("\(function)('\(encodedData)')") { (result, error) in
            guard error == nil else {
                print("There was an error in evaluateJavaScriptForData of CurrentVC")
                print(error)
                return
            }
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            if let messageBody: String = message.body as? String {
                plotOptions = messageBody
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
