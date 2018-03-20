//
//  SubredditsView.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/16/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class SubredditsView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var redditTable: UITableView!
    
    var redditAPI = RedditHandler()
    var subreddits = [String]()
    let ncCenter = NotificationCenter.default

    override func loadView() {
        super.loadView()
        
        redditTable.delegate = self
        redditTable.dataSource = self
        
        //Notification for when the user has logged in
        ncCenter.addObserver(self, selector: #selector(repopulateSubTable), name: Notification.Name.init(rawValue: "userLogin"), object: nil)
        
        repopulateSubTable()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    //Creates a new view based on the cell selected and then pushed onto the navigation controller
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newView = storyboard?.instantiateViewController(withIdentifier: "PostsView") as! PostsView
        if indexPath.section == 1 {
            newView.subredditToLoad = subreddits[indexPath.row]
        } else {
            newView.subredditToLoad = ""
        }
        self.navigationController?.pushViewController(newView, animated: true)
        self.redditTable.deselectRow(at: indexPath, animated: true)
    }
    
    //Creates and returns each cell of the table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = redditTable.dequeueReusableCell(withIdentifier: "subredditListCell") as! RedditListCell
        
        if indexPath.section == 1 {
            cell.subredditName.text = subreddits[indexPath.row]
            return cell
        }
        
        cell.subredditName.text = "Home"
        return cell
        
    }
    
    //Sets the title per header in table
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Reddit"
        }
        if section == 1 {
            return "Subscribed"
        }
        return ""
    }
    
    //Tells the table the height of the row
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    //Tells the tableview how many rows are in a section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if section == 1 {
            return subreddits.count
        }
        return 0
    }
    
    //Tells the tableview how many sections the tableview will contain
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    //repopulates the subreddit table
    @objc func repopulateSubTable(){
        
        //Path to check for userData file
        let saveURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path
        
        if let authUser = NSKeyedUnarchiver.unarchiveObject(withFile: saveURL) as? AuthenticatedUser {
            redditAPI.authenticatedUser = authUser
            self.tabBarController!.tabBar.items![1].title = redditAPI.authenticatedUser?.name
            authUser.saveUserToFile()
            
            authUser.asyncGetSubscribedSubreddits(api: redditAPI, completition: {(subs) in
                self.subreddits = subs
                
                // Starts updates onto the TableView
                self.redditTable.beginUpdates()
                
                for i in 0..<self.subreddits.count {
                    // Inserts a row for each Subreddit in list
                    self.redditTable.insertRows(at: [IndexPath(row: i, section: 1)], with: .top)
                }
                // Informs the tableview that the updates have concluded
                self.redditTable.endUpdates()
                
            })
        }
    }
    
}
