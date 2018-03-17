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
		
		let saveURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path
		
		if let authUser = NSKeyedUnarchiver.unarchiveObject(withFile: saveURL) as? AuthenticatedUser {
			redditAPI.authenticatedUser = authUser
			self.tabBarController!.tabBar.items![1].title = redditAPI.authenticatedUser?.name
			authUser.saveUserToFile()
			
			authUser.asyncGetSubscribedSubreddits(api: redditAPI, completition: {(subs) in
				self.subreddits = subs
				self.redditTable.reloadData()
			})
			
		}
		//Notification for when the user has logged in
		ncCenter.addObserver(self, selector: #selector(userLoggedInReload), name: Notification.Name.init(rawValue: "userLogin"), object: nil)
		
		redditTable.delegate = self
		redditTable.dataSource = self
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
	}
	
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
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = redditTable.dequeueReusableCell(withIdentifier: "subredditListCell") as! RedditListCell
		
		if indexPath.section == 1 {
			cell.subredditName.text = subreddits[indexPath.row]
			return cell
		}
		
		cell.subredditName.text = "Home"
		return cell
		
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Reddit"
		}
		if section == 1 {
			return "Subscribed"
		}
		return ""
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 25
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return 1
		}
		if section == 1 {
			return subreddits.count
		}
		return 0
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	//Function called by Notification Center when notification notifies that a user has logged in
	@objc func userLoggedInReload() {
		let saveURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path
		if let authUser = NSKeyedUnarchiver.unarchiveObject(withFile: saveURL) as? AuthenticatedUser {
			redditAPI.authenticatedUser = authUser
		}
	}
	
}
