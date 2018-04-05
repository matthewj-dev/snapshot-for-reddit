//
//  PostsNavigationController.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/16/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class PostsNavigationController: UINavigationController, RedditView {
	
	override func loadView() {
		super.loadView()
		
		let postsView = storyboard?.instantiateViewController(withIdentifier: "PostsView") as! PostsView
		let subsView = storyboard?.instantiateViewController(withIdentifier: "SubredditView") as! SubredditsView
		
		subsView.navigationItem.title = "Subreddits"
		
		self.viewControllers = [subsView, postsView]
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	func redditUserChanged(loggedIn: Bool) {
		for view in viewControllers {
			guard let view = view as? RedditView else {continue}
			view.redditUserChanged(loggedIn: loggedIn)
		}
	}
}
