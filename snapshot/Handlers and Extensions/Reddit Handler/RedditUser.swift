//
//  RedditUser.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/15/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import Foundation


/**
Reddit user. Has access to posts and details of user
*/
class RedditUser: NSObject {
	let data: [String:Any?]
	let posts: [RedditPost]
	
	/**
	- Parameters:
	- aboutResponse: RedditResponse of users about page
	- postsResponse: RedditResponse of users main page
	*/
	init(api: RedditHandler, aboutResponse: RedditResponse, postsResponse: RedditResponse) throws {
		guard let userData = aboutResponse.parsedData else {
			throw UserError.invalidParse("Unable to parse some user data")
		}
		data = userData
		
		do {
			let tempSub = try Subreddit(api: api, response: postsResponse)
			posts = tempSub.posts
		}
		catch {
			print("User posts not found")
			print(error)
			throw error
		}
	}
	
	/**
	- Parameter userData: Dictionary of user data from previous load
	- Parameter postsData: Array of RedditPosts from previous load, can be nil
	*/
	init (userData: [String:Any?], postsData: [RedditPost]?){
		if postsData == nil {
			posts = [RedditPost]()
		}
		else {
			posts = postsData!
		}
		data = userData
	}
	
	/**
	Name of user
	*/
	var name: String? {
		return data["name"] as? String
	}
	
	/**
	Post Karma of user
	*/
	var postKarma: String? {
		guard let importantKarma = data["link_karma"] as? Int else {
			return nil
		}
		return String(importantKarma)
	}
	
	/**
	Comment Karma of user
	*/
	var commentKarma: String? {
		guard let plebKarma = data["comment_karma"] as? Int else {
			return nil
		}
		return String(plebKarma)
	}
	
	enum UserError: Error {
		case invalidParse(String)
		case invalidURLs()
		case invalidResponse()
	}
	
}
