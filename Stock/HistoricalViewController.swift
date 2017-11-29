//
//  HistoricalViewController.swift
//  Stock
//
//  Created by Nick on 11/25/17.
//  Copyright © 2017 Xinyu Chen. All rights reserved.
//

import UIKit
import WebKit

class HistoricalViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    
    var historicalData: [String: AnyObject] = [:]
    
    @IBOutlet weak var activityIndicator: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 238/255, green: 243/255, blue: 249/255, alpha: 255/255)

        setUpWebView()
        
        let when = DispatchTime.now() + 1 // delay 1 second
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.evaluateJavaScriptForData(dictionaryData: self.historicalData)
            self.activityIndicator.isHidden = true
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpWebView() {
        // setup webView
        webView.scrollView.bounces = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        loadHTML()
    }
    
    func loadHTML() {
        let jsfile = loadFile("historical")
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
    
    func evaluateJavaScriptForData(dictionaryData: [String: AnyObject]) {
        // Convert swift dictionary into encoded json
        let serializedData = try! JSONSerialization.data(withJSONObject: dictionaryData, options: .prettyPrinted)
        let encodedData = serializedData.base64EncodedString(options: .endLineWithLineFeed)
        // This WKWebView API to calls 'reloadData' function defined in js
        webView.evaluateJavaScript("reloadData('\(encodedData)')") { (result, error) in
            guard error == nil else {
                print("There was an error in evaluateJavaScriptForData of HistoricalVC")
                print(error)
                return
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
