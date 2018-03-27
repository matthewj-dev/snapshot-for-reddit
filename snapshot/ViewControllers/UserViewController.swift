//
//  UserViewController.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/14/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit
import SafariServices

class UserViewController: UIViewController {
    var loginWindow: SFAuthenticationSession!
    var redditAPI = RedditHandler()
    var settings = UserDefaults.standard
	
	let manager = FileManager.default

    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let api = (self.tabBarController as? TabBarControl)?.redditAPI {
			redditAPI = api
		}
		
		// Creates the Safari Authentication view with authorization view 
        loginWindow = SFAuthenticationSession(url: URL(string: "https://www.reddit.com/api/v1/authorize.compact?client_id=udgVMzpax63hJQ&response_type=code&duration=permanent&state=ThisIsATestState&redirect_uri=snapshot://response&scope=identity%20edit%20mysubreddits%20read")!, callbackURLScheme: "snapshot", completionHandler: {url, error in
            if url != nil && url!.absoluteString.contains("code=") {
                
                // pass url from Safari to auth user
                if let newAuthUser = self.redditAPI.getAuthenticatedUser(authCode: url!.absoluteString.components(separatedBy: "code=")[1]){
                    self.redditAPI.authenticatedUser = newAuthUser
                    self.navigationItem.title = self.redditAPI.authenticatedUser?.name
					
                    newAuthUser.saveUserToFile()
					guard let tabbar = self.tabBarController as? TabBarControl else {return}
					tabbar.redditUserChanged(loggedIn: true)
                }
                
            }
        })
    }
    
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		self.navigationItem.title = self.redditAPI.authenticatedUser?.name
		
		if self.redditAPI.authenticatedUser != nil {
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(logoutUser))
			return
		}
		else {
			self.navigationItem.rightBarButtonItem = nil
		}
		
		loginWindow.start()
	}
	
	@objc func logoutUser() {
		if manager.fileExists(atPath: (manager.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path) {
			do {
				try manager.removeItem(atPath: (manager.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path)
				self.redditAPI.authenticatedUser = nil
				self.viewDidAppear(true)
				
				guard let tabbar = self.tabBarController as? TabBarControl else {return}
				tabbar.redditUserChanged(loggedIn: false)
			} catch {
				let alert = UIAlertController(title: "Failed", message: "There was an error logging out", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
}
