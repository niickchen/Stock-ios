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
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.bold)]
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

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    var autolist: [AnyObject] = []
    var stocks: [StarredStock] = []
    var stocksBak: [StarredStock] = []
    var favTableUpdateimer: Timer!
    @IBOutlet weak var inputField: UITextField!
    private let myArray: NSArray = ["First","Second","Third"]
    private var myTableView: UITableView!
    
    // clear button clicked
    @IBAction func clear(_ sender: Any) {
        self.inputField.text = ""
        self.autolist = []
        print()
    }
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBAction func switched(_ sender: Any) {
        
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
        
        // init timer
        favTableUpdateimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateFavTable), userInfo: nil, repeats: true)
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(40)
//    }
    
    @objc func updateFavTable() {
        // retrieve core data
        getData()
        if stocksBak != stocks {
            stocksBak = stocks
            favedStockTableView.reloadData()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide top bar
        self.navigationController?.navigationBar.isHidden = true
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
    
    
    
}


