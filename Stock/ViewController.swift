//
//  ViewController.swift
//  Stock
//
//  Created by Nick on 11/23/17.
//  Copyright © 2017 Xinyu Chen. All rights reserved.
//

import UIKit
import Toaster
import CoreData

let SERVER_URL = "http://stocksite-env.us-west-1.elasticbeanstalk.com"
let AUTO_URL = "/autocomplete?input="

extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold)]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        
        return self
    }
    
    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.light)]
        let normal = NSMutableAttributedString(string:text, attributes: attrs)
        append(normal)
        
        return self
    }
    
    @discardableResult func light(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.light), .foregroundColor: UIColor.lightGray]
        let light = NSMutableAttributedString(string:text, attributes: attrs)
        append(light)
        
        return self
    }
    
    @discardableResult func compact(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 5, weight: UIFont.Weight.light), .foregroundColor: UIColor.black]
        let compact = NSMutableAttributedString(string:text, attributes: attrs)
        append(compact)
        
        return self
    }
    
    @discardableResult func green(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium), .foregroundColor: UIColor(red: 0/255, green: 153/255, blue: 51/255, alpha: 255/255)]
        let green = NSMutableAttributedString(string:text, attributes: attrs)
        append(green)
        
        return self
    }
    
    @discardableResult func red(_ text: String) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium), .foregroundColor: UIColor.red]
        let red = NSMutableAttributedString(string:text, attributes: attrs)
        append(red)
        
        return self
    }
}

//// This way you'll never hit Index out of range
//extension Collection where Indices.Iterator.Element == Index {
//    subscript (safe index: Index) ->  Element? {
//        return indices.contains(index) ? self[index] : nil
//    }
//}

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    // autocompletion result list
    var autolist: [AnyObject] = []
    // faved stocks
    var stocks: [StarredStock] = []
    var timer: Timer?
    
    
    @IBOutlet weak var inputField: UITextField!
    private let myArray: NSArray = ["First","Second","Third"]
    private var myTableView: UITableView!
    
    // the value to be sent via segue by clicking table cells
    var tableCellSymbol = ""
    
    let sortbyPickerData = ["Default", "Symbol", "Price", "Change", "Change(%)"]
    
    let orderPickerData = ["Ascending", "Descending"]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // hide picker row lines
        pickerView.subviews.forEach({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == sortPicker {
            return 5
        } else {
            return orderPickerData.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == sortPicker {
            return sortbyPickerData[row]
        } else {
            return orderPickerData[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.sortData()
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "Arial", size: 20.0)
            pickerLabel?.textAlignment = .center
        }
        if pickerView == sortPicker {
            pickerLabel?.text = sortbyPickerData[row]
        } else {
            pickerLabel?.text = orderPickerData[row]
        }
        return pickerLabel!
    }
    
    func sortData() {
        
    }
    
    // clear button clicked
    @IBAction func clear(_ sender: Any) {
        self.inputField.text = ""
        self.autolist = []
        // clear url tasks. called from autocompletion
        URLSession.shared.getAllTasks{ (openTasks: [URLSessionTask]) in
            print("Number of open tasks: \(openTasks.count)")
            //openTasks.removeAll()
            for task in openTasks {
                task.cancel()
            }
        }
    }
    
    @IBOutlet weak var orderPicker: UIPickerView!
    @IBOutlet weak var sortPicker: UIPickerView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func refreshData(delayTime: Double) {
        
        
        // do nothing if auto refresh is on or no faved stocks
        if self.switch.isOn || self.stocks.count == 0 {
            return
        }
        
        self.activityIndicator.isHidden = false
        
        for stock in stocks {
            fetchData(symbol: stock.symbol!, url: TIME_SERIES_DAILY_URL)
        }
        
        
        // waiting for data
        let when = DispatchTime.now() + delayTime // delay delayTime seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.favedStockTableView.reloadData()
            self.activityIndicator.isHidden = true
        }
        
    }
    
    @IBAction func refresh(_ sender: Any) {
        refreshData(delayTime: 7)
    }
    @IBOutlet weak var submitButton: UIButton!
    
    @IBAction func autorefresh(_ sender: Any) {
        if self.switch.isOn {
            timer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(updateDataEveryFiveSeconds), userInfo: nil, repeats: true)
        }
            
        else {
            timer?.invalidate()
            timer = nil
        }
        
        
    }
    
    @IBOutlet weak var `switch`: UISwitch!
    
    // get quote button clicked
    @IBAction func submit(_ sender: Any) {
        self.view.endEditing(true)
        // if empty input
        if self.inputField.text == nil || self.inputField.text?.replacingOccurrences(of: " ", with: "") == "" {
            displayToastMessage("Please enter a stock name or symbol.")
            self.inputField.text = ""
            self.autolist = []
        }
        // if input is valid, transition to the detail view
        else {
            performSegue(withIdentifier: "detail", sender: self.submitButton)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "detail" {
            if let toViewController = segue.destination as? DetailViewController {
                var fullinputArr = inputField.text?.uppercased().replacingOccurrences(of: " ", with: "").split(separator: "-")
                toViewController.input = String(fullinputArr![0])
            }
        } else if segue.identifier == "cellToDetail" {
            if let toViewController = segue.destination as? DetailViewController {
                toViewController.input = tableCellSymbol
            
            }
        }
    }
    
    @objc func updateDataEveryFiveSeconds() {
        
        self.activityIndicator.isHidden = false
        
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.activityIndicator.isHidden = true
            self.favedStockTableView.reloadData()
        }
        
        for stock in stocks {
            fetchData(symbol: stock.symbol!, url: TIME_SERIES_DAILY_URL)
        }
    }
    
    func displayAlert(_ userMessage: String) {
        let alertController = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("alert")
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func displayToastMessage(_ userMessage: String) {
        let toast = Toast(text: userMessage)
        ToastView.appearance().bottomOffsetPortrait = CGFloat(160)
        ToastView.appearance().font = UIFont(name: "AvenirNext-Medium", size: 17)
        toast.show()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 238/255, green: 243/255, blue: 249/255, alpha: 255/255)
        
        // retrieve core data
        getData()
        
        // off switch
        self.switch.setOn(false, animated: false)
        
        inputField.delegate = self
        inputField.layer.borderColor = UIColor(red: 87/255, green: 175/255, blue: 244/255, alpha: 255/255).cgColor
        
        // setup my table view aka autocomplete table view
        // autocomplete table
        myTableView = UITableView(frame: CGRect(x: inputField.frame.origin.x, y: inputField.frame.origin.y + inputField.frame.height, width: inputField.frame.width, height: CGFloat(0)))
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        myTableView.dataSource = self
        myTableView.delegate = self
        // separator sets to clear
        myTableView.separatorColor = UIColor.clear
        // border color
        myTableView.layer.masksToBounds = true
        myTableView.layer.borderColor = UIColor(red: 224/255, green: 224/255, blue:224/255, alpha: 1.0 ).cgColor
        myTableView.layer.borderWidth = 0.5
        
        
        myTableView.estimatedRowHeight = 40
        myTableView.rowHeight = UITableViewAutomaticDimension
        self.view.addSubview(myTableView)
        self.myTableView.isHidden = true
        
        // setup fav table view
        favedStockTableView.dataSource = self
        favedStockTableView.delegate = self
        favedStockTableView.rowHeight = 60
        favedStockTableView.register(UITableViewCell.self, forCellReuseIdentifier: "sCell")
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.favedStockTableView.bounds.size.width, height: self.favedStockTableView.bounds.size.height))
        backgroundView.backgroundColor = UIColor(red: 238/255, green: 243/255, blue: 249/255, alpha: 255/255)
        self.favedStockTableView.backgroundView = backgroundView
        favedStockTableView.reloadData()
        
        self.switch.onTintColor = UIColor(red: 87/255, green: 175/255, blue: 244/255, alpha: 255/255)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        URLSession.shared.getAllTasks{ (openTasks: [URLSessionTask]) in
//            print("Number of open tasks: \(openTasks.count)")
//            //openTasks.removeAll()
//            for task in openTasks {
//                task.cancel()
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide top bar
        self.navigationController?.navigationBar.isHidden = true
        
        // update stock table
        getData()
        favedStockTableView.reloadData()
        
        refreshData(delayTime: 2)
    }
    
    
//    func shouldPerformSegueWithIdentifier(_ identifier: String!,
//                                          sender sender: AnyObject!) -> Bool {
//
//    }
    
    
    @IBOutlet weak var favedStockTableView: UITableView!
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == myTableView {
            if indexPath.row < autolist.count {
                if let item = autolist[indexPath.row] as? [String: String] {
                    inputField.text = "\(item["Symbol"]!) - \(item["Name"]!) (" + item["Exchange"]! + ")"
                    self.myTableView.isHidden = true
                    self.autolist = []
                }
            }
        }
            
        else if tableView == favedStockTableView {
            tableView.deselectRow(at: indexPath, animated: true)
            tableCellSymbol = (favedStockTableView.cellForRow(at: indexPath)?.viewWithTag(100) as! UILabel).text ?? ""
            performSegue(withIdentifier: "cellToDetail", sender: self.favedStockTableView.cellForRow(at: indexPath))
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    // slide to delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        if tableView == favedStockTableView && editingStyle == .delete {
            
            // delete from core data
                let label = tableView.cellForRow(at: indexPath)?.viewWithTag(100) as! UILabel
            let objs = get(withPredicate: NSPredicate(format: "symbol == %@", label.text!))
                for obj in objs {
                    context.delete(obj)
                }
            
            
            // update local data variable
            getData()
            
            favedStockTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == myTableView {
            return autolist.count
        }
        
        else {
            
            
            return stocks.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == myTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
            if indexPath.row < autolist.count {
                if let item = autolist[indexPath.row] as? [String: String] {
                    let formattedString = NSMutableAttributedString()
                    formattedString.bold(item["Symbol"]!).normal(" - \(item["Name"] ?? "")").normal(" (\(item["Exchange"] ?? ""))")
                    cell.textLabel!.attributedText = formattedString
                }
            }
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "sCell", for: indexPath as IndexPath)
            
            if let symbolLabel = cell.viewWithTag(100) as? UILabel {
                symbolLabel.text = stocks[indexPath.row].symbol
            }
            else {
                let symbolLabel = UILabel(frame: CGRect(x: 20, y: 21, width: 50, height: 19))
                symbolLabel.textColor = UIColor(red: 29/255, green: 41/255, blue: 81/255, alpha: 255/255)
                symbolLabel.textAlignment = .center
                symbolLabel.tag = 100
                symbolLabel.text = stocks[indexPath.row].symbol
                cell.contentView.addSubview(symbolLabel)
            }
            
            if let priceLabel = cell.viewWithTag(200) as? UILabel {
                priceLabel.text = "$\(stocks[indexPath.row].price ?? "")"
            }
            else {
                let priceLabel = UILabel(frame: CGRect(x: 100, y: 21, width: 70, height: 19))
                priceLabel.textColor = UIColor(red: 29/255, green: 41/255, blue: 81/255, alpha: 255/255)
                priceLabel.textAlignment = .center
                priceLabel.tag = 200
                priceLabel.text = "$\(stocks[indexPath.row].price ?? "")"
                cell.contentView.addSubview(priceLabel)
            }
            
            if let changeLabel = cell.viewWithTag(300) as? UILabel {
                let formattedString = NSMutableAttributedString()
                if Double(stocks[indexPath.row].change?.components(separatedBy: " ")[0] ?? "0")! > 0 {
                    formattedString.green(stocks[indexPath.row].change!)
                    changeLabel.attributedText = formattedString
                } else if Double(stocks[indexPath.row].change?.components(separatedBy: " ")[0] ?? "0")! < 0 {
                    formattedString.red(stocks[indexPath.row].change!)
                    changeLabel.attributedText = formattedString
                } else {
                    changeLabel.text = "0.00 (0.00%)"
                    changeLabel.textColor = UIColor(red: 29/255, green: 41/255, blue: 81/255, alpha: 255/255)
                }
            }
            else {
                let changeLabel = UILabel(frame: CGRect(x: 190, y: 21, width: 150, height: 19))
                changeLabel.textAlignment = .center
                changeLabel.tag = 300
                let formattedString = NSMutableAttributedString()
                if Double(stocks[indexPath.row].change?.components(separatedBy: " ")[0] ?? "0")! > 0 {
                    formattedString.green(stocks[indexPath.row].change!)
                    changeLabel.attributedText = formattedString
                } else if Double(stocks[indexPath.row].change?.components(separatedBy: " ")[0] ?? "0")! < 0 {
                    formattedString.red(stocks[indexPath.row].change!)
                    changeLabel.attributedText = formattedString
                } else {
                    changeLabel.text = "0.00 (0.00%)"
                    changeLabel.textColor = UIColor(red: 29/255, green: 41/255, blue: 81/255, alpha: 255/255)
                }
                cell.contentView.addSubview(changeLabel)
            }
            
            cell.backgroundColor = UIColor.clear
            
            
            return cell
        }
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let txtAfterUpdate = text.replacingCharacters(in: range, with: string)
            getAutoComList(text: txtAfterUpdate)
            
            self.myTableView.reloadData()
        }
        return true
    }

    
    // touch outside and dismiss keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (myTableView != nil) {
            myTableView.isHidden = false
            self.myTableView.frame = CGRect(x: self.inputField.frame.origin.x, y: self.inputField.frame.origin.y + self.inputField.frame.height, width: self.inputField.frame.width, height: CGFloat(50 * self.autolist.count))
            // reload tableview data
            self.myTableView.reloadData()
            getAutoComList(text: inputField.text)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        // Hide the autocorrection suggestion table
        if (self.myTableView != nil) {
            self.myTableView.isHidden = true
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Hide the autocorrection suggestion table
        if (self.myTableView != nil) {
            self.myTableView.isHidden = true
        }
        
        
    }
    
    func getAutoComList(text: String?) -> Void {
        func reloadTable() -> Void {
            DispatchQueue.main.async {
                // update tableview height
                self.myTableView.frame = CGRect(x: self.inputField.frame.origin.x, y: self.inputField.frame.origin.y + self.inputField.frame.height, width: self.inputField.frame.width, height: CGFloat(50 * self.autolist.count))
                // reload tableview data
                self.myTableView.reloadData()
            }
        }
        
        if text == nil || text?.replacingOccurrences(of: " ", with: "")=="" {
            self.autolist = []
            reloadTable()
            return
        }
        let urlstring = (SERVER_URL + AUTO_URL + text!).replacingOccurrences(of: " ", with: "")
        let requestURL = URL(string: urlstring)

        var request = URLRequest(url: requestURL ?? URL(string: SERVER_URL + AUTO_URL)!)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: requestURL ?? URL(string: SERVER_URL + AUTO_URL)!){
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET")
                print(error!)
                self.autolist = []
                reloadTable()
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                self.autolist = []
                reloadTable()
                return
            }
            // parse the result as JSON, since that's what the API provides
            do {
                guard let list = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [AnyObject] else {
                        print("error trying to convert data to JSON")
                        print("autocomplete")
                        self.autolist = []
                        reloadTable()
                        return
                }

                if list.count > 5 {
                    self.autolist = Array(list[0..<5])
                } else {
                    self.autolist = list
                }
                
                reloadTable()
                
                
            } catch  {
                print("error trying to convert data to JSON")
                print("autocomplete")
                self.autolist = []
                reloadTable()
                return
            }
        }

        task.resume()
    }
    
    func fetchData(symbol: String, url: String) {
        // get URL string
        let urlstring = (SERVER_URL + url + symbol)
        let requestURL = URL(string: urlstring)
        
        // make http get request
        var request = URLRequest(url: requestURL ?? URL(string: SERVER_URL + AUTO_URL)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: requestURL ?? URL(string: SERVER_URL + AUTO_URL)!){
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("Error calling GET")
                print(error!)
                self.displayToastMessage("Error updating one stock value.")
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                self.displayToastMessage("Error updating one stock value.")
                return
            }
            // parse the result as JSON
            do {
                guard let json = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: AnyObject] else {
                        print("Error trying to convert data to JSON dictionary")
                        self.displayToastMessage("Error updating one stock value.")
                        return
                }
                
                // if json contains error message
                if json["Error Message"] != nil || json.count == 0 {
                    self.displayToastMessage("Error updating one stock value.")
                    return
                }
                
                let data = self.processTableData(tsdData: json)
                
                // extract data if no error
                let objs = self.get(withPredicate: NSPredicate(format: "symbol == %@", data["symbol"]!))
                
                print("\(data)")
                // update core data
                for obj in objs {
                    self.updateData(obj: obj, data: data)
                }
                
                // update local data
                self.getData()
                
                
            } catch  {
                self.displayToastMessage("Error updating one stock value.")
                print("Error trying to convert data to JSON")
                return
            }
        }
        
        task.resume()
    }
    
    // update core data
    func updateData(obj: StarredStock, data: [String: String]) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let stock = obj
        // update core data
        stock.price = data["price"]
        stock.change = data["change"]
        stock.volume = data["volume"]
        // Save the data to coredata
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    // return dates of stock prices in descending order
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
    
    func processTableData(tsdData: [String: AnyObject]) -> [String: String] {
        // process table data
        var metadata = tsdData["Meta Data"] as? [String: String] ?? [:]
        var tsd = tsdData["Time Series (Daily)"] as? [String: [String: String]] ?? [:]
        if tsd.count > 0 {
            //update row data
            let dates = getDates(tsd as [String : AnyObject])
            let lastDayData = tsd[dates[0]]!
            let previousDayData = tsd[dates[1]]!
            let lastPrice = Double(lastDayData["4. close"]!)
            let lastClose = Double(previousDayData["4. close"]!)
            let changeValue = lastPrice! - lastClose!
            let changePercent = changeValue / lastClose! * 100
            
            let symbol = metadata["2. Symbol"]
            let price = String(format: "%.2f", lastPrice!)
            let change = String(format: "%.2f", changeValue) + " (" + String(format: "%.2f", changePercent) + "%)"
            let volume = Int(lastDayData["5. volume"]!)?.formattedWithSeparator
            let obj: [String : String] = ["symbol": symbol!, "price": price, "change": change, "volume": volume!]
            
            return obj
        }
        return [:]
    }
    
    // fetch with predicate
    func get(withPredicate queryPredicate: NSPredicate) -> [StarredStock]{
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<StarredStock> = StarredStock.fetchRequest()
        
        fetchRequest.predicate = queryPredicate
        
        do {
            let response = try context.fetch(fetchRequest)
            return response as! [StarredStock]
            
        } catch let error as NSError {
            // failure
            print(error)
            return [StarredStock]()
        }
    }
    
    
}


