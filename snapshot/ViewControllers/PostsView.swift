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
    var itemCount = 0
    
    override func loadView() {
        super.loadView()
        
        if let sub = redditAPI.getSubreddit(Subreddit: "", count: 100, id: nil, type: .normal){
            subreddit = sub
            
            if subreddit.name.isEmpty {
                self.navigationItem.title = "Home"
            }
            else {
                self.navigationItem.title = subreddit.name
            }
            
            itemCount = subreddit.postCount
        }
        
    }
	
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
        
        ncCenter.addObserver(self, selector: #selector(bringBackTab), name: Notification.Name.init(rawValue: "isDismissed"), object: nil)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = postCollection.dequeueReusableCell(withReuseIdentifier: "PostsViewCell", for: indexPath)
        
        guard let postCell = cell as? PostsViewCell else {
            return cell
        }
        
        guard let post = subreddit[indexPath.row] else {
            return postCell
        }
        
        postCell.postTitle.text = post.title!
        
        guard var thumbnail = post.thumbnail else {
            return postCell
        }
        
        if let preview = post.preview {
            thumbnail = preview
        }
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap))
        
        
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
        
        return itemCount
    }
    
    /**
     called when an image is tapped
    */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var newView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MaxImageController") as! MaxViewController
        
        newView.subreddit = subreddit
        
        newView.index = indexPath.row
        
        newView.modalTransitionStyle = .crossDissolve
        
        newView.modalPresentationStyle = .overCurrentContext
        
        self.tabBarController?.tabBar.isHidden = true
        
        present(newView, animated: true, completion: nil)
        
    }
	
    var isUpdating = false
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !isUpdating && indexPath.row > postCollection.numberOfItems(inSection: 0) - 20 {
            isUpdating = true
            subreddit.asyncLoadAdditionalPosts(count: 100, completion: {(didload) in
                if didload {
                    var newIndexes = [IndexPath]()
                    print(self.subreddit.postCount)
                    for i in self.postCollection.numberOfItems(inSection: 0)..<self.subreddit.postCount {
                        newIndexes.append(IndexPath(item: i, section: 0))
                    }
                    self.postCollection.performBatchUpdates({
                        for update in newIndexes {
                            self.postCollection.insertItems(at:[update])
                            self.itemCount += 1
                        }
                    }, completion: nil)
                    self.isUpdating = false
                }
            })
        }
    }
    
	
	//Function called by Notification Center when notification notifies that a user has logged in
    @objc func userLoggedInReload() {
        
		if let authUser = NSKeyedUnarchiver.unarchiveObject(withFile: saveURL) as? AuthenticatedUser {
			redditAPI.authenticatedUser = authUser
		}
		
     postCollection.reloadData()
    }
    
    @objc func bringBackTab() {
        self.tabBarController?.tabBar.isHidden = false

    }
}

