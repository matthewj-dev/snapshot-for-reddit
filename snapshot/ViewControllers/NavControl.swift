//
//  NavControl.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/16/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class NavControl: UINavigationController {

	override func loadView() {
		super.loadView()
		let postsView = storyboard?.instantiateViewController(withIdentifier: "PostsView")
		let subsView = storyboard?.instantiateViewController(withIdentifier: "SubredditView")
		
		subsView?.navigationItem.title = "Subreddits"
		self.viewControllers = [subsView!, postsView!]
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
