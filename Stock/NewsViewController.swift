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
    var timer = Timer()
    @IBOutlet weak var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // table view setup
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        myTableView.dataSource = self
        myTableView.delegate = self
        myTableView.reloadData()
        
        //delayedUpdateTable()
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        newsjson = newsjson["rss"] as? [String : AnyObject] ?? newsjson
        newsjson = newsjson["channel"] as? [String : AnyObject] ?? newsjson
        return newsjson["item"]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        let arr = newsjson["item"]![indexPath.row] as AnyObject
        cell.textLabel?.text = arr["title"] as? String ?? ""
        cell.textLabel!.numberOfLines = 0
        cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
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
