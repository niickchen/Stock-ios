//
//  NewsViewController.swift
//  Stock
//
//  Created by Nick on 11/25/17.
//  Copyright © 2017 Xinyu Chen. All rights reserved.
//

import UIKit

class NewsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var newsjson: [String: AnyObject] = [:]
    var newsdata: [AnyObject] = []
    
    var timer = Timer()
    @IBOutlet weak var myTableView: UITableView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 238/255, green: 243/255, blue: 249/255, alpha: 255/255)
        
        myTableView.isHidden = true
        
        //delayedUpdateTable()
        let when = DispatchTime.now() + 1 // delay 1 second
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.activityIndicator.isHidden = true
            // table view setup
            self.myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
            self.myTableView.estimatedRowHeight = 65
            self.myTableView.dataSource = self
            self.myTableView.delegate = self
            let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.myTableView.bounds.size.width, height: self.myTableView.bounds.size.height))
            backgroundView.backgroundColor = UIColor(red: 238/255, green: 243/255, blue: 249/255, alpha: 255/255)
            self.myTableView.backgroundView = backgroundView
            self.myTableView.reloadData()
            self.myTableView.isHidden = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func delayedUpdateTable(){
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.myTableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let arr = newsdata[indexPath.row] as AnyObject
        let urlString = arr["link"] as! String
        guard let url = URL(string: urlString) else {
            return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // process newsjson
        newsjson = newsjson["rss"] as? [String : AnyObject] ?? newsjson
        newsjson = newsjson["channel"] as? [String : AnyObject] ?? newsjson
        newsdata = newsjson["item"] as? [AnyObject] ?? []
        newsdata = newsdata.filter {
            ($0["link"] as! String).range(of:"/symbol") == nil
            
        }
        return newsdata.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        let arr = newsdata[indexPath.row] as AnyObject
        
        // convert time to current timezone
        let dfmatter = DateFormatter()
        dfmatter.dateFormat = "E, dd MMM, yyyy HH:mm:ss Z"
        let date = dfmatter.date(from: arr["pubDate"] as! String)
        
        let dateFormatter = DateFormatter() // new date formatter
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "E, dd MMM, yyyy HH:mm:ss z" //Specify format
        let strDate = dateFormatter.string(from: date!)
        
        let formattedString = NSMutableAttributedString()
        formattedString.bold("\(arr["title"]! ?? "")").compact("\n\n").light("  Author: \(arr["sa:author_name"]! ?? "")").compact("\n\n").light("  Date: \(strDate ?? "")")
        cell.textLabel!.attributedText = formattedString
        cell.textLabel!.numberOfLines = 0
        cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        cell.backgroundColor = UIColor.clear
        return cell
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
