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
    
    var redditAPI = RedditHandler()
    var subreddit : RedditHandler.Subreddit!
    var settings = UserDefaults.standard
    var ncCenter = NotificationCenter.default
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        ncCenter.addObserver(self, selector: #selector(userLoggedInReload), name: Notification.Name.init("userLogin"), object: nil)
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        if let package = settings.object(forKey: "userData") as? [String:Any] {
            if let authUser = redditAPI.getAuthenticatedUser(packagedData: package) {
                redditAPI.authenticatedUser = authUser
                self.tabBarController!.tabBar.items![1].title = redditAPI.authenticatedUser?.name
            }
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
    
    @objc func userLoggedInReload() {
        
        if let package = settings.object(forKey: "userData") as? [String:Any] {
            if let authUser = redditAPI.getAuthenticatedUser(packagedData: package) {
                redditAPI.authenticatedUser = authUser
            }
        }
     postCollection.reloadData()
    }


}

