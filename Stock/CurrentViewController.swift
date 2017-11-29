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
import CoreData

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
    
    let starredImg = UIImage(named: "Starred")
    let unstarredImg = UIImage(named: "Unstarred")
    var starredStatus = false
    var stocks: [StarredStock] = []
    
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
        if selectedPickerValue != currentValidPickerValue {
            loaded = false
            currentValidPickerValue = selectedPickerValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 238/255, green: 243/255, blue: 249/255, alpha: 255/255)
        
        // fetch core data
        getData()

        loaded = false
        
        // init fav button value
        unFav()
        
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
    
    // fetch core data
    func getData() {
        do {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            stocks = try context.fetch(StarredStock.fetchRequest())
        } catch {
            print("Fetching Failed")
        }
    }
    
    @IBOutlet weak var star: UIButton!
    @IBAction func starred(_ sender: Any) {
        // if data error return
        if tsdData.count == 0 || tsdError {
            return
        }
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        if !starredStatus {
            let stock = StarredStock(context: context) // Link Task & Context
            // save to core data
            stock.symbol = rowContent[0]
            stock.price = rowContent[1]
            stock.change = rowContent[2]
            stock.volume = rowContent[7]
            // Save the data to coredata
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            // update local data
            getData()
            
            // Set fav star
            setFav()
            
        } else {
            for stock in stocks {
                if stock.symbol == rowContent[0] {
                    context.delete(stock)
                    break
                }
            }
            // update local data
            getData()
            
            // Remove fav star
            unFav()
        }
        
    }
    
    func setFav() {
        starredStatus = true
        star.setImage(starredImg, for: .normal)
        star.setBackgroundImage(starredImg, for: .normal)
    }
    
    func unFav() {
        starredStatus = false
        star.setImage(unstarredImg, for: .normal)
        star.setBackgroundImage(unstarredImg, for: .normal)
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
        shareDialog.mode = .automatic
        shareDialog.completion = { result in
            // Handle share results
            self.displayToastMessage("Shared successfully.")
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
            // String to Data, then to Dictionary
            let json = try! JSONSerialization.jsonObject(with: plotOptions.data(using: .utf8)!, options: .allowFragments)
            
            // Then Dictionary to Data. IDK why it has to be like this, or it will fail to be correct Data.
            let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            httpPost(jsondata: data!, url: url!)
        }
    }
    
    func httpPost(jsondata: Data, url: URL) {
        if !jsondata.isEmpty {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsondata
            
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
                
                let when = DispatchTime.now() + 0.5 // delay 0.5 second for plotOptions to be updated
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // http post to get chart link
                    self.retrieveChartPicture()
                }
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
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
        backgroundView.backgroundColor = UIColor(red: 238/255, green: 243/255, blue: 249/255, alpha: 255/255)
        self.tableView.backgroundView = backgroundView
    }
    
    func setupPickerView() {
        picker.delegate = self
        picker.dataSource = self
        selectedPickerValue = 0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // hide picker row lines
        pickerView.subviews.forEach({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
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
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "Arial", size: 20.0)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = pickerData[row]
        
        return pickerLabel!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // process table data
        var metadata = tsdData["Meta Data"] as? [String: String] ?? [:]
        var tsd = tsdData["Time Series (Daily)"] as? [String: [String: String]] ?? [:]
        if tsd.count > 0 {
            
            // update star
            for stock in stocks {
                if stock.symbol == metadata["2. Symbol"] {
                    setFav()
                    break
                }
            }
            
            // update dates, used in charts
            dates = getDates(tsd as [String : AnyObject])
            
            //update row data
            
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
            imageView.frame = CGRect(x: 240, y: 7, width: 20, height: 20)
            cell.contentView.addSubview(imageView)
        } else if indexPath.row == 2 && change < 0{
            let image: UIImage = UIImage(named: "down_arrow")!
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(x: 240, y: 7, width: 20, height: 20)
            cell.contentView.addSubview(imageView)
        }
        
        cell.backgroundColor = UIColor.clear
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
    }
    
    
    override func loadView() {
        super.loadView()
        
        // listen for callback from javascript
        self.webView.configuration.userContentController.add(self, name: "callbackHandler")
        
        activityIndicator.color = UIColor.orange
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
