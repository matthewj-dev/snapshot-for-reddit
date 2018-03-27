//
//  RedditView.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/27/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

protocol RedditView {
	
	/**
	Informs the view that a change has been applied to the currently logged in user
	- Parameter loggedIn: Boolean of if there is currently a logged in user
	*/
	func redditUserChanged(loggedIn: Bool)
	
}

extension RedditView {
	
	func redditUserChanged(loggedIn: Bool){}
	
}
