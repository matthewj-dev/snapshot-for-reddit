//
//  NavControl.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/16/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class NavControl: UINavigationController {

	let center = NotificationCenter.default
	
	override func loadView() {
		super.loadView()
		
		center.addObserver(self, selector: #selector(toggleDarkMode), name: Notification.Name.UIScreenBrightnessDidChange, object: nil)
		
		let postsView = storyboard?.instantiateViewController(withIdentifier: "PostsView") as! PostsView
		let subsView = storyboard?.instantiateViewController(withIdentifier: "SubredditView") as! SubredditsView
		
		subsView.navigationItem.title = "Subreddits"
		
		self.viewControllers = [subsView, postsView]
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		toggleDarkMode()
    }
	
	var darkModeEnabled = false
	@objc func toggleDarkMode() {
		
		if UIScreen.main.brightness < 0.20 && !darkModeEnabled {
			darkModeEnabled = true
			self.navigationBar.barStyle = .black
			self.tabBarController?.tabBar.barStyle = .black
			for i in self.viewControllers {
				if i is DarkMode {
					print("Toggled Dark Mode On")
					(i as! DarkMode).darkMode(isOn: true)
				}
			}
		}
		else if darkModeEnabled && UIScreen.main.brightness >= 0.20 {
			darkModeEnabled = false
			self.navigationBar.barStyle = .default
			self.tabBarController?.tabBar.barStyle = .default
			for i in self.viewControllers {
				if i is DarkMode {
					print("Toggled Dark Mode off")
					(i as! DarkMode).darkMode(isOn: false)
				}
			}
		}
	}
	
}
