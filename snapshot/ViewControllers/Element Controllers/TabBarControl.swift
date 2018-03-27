//
//  TabBarControl.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/26/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class TabBarControl: UITabBarController, RedditView {

	var redditAPI = RedditHandler()
	let center = NotificationCenter.default
	
	override func loadView() {
		super.loadView()
		center.addObserver(self, selector: #selector(brightnessChanged), name: .UIScreenBrightnessDidChange, object: nil)
		
		if let authUser = NSKeyedUnarchiver.unarchiveObject(withFile: (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path) as? AuthenticatedUser {
			redditAPI.authenticatedUser = authUser
			self.tabBar.items![1].title = redditAPI.authenticatedUser?.name
			
			authUser.saveUserToFile()
		}
		
		self.viewControllers![0] = self.viewControllers![0] as! PostsNavigationController
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		brightnessChanged()
	}
	
	func redditUserChanged(loggedIn: Bool) {
		if loggedIn {
			self.tabBar.items![1].title = self.redditAPI.authenticatedUser?.name
		}
		else {
			self.tabBar.items![1].title = "User"
		}
		
		for view in viewControllers! {
			guard let view = view as? RedditView else {continue}
			view.redditUserChanged(loggedIn: loggedIn)
		}
	}
	
	var darkModeEnabled = false
	@objc func brightnessChanged() {
		for i in viewControllers! {
			if i is DarkMode {
				
				if UIScreen.main.brightness <= 0.20 && !darkModeEnabled {
					(i as! DarkMode).darkMode(isOn: true)
					self.darkModeEnabled = true
					self.tabBar.barStyle = .black
				}
				else if UIScreen.main.brightness > 0.20 && darkModeEnabled {
					(i as! DarkMode).darkMode(isOn: false)
					self.darkModeEnabled = false
					self.tabBar.barStyle = .default
				}
			}
		}
	}
	
}
