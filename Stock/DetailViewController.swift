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
    
    @IBOutlet weak var containerView: UIView!
    
    private lazy var currentViewController: CurrentViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "CurrentViewController") as! CurrentViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        return viewController
    }()
    
    private lazy var historicalViewController: HistoricalViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "HistoricalViewController") as! HistoricalViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        return viewController
    }()
    
    private lazy var newsViewController: NewsViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "NewsViewController") as! NewsViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
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
        // Do any additional setup after loading the view.
        
        // loading spinner
        SwiftSpinner.show(duration: 12, title: "Loading data")
        
        // async fetch data
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
        
        // show current view
        add(asChildViewController: currentViewController)
        // hide error label
        errorLabel.isHidden = true
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // pass data to current view controller
        if segue.identifier == "current" {
            if let toViewController = segue.destination as? CurrentViewController {
                
            }
        }
        
        // pass data to historical view controller
        if segue.identifier == "historical" {
            if let toViewController = segue.destination as? HistoricalViewController {
                
            }
        }
        
        // pass data to news view controller
        if segue.identifier == "news" {
            if let toViewController = segue.destination as? NewsViewController {
                toViewController.newsjson = stockdata[NEWS_URL]!
            }
        }
    }
    

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex
        { // update container view
            case 0:
                
                remove(asChildViewController: historicalViewController)
                remove(asChildViewController: newsViewController)
                remove(asChildViewController: loadingViewController)
                add(asChildViewController: currentViewController)
                errorLabel.isHidden = true
            case 1:
                remove(asChildViewController: currentViewController)
                remove(asChildViewController: newsViewController)
                remove(asChildViewController: loadingViewController)
                add(asChildViewController: historicalViewController)
                errorLabel.isHidden = true
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
                        errorLabel.text = "Error loading news"
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
                print(error!)
                self.error[url] = true
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                self.error[url] = true
                return
            }
            // parse the result as JSON, since that's what the API provides
            do {
                guard let json = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: AnyObject] else {
                        print("error trying to convert data to JSON")
                        self.error[url] = true
                        return
                }
                // dismiss the loading scene if received time_series_daily data
                if url == TIME_SERIES_DAILY_URL {
                    SwiftSpinner.hide()
                }
                self.stockdata[url] = json
                self.error[url] = false
            } catch  {
                print("error trying to convert data to JSON")
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
