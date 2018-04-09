//
//  UserViewController.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/14/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit
import SafariServices

class UserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DarkMode, RedditView {
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(true)
	}
	
	func redditUserChanged(loggedIn: Bool) {
		if loggedIn {
			redditAPI.authenticatedUser?.asyncGetSavedPosts(api: redditAPI, completion: {
				(subreddit) in
				self.navigationItem.title = self.redditAPI.authenticatedUser?.name
				self.savedPosts = subreddit
				if self.savedPosts != nil {
					var imagePairs = [ImageCachePair]()
					for postIndex in 0 ..< self.savedPosts!.postCount {
						if let key = self.savedPosts?[postIndex]?.id, let url = self.savedPosts?[postIndex]?.thumbnail {
							imagePairs.append(ImageCachePair(key: key, url: url))
						}
					}
					self.imageCache.preload(pairs: imagePairs, IndexToAsyncAt: 5, completion: {
						self.savedPostsTable.reloadData()
					})
				}
			})
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(logoutUser))
			return
		}
		self.navigationItem.title = ""
		self.commentKarmaLabel.text = "Comment"
		self.linkKarmaLabel.text = "Link"
		self.savedPosts = nil
		self.savedPostsTable.reloadData()
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(callLoginWindow))
		
	}
	
	var imageCache = ImageCacher()
	
	var darkModeEnabled: Bool = false
	
	func darkMode(isOn: Bool) {
		darkModeEnabled = isOn
		
		if darkModeEnabled {
			self.view.backgroundColor = .black
			if savedPostsTable != nil, karmaView != nil, commentKarmaLabel != nil, linkKarmaLabel != nil  {
				self.savedPostsTable.reloadData()
				self.savedPostsTable.backgroundColor = .black
				self.commentKarmaLabel.textColor = .white
				self.linkKarmaLabel.textColor = .white
				self.karmaView.backgroundColor = .black
			}
			return
		}
		self.view.backgroundColor = .white
		if savedPostsTable != nil, karmaView != nil, commentKarmaLabel != nil, linkKarmaLabel != nil {
			self.savedPostsTable.reloadData()
			self.savedPostsTable.backgroundColor = .white
			self.commentKarmaLabel.textColor = .black
			self.linkKarmaLabel.textColor = .black
			self.karmaView.backgroundColor = .white
		}
	}
	
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		if darkModeEnabled {
			view.tintColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
			(view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor(iOSColor: .iOSBlue)
		}
		else {
			(view as! UITableViewHeaderFooterView).tintColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
			(view as! UITableViewHeaderFooterView).textLabel?.textColor = .black
		}
		
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 25
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Saved Posts"
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if savedPosts != nil {
			return savedPosts!.postCount
		}
		return 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = savedPostsTable.dequeueReusableCell(withIdentifier: "savedPost") as! SavedPost
		if let post = savedPosts?[indexPath.row] {
			cell.postTitle.text = post.title
			cell.postThumb.layer.cornerRadius = 10
			cell.postThumb.clipsToBounds = true
			cell.postThumb.layer.borderWidth = 0.25
			cell.postThumb.layer.borderColor = UIColor.black.cgColor
			
			if darkModeEnabled {
				cell.backgroundColor = .black
				cell.postTitle.textColor = .white
				cell.postThumb.layer.cornerRadius = 10
				cell.postThumb.clipsToBounds = true
				cell.postThumb.layer.borderWidth = 0.25
				cell.postThumb.layer.borderColor = UIColor.white.cgColor
			}
			
			if let key = post.id, let url = post.thumbnail {
				DispatchQueue.main.async {
					cell.postThumb.image = self.imageCache.retreive(pair: ImageCachePair(key: key, url: url))
				}
			}
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let newView = storyboard?.instantiateViewController(withIdentifier: "MaxImageController") as! MaxViewController
		newView.subreddit = savedPosts
		newView.index = indexPath.row
		newView.modalTransitionStyle = .crossDissolve
		newView.modalPresentationStyle = .overCurrentContext
		newView.settingGurl = settings
		
		present(newView, animated: true, completion: {self.savedPostsTable.deselectRow(at: indexPath, animated: true)})
	}
	
	@IBOutlet weak var karmaView: UIView!
	@IBOutlet weak var savedPostsTable: UITableView!
	@IBOutlet weak var linkKarmaLabel: UILabel!
	@IBOutlet weak var commentKarmaLabel: UILabel!
	
    var loginWindow: SFAuthenticationSession!
    var redditAPI = RedditHandler()
    var settings = SettingsHandler()
    
    var savedPosts: Subreddit? = nil
    let manager = FileManager.default
    
    override func loadView() {
        super.loadView()
        if let api = (self.tabBarController as? TabBarControl)?.redditAPI {
            redditAPI = api
			darkModeEnabled = (self.tabBarController as? TabBarControl)!.darkModeEnabled
			
			api.authenticatedUser?.asyncGetSavedPosts(api: api, completion: {
				(subreddit) in
				self.savedPosts = subreddit
				if self.savedPosts != nil {
					var imagePairs = [ImageCachePair]()
					for postIndex in 0 ..< self.savedPosts!.postCount {
						if let key = self.savedPosts?[postIndex]?.id, let url = self.savedPosts?[postIndex]?.thumbnail {
							imagePairs.append(ImageCachePair(key: key, url: url))
						}
					}
					self.imageCache.preload(pairs: imagePairs, IndexToAsyncAt: 5, completion: {
						self.savedPostsTable.reloadData()
					})
				}
			})
			
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.prefersLargeTitles = false
		
        savedPostsTable.delegate = self
        savedPostsTable.dataSource = self
		
        self.darkMode(isOn: darkModeEnabled)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if self.redditAPI.authenticatedUser != nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(logoutUser))
            self.linkKarmaLabel.text = "Post Karma\n \(redditAPI.authenticatedUser!.postKarma!)"
            self.commentKarmaLabel.text = "Comment Karma\n \(redditAPI.authenticatedUser!.commentKarma!)"
            return
        }
        else {
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(callLoginWindow))
		}
		callLoginWindow()
    }
	
	@objc func callLoginWindow() {
		// Creates the Safari Authentication view with authorization view
		loginWindow = SFAuthenticationSession(url: URL(string: "https://www.reddit.com/api/v1/authorize.compact?client_id=udgVMzpax63hJQ&response_type=code&duration=permanent&state=ThisIsATestState&redirect_uri=snapshot://response&scope=identity%20edit%20mysubreddits%20read%20history")!, callbackURLScheme: "snapshot", completionHandler: {url, error in
			if url != nil && url!.absoluteString.contains("code=") {
				
				// pass url from Safari to auth user
				if let newAuthUser = self.redditAPI.getAuthenticatedUser(authCode: url!.absoluteString.components(separatedBy: "code=")[1]){
					self.redditAPI.authenticatedUser = newAuthUser
					
					newAuthUser.saveUserToFile()
					guard let tabbar = self.tabBarController as? TabBarControl else {return}
					DispatchQueue.main.async {
						tabbar.redditUserChanged(loggedIn: true)
					}
				}
				
			}
		})
		loginWindow.start()
	}
    
    @objc func logoutUser() {
        if manager.fileExists(atPath: (manager.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path) {
            do {
                try manager.removeItem(atPath: (manager.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path)
                self.redditAPI.authenticatedUser = nil
                
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
