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
    var ncCenter = NotificationCenter.default
	
	let manager = FileManager.default
	var saveURL: String!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		saveURL = (manager.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path
		print(saveURL)
		
		// Creates the Safari Authentication view with authorization view 
        loginWindow = SFAuthenticationSession(url: URL(string: "https://www.reddit.com/api/v1/authorize.compact?client_id=udgVMzpax63hJQ&response_type=code&duration=permanent&state=ThisIsATestState&redirect_uri=snapshot://response&scope=identity%20edit%20mysubreddits%20read")!, callbackURLScheme: "snapshot", completionHandler: {url, error in
            if url != nil && url!.absoluteString.contains("code=") {
                
                // pass url from Safari to auth user
                if let newAuthUser = self.redditAPI.getAuthenticatedUser(authCode: url!.absoluteString.components(separatedBy: "code=")[1]){
                    self.redditAPI.authenticatedUser = newAuthUser
                    self.navigationItem.title = self.redditAPI.authenticatedUser?.name
                    self.tabBarController!.tabBar.items![1].title = self.redditAPI.authenticatedUser?.name
					
                    newAuthUser.saveUserToFile()
					self.ncCenter.post(Notification(name: Notification.Name.init(rawValue: "userLogin")))
                }
                
            }
        })
    }
    
	override func viewDidAppear(_ animated: Bool) {
		if let authUser = NSKeyedUnarchiver.unarchiveObject(withFile: saveURL) as? AuthenticatedUser {
			redditAPI.authenticatedUser = authUser
			self.navigationItem.title = self.redditAPI.authenticatedUser?.name
			self.tabBarController!.tabBar.items![1].title = redditAPI.authenticatedUser?.name
			
			authUser.saveUserToFile()
			return
		}
		
		loginWindow.start()
	}
}
