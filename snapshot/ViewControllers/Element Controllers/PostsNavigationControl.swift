//
//  PostsNavigationController.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/16/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class PostsNavigationController: UINavigationController, DarkMode, RedditView {
	
	override func loadView() {
		super.loadView()
		
		let postsView = storyboard?.instantiateViewController(withIdentifier: "PostsView") as! PostsView
		let subsView = storyboard?.instantiateViewController(withIdentifier: "SubredditView") as! SubredditsView
		
		subsView.navigationItem.title = "Subreddits"
		
		self.viewControllers = [subsView, postsView]
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		darkMode(isOn: darkModeEnabled)
    }
	
	func redditUserChanged(loggedIn: Bool) {
		for view in viewControllers {
			guard let view = view as? RedditView else {continue}
			view.redditUserChanged(loggedIn: loggedIn)
		}
	}
	
	var darkModeEnabled = false
	func darkMode(isOn: Bool) {
		darkModeEnabled = isOn
		
		for i in viewControllers {
			if i is DarkMode {
				
				if isOn {
					(i as! DarkMode).darkMode(isOn: true)
					self.darkModeEnabled = true
					self.navigationBar.barStyle = .black
				}
				else {
					(i as! DarkMode).darkMode(isOn: false)
					self.darkModeEnabled = false
					self.navigationBar.barStyle = .default
				}
			}
		}
		
	}
	
}
