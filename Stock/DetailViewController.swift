//
//  DetailViewController.swift
//  Stock
//
//  Created by Nick on 11/24/17.
//  Copyright © 2017 Xinyu Chen. All rights reserved.
//

import UIKit
import SwiftSpinner
import Toaster
import Foundation

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
    var containerIndex: Int = 0
    var stockdata: [String: [String: AnyObject]] = [:]
    var error: [String: Bool] = [:]
    var loaded = false
    var timer: Timer = Timer.init()
    
    @IBOutlet weak var containerView: UIView!
    
    private lazy var currentViewController: CurrentViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "CurrentViewController") as! CurrentViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        // Pass data
        viewController.input = self.input ?? ""
        viewController.tsdData = stockdata[TIME_SERIES_DAILY_URL] ?? [:]
        viewController.tsdError = self.error[TIME_SERIES_DAILY_URL] ?? false
        return viewController
    }()
    
    private lazy var historicalViewController: HistoricalViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "HistoricalViewController") as! HistoricalViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        // Pass data
        viewController.historicalData = stockdata[TIME_SERIES_DAILY_URL] ?? [:]
        
        return viewController
    }()
    
    private lazy var newsViewController: NewsViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "NewsViewController") as! NewsViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        // Pass data
        viewController.newsjson = stockdata[NEWS_URL] ?? [:]
        return viewController
    }()
    
    private lazy var loadingViewController: LoadingViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        return viewController
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 238/255, green: 243/255, blue: 249/255, alpha: 255/255)
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 87/255, green: 175/255, blue: 244/255, alpha: 255/255)
        
        // Do any additional setup after loading the view.
        containerIndex = 0
        stockdata = [:]
        error = [:]
        loaded = false
        
        // loading spinner
        SwiftSpinner.show("Loading data").addTapHandler({
            SwiftSpinner.hide()
            _ = self.navigationController?.popViewController(animated: true)
        }, subtitle: "Tap to cancel")
        
        
        
        
        // set title of top bar
        self.title = input
        
        // async fetch data
        self.fetchData(TIME_SERIES_DAILY_URL)
        self.fetchData(NEWS_URL)
        
        // hide error label
        errorLabel.isHidden = true
        
        // timer to check if received data
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.loadCurrentViewAndDismissSpinner), userInfo: nil, repeats: true)
    }
    
    func displayToastMessage(_ userMessage: String) {
        let toast = Toast(text: userMessage)
        ToastView.appearance().bottomOffsetPortrait = CGFloat(160)
        ToastView.appearance().font = UIFont(name: "AvenirNext-Medium", size: 17)
        toast.show()
    }
    
    
    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChildViewController(viewController)
        
        // Add Child View as Subview
        containerView.addSubview(viewController.view)
        
        // Configure Child View
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Notify Child View Controller
        viewController.didMove(toParentViewController: self)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParentViewController: nil)
        
        // Remove Child View From Superview
        viewController.view.removeFromSuperview()
        
        // Notify Child View Controller
        viewController.removeFromParentViewController()
    }
    

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex
        { // update container view
            case 0:
                while stockdata[TIME_SERIES_DAILY_URL] == nil {
                    remove(asChildViewController: currentViewController)
                    remove(asChildViewController: newsViewController)
                    remove(asChildViewController: historicalViewController)
                    add(asChildViewController: loadingViewController)
                    errorLabel.isHidden = true
                    if self.error[TIME_SERIES_DAILY_URL] != nil && self.error[TIME_SERIES_DAILY_URL]! {
                        remove(asChildViewController: loadingViewController)
                        add(asChildViewController: currentViewController)
                        errorLabel.isHidden = true
                        displayToastMessage("Failed to load data. Please try again later.")
                        break
                    }
                }
                // if received data correctly, show historical view
                if self.error[TIME_SERIES_DAILY_URL] != nil && !self.error[TIME_SERIES_DAILY_URL]! {
                    // TODO: Prompt error message after 10 seconds if not out of while loop
                    
                    remove(asChildViewController: historicalViewController)
                    remove(asChildViewController: loadingViewController)
                    remove(asChildViewController: newsViewController)
                    add(asChildViewController: currentViewController)
                    errorLabel.isHidden = true
            }
            case 1:
                while stockdata[TIME_SERIES_DAILY_URL] == nil {
                    remove(asChildViewController: currentViewController)
                    remove(asChildViewController: newsViewController)
                    remove(asChildViewController: historicalViewController)
                    add(asChildViewController: loadingViewController)
                    errorLabel.isHidden = true
                    if self.error[TIME_SERIES_DAILY_URL] != nil && self.error[TIME_SERIES_DAILY_URL]! {
                        remove(asChildViewController: loadingViewController)
                        errorLabel.isHidden = false
                        errorLabel.text = "Failed to load historical data"
                        break
                    }
                }
                // if received data correctly, show historical view
                if self.error[TIME_SERIES_DAILY_URL] != nil && !self.error[TIME_SERIES_DAILY_URL]! {
                    // TODO: Prompt error message after 10 seconds if not out of while loop
                    
                    remove(asChildViewController: currentViewController)
                    remove(asChildViewController: loadingViewController)
                    remove(asChildViewController: newsViewController)
                    add(asChildViewController: historicalViewController)
                    errorLabel.isHidden = true
            }
            case 2:
                while stockdata[NEWS_URL] == nil {
                    remove(asChildViewController: currentViewController)
                    remove(asChildViewController: newsViewController)
                    remove(asChildViewController: historicalViewController)
                    add(asChildViewController: loadingViewController)
                    errorLabel.isHidden = true
                    if self.error[NEWS_URL] != nil && self.error[NEWS_URL]! {
                        remove(asChildViewController: loadingViewController)
                        errorLabel.isHidden = false
                        errorLabel.text = "Failed to load news data"
                        break
                    }
                }
                
                // if received news correctly, show news view
                if self.error[NEWS_URL] != nil && !self.error[NEWS_URL]! {
                    // TODO: Prompt error message after 10 seconds if not out of while loop
                    remove(asChildViewController: currentViewController)
                    remove(asChildViewController: loadingViewController)
                    remove(asChildViewController: historicalViewController)
                    add(asChildViewController: newsViewController)
                    errorLabel.isHidden = true
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
    
    override func viewWillDisappear(_ animated: Bool) {
        //input = ""
        //containerIndex = 0
        //stockdata = [:]
        //error = [:]
        //loaded = false
        
//        URLSession.shared.getAllTasks{ (openTasks: [URLSessionTask]) in
//            print("Number of open tasks: \(openTasks.count)")
//            //openTasks.removeAll()
//            for task in openTasks {
//                task.cancel()
//            }
//        }
        
        super.viewWillDisappear(animated)
    }
    
    @objc func loadCurrentViewAndDismissSpinner()
    {
        print(self.error[TIME_SERIES_DAILY_URL])
        if loaded {
            timer.invalidate()
            return
        }
        // dismiss the loading scene after 1 second in order to load webView first if received time_series_daily data and add current view
        if  self.error[TIME_SERIES_DAILY_URL] != nil && !self.error[TIME_SERIES_DAILY_URL]! {
            DispatchQueue.main.async {
                self.add(asChildViewController: self.currentViewController)
            }
            let when = DispatchTime.now() + 2.5 // delay 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: when) {
                SwiftSpinner.hide()
            }
            loaded = true
        } else if self.error[TIME_SERIES_DAILY_URL] != nil && self.error[TIME_SERIES_DAILY_URL]! {
            SwiftSpinner.hide()
            self.displayToastMessage("Failed to load data and display the chart. Please try again later.")
            DispatchQueue.main.async {
                self.add(asChildViewController: self.currentViewController)
            }
            loaded = true
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // show top bar
        self.navigationController?.navigationBar.isHidden = false
        
        // setup
        containerIndex = 0
        stockdata = [:]
        error = [:]
        loaded = false
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
