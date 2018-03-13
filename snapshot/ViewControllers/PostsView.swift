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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
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
        if let sub = redditAPI.getSubreddit(Subreddit: "aww", count: 100, id: nil, type: .normal){
            subreddit = sub
            self.navigationItem.title = subreddit.name
            return subreddit.postCount
        }
        return 0
    }


}

