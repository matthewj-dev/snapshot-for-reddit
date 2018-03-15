//
//  ViewController.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/12/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class PostsView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var postCollection: UICollectionView!
    
    let testNums = Array(repeating: "DOGGO", count: 200)
	
	var ncCenter = NotificationCenter.default
	let manager = FileManager.default
	
    var redditAPI = RedditHandler()
    var settings = UserDefaults.standard
	
	var saveURL: String!
    var subreddit: Subreddit!
	
	//Called when view has finished loading but not yet appeared on screen
    override func viewDidLoad() {
        super.viewDidLoad()
		saveURL = (manager.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path
        ncCenter.addObserver(self, selector: #selector(userLoggedInReload), name: Notification.Name.init("userLogin"), object: nil)
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
		if let authUser = NSKeyedUnarchiver.unarchiveObject(withFile: saveURL) as? AuthenticatedUser {
			redditAPI.authenticatedUser = authUser
			self.navigationItem.title = self.redditAPI.authenticatedUser?.name
			self.tabBarController!.tabBar.items![1].title = redditAPI.authenticatedUser?.name
		}
        
        postCollection.delegate = self
        postCollection.dataSource = self
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = postCollection.dequeueReusableCell(withReuseIdentifier: "PostsViewCell", for: indexPath)
        
        guard let postCell = cell as? PostsViewCell else {
            return cell
        }
        
//        postCell.postTitle.text = String(testNums[indexPath.row])
        
        guard let post = subreddit[indexPath.row] else {
            return postCell
        }
        
        postCell.postTitle.text = post.title!
        
        guard let thumbnail = post.thumbnail else {
            return postCell
        }
        
        DispatchQueue.global().async {
            do {
//                let imgData = try Data(contentsOf: URL(string: "https://s.abcnews.com/images/Lifestyle/puppy-ht-3-er-170907_4x3_992.jpg")!)
                let imgData = try Data(contentsOf: thumbnail)

                DispatchQueue.main.async {
                    postCell.thumbnail.image = UIImage(data: imgData)
                }
            }
            catch {
                print("Shit happens")
            }

        }
        return postCell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sub = redditAPI.getSubreddit(Subreddit: "", count: 100, id: nil, type: .normal){
            subreddit = sub
            
            if subreddit.name.isEmpty {
                self.navigationItem.title = "Home"
            }
            else {
                self.navigationItem.title = subreddit.name
            }
            
            return subreddit.postCount
        }
        return 0
    }
	
	
	//Function called by Notification Center when notification notifies that a user has logged in
    @objc func userLoggedInReload() {
        
		if let authUser = NSKeyedUnarchiver.unarchiveObject(withFile: saveURL) as? AuthenticatedUser {
			redditAPI.authenticatedUser = authUser
		}
		
     postCollection.reloadData()
    }


}

