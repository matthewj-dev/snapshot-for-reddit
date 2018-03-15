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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginWindow = SFAuthenticationSession(url: URL(string: "https://www.reddit.com/api/v1/authorize.compact?client_id=udgVMzpax63hJQ&response_type=code&duration=permanent&state=ThisIsATestState&redirect_uri=snapshot://response&scope=identity%20edit%20mysubreddits%20read")!, callbackURLScheme: "snapshot", completionHandler: {url, error in
            if url != nil && url!.absoluteString.contains("code=") {
                
                // pass url from Safari to auth user
                if let newAuthUser = self.redditAPI.getAuthenticatedUser(authCode: url!.absoluteString.components(separatedBy: "code=")[1]){
                    self.redditAPI.authenticatedUser = newAuthUser
                    self.settings.set(newAuthUser.packageDataforFutureCreation(), forKey: "userData")
                    self.ncCenter.post(Notification(name: Notification.Name.init("userLogin")))
                }
                
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let package = settings.object(forKey: "userData") as? [String:Any] {
            if let authUser = redditAPI.getAuthenticatedUser(packagedData: package) {
                redditAPI.authenticatedUser = authUser
                return
            }
        }
        
        loginWindow.start()
    }
}
