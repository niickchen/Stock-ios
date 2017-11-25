//
//  DetailViewController.swift
//  Stock
//
//  Created by Nick on 11/24/17.
//  Copyright © 2017 Xinyu Chen. All rights reserved.
//

import UIKit

let SMA_URL = "/quote/sma?symbol=";
let EMA_URL = "/quote/ema?symbol=";
let STOCH_URL = "/quote/stoch?symbol=";
let RSI_URL = "/quote/rsi?symbol=";
let ADX_URL = "/quote/adx?symbol=";
let CCI_URL = "/quote/cci?symbol=";
let BBANDS_URL = "/quote/bbands?symbol=";
let MACD_URL = "/quote/macd?symbol=";
let TIME_SERIES_DAILY_URL = "/quote/time_series_daily?symbol=";
let NEWS_URL = "/news?symbol=";
let FACEBOOK_SHARE_URL = "/share/facebook"

class DetailViewController: UIViewController {
    
    var input: String!
    var stockdata: [String: AnyObject] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        fetchData(TIME_SERIES_DAILY_URL)
        fetchData(SMA_URL)
        fetchData(EMA_URL)
        fetchData(STOCH_URL)
        fetchData(RSI_URL)
        fetchData(ADX_URL)
        fetchData(CCI_URL)
        fetchData(BBANDS_URL)
        fetchData(MACD_URL)
        fetchData(NEWS_URL)
    }
    
    func fetchData(_ url: String) {
        let urlstring = (SERVER_URL + url + input)
        let requestURL = URL(string: urlstring)
        
        var request = URLRequest(url: requestURL ?? URL(string: SERVER_URL + AUTO_URL)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: requestURL ?? URL(string: SERVER_URL + AUTO_URL)!){
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET")
                print(error!)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                
                return
            }
            // parse the result as JSON, since that's what the API provides
            do {
                guard let json = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [AnyObject] else {
                        print("error trying to convert data to JSON")
                        
                        return
                }
                
                self.stockdata[url] = json as AnyObject
                
                
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // show top bar
        self.navigationController?.navigationBar.isHidden = false
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
