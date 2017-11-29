//
//  ViewController.swift
//  Stock
//
//  Created by Nick on 11/23/17.
//  Copyright © 2017 Xinyu Chen. All rights reserved.
//

import UIKit
import Toaster

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
        let light = NSMutableAttributedString(string:text, attributes: attrs)
        append(light)
        
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
    @IBOutlet weak var inputField: UITextField!
    private let myArray: NSArray = ["First","Second","Third"]
    private var myTableView: UITableView!
    
    // clear button clicked
    @IBAction func clear(_ sender: Any) {
        self.inputField.text = ""
        self.autolist = []
    }
    
    @IBOutlet weak var submitButton: UIButton!
    
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
        
        inputField.delegate = self
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
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(40)
//    }
    
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < autolist.count {
            if let item = autolist[indexPath.row] as? [String: String] {
                inputField.text = "\(item["Symbol"]!) - \(item["Name"]!) (" + item["Exchange"]! + ")"
                self.myTableView.isHidden = true
                self.autolist = []
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autolist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
            // TODO: INDEX OUT OF RANGE EXCEPTION HERE
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


