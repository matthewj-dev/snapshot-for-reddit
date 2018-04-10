//
//  ViewController.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/12/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit
import SafariServices

class PostsView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIViewControllerPreviewingDelegate, DarkMode, RedditView {
	
    func redditUserChanged(loggedIn: Bool) {
        loadSubredditIntoCollectionView()
	}
    
    func darkMode(isOn: Bool) {
        darkModeEnabled = isOn
        
        if isOn {
            if postCollection != nil {
                self.postCollection.reloadData()
            }
            self.view.backgroundColor = .black
            self.postCollection.backgroundColor = .black
            self.loadingWheel.activityIndicatorViewStyle = .white
        }
        else {
            if postCollection != nil {
                self.postCollection.reloadData()
            }
            self.view.backgroundColor = .white
            self.postCollection.backgroundColor = .white
            self.loadingWheel.activityIndicatorViewStyle = .gray
        }
    }
    

    @IBOutlet weak var postCollection: UICollectionView!
	
    var subredditToLoad = ""
    
    var ncCenter = NotificationCenter.default
	var settingsBoi: SettingsHandler!
	var darkModeEnabled: Bool = false
    
    var redditAPI = RedditHandler()
    var imageCache = ImageCacher()
    
    var subreddit: Subreddit!
    var itemCount = 0
    
    let loadingWheel = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    override func loadView() {
        super.loadView()
        
        if let tabBar = self.tabBarController as? TabBarControl {
            settingsBoi = tabBar.settings
        }
        else {
            settingsBoi = SettingsHandler()
        }
        
        // Gets the global API from the TabBar Controller
        if let api = (self.tabBarController as? TabBarControl)?.redditAPI {
            redditAPI = api
        }
        
        registerForPreviewing(with: self, sourceView: self.postCollection)
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        loadingWheel.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingWheel)
    }
    
    //Called when view has finished loading but not yet appeared on screen
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubredditIntoCollectionView()
        
        darkMode(isOn: darkModeEnabled)
        
        //Notification for when the user dismisses the full screen image viewer
        ncCenter.addObserver(self, selector: #selector(bringBackTab), name: Notification.Name.init(rawValue: "isDismissed"), object: nil)
        
        postCollection.delegate = self
        postCollection.dataSource = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = postCollection.dequeueReusableCell(withReuseIdentifier: "PostsViewCell", for: indexPath)
        
        guard let postCell = cell as? PostsViewCell else {
            return cell
        }
        
        if darkModeEnabled {
            postCell.backgroundColor = .black
            postCell.postTitle.textColor = .white
            postCell.postTitle.backgroundColor = (UIColor.black).withAlphaComponent(0.75)
			postCell.layer.cornerRadius = 10
			postCell.clipsToBounds = true
			postCell.layer.borderWidth = 0.25
			postCell.layer.borderColor = UIColor.white.cgColor
        }
        else {
            postCell.backgroundColor = .white
            postCell.postTitle.textColor = .black
            postCell.postTitle.backgroundColor = (UIColor.white).withAlphaComponent(0.75)
			postCell.layer.cornerRadius = 10
			postCell.clipsToBounds = true
			postCell.layer.borderWidth = 0.25
			postCell.layer.borderColor = (UIColor.black).withAlphaComponent(0.75).cgColor
        }
        
        guard let post = subreddit[indexPath.row] else {
            return postCell
        }
        
        postCell.postTitle.text = post.title!
        
		if let key = post.id, let url = post.thumbnail {
			DispatchQueue.global().async {
				let image = self.imageCache.retreive(pair: ImageCachePair(key: key, url: url))
				DispatchQueue.main.async {
					postCell.thumbnail.image = image
				}
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
        let newView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MaxImageController") as! MaxViewController
        
        newView.subreddit = subreddit
        newView.index = indexPath.row
        newView.modalTransitionStyle = .crossDissolve
        newView.modalPresentationStyle = .overCurrentContext
        newView.settingGurl = settingsBoi
        
        self.tabBarController?.tabBar.isHidden = true
        
        present(newView, animated: true, completion: nil)
        
    }
    
    //Variable used for detecting whether an update is already taking place
    private var isUpdating = false
    
    //Informs the subreddit object to load additional posts with async
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !isUpdating && indexPath.row > postCollection.numberOfItems(inSection: 0) - 20 {
            isUpdating = true
            subreddit.asyncLoadAdditionalPosts(count: 100, completion: {(didload) in
                if didload {
                    let oldItemCount = self.postCollection.numberOfItems(inSection: 0)
                    self.postCollection.performBatchUpdates({
                        for i in oldItemCount..<self.subreddit.postCount {
                            self.postCollection.insertItems(at: [IndexPath(item: i, section: 0)])
                            self.itemCount += 1
                        }
                    }, completion: nil)
                    
                    DispatchQueue.global().async {
                        var imagePairs = [ImageCachePair]()
                        for i in oldItemCount..<self.subreddit.postCount {
                            if let key = self.subreddit[i]?.id, let url = self.subreddit[i]?.thumbnail {
                                imagePairs.append(ImageCachePair(key: key, url: url))
                            }
                        }
                        self.imageCache.preload(pairs: imagePairs, IndexToAsyncAt: 0, completion: {() in })

                    }
                    self.isUpdating = false
                }
            })
        }
    }
    
    /**
    Loads the subreddit through async and then loads the UICollectionView with the posts of that subreddit
    */
    func loadSubredditIntoCollectionView() {
        redditAPI.asyncGetSubreddit(Subreddit: subredditToLoad, count: 100, id: nil, type: .image, completion: {(newSubreddit) in
            if newSubreddit != nil {
                
                self.subreddit = newSubreddit!
                self.itemCount = self.subreddit.postCount
                
                if self.subreddit.name.isEmpty {
                    self.navigationItem.title = "Home"
                }
                else {
                    self.navigationItem.title = self.subreddit.name
                }
                
                
                var imagePairs = [ImageCachePair]()
                for i in 0..<self.subreddit.postCount {
                    if let key = self.subreddit[i]?.id, let url = self.subreddit[i]?.thumbnail {
                        imagePairs.append(ImageCachePair(key: key, url: url))
                    }
                }
                
                self.imageCache.preload(pairs: imagePairs, IndexToAsyncAt: 0, completion: {
                    self.postCollection.reloadData()
                    self.loadingWheel.stopAnimating()
                })
                
            }
            else {
                let alert = UIAlertController(title: "Subreddit not found", message: "The specified subreddit was not found", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Understood", style: .cancel, handler: {Void in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = postCollection.indexPathForItem(at: location) else { return nil }
        guard let cell = postCollection.cellForItem(at: indexPath) else { return  nil }
        
        let newView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MaxImageController") as! MaxViewController
        
        newView.subreddit = subreddit
        newView.index = indexPath.row
        newView.settingGurl = settingsBoi
        previewingContext.sourceRect = cell.frame
        
        
        return newView
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.modalTransitionStyle = .crossDissolve
        viewControllerToCommit.modalPresentationStyle = .overCurrentContext
        
        self.tabBarController?.tabBar.isHidden = true
        
        present(viewControllerToCommit, animated: true, completion: nil)
    }
    
    @objc func bringBackTab() {
        self.tabBarController?.tabBar.isHidden = false
        
    }
}

