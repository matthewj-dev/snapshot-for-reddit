//
//  Subreddit.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/15/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import Foundation


/**
Subreddit object that contains subreddit post data
*/
public class Subreddit {
	internal var posts = [RedditPost]()
	/**
	Name of Subreddit
	*/
	var name: String
	let type: SubredditType
	let bannerURL: URL?
	
	/**
	- Parameter response: Response from Reddit API
	- Parameter type: Type of subreddit to create
	
	- throws: If the subreddit is invalid or there is an issue parsing
	*/
	init(response: RedditResponse, name: String = "", type: SubredditType = .normal) throws {
		self.type = type
		self.name = name
		
		for i in 0..<response.childrenDataCount {
			if let postData = response.parsedChildData(index: i) {
				let post = RedditPost(postData: postData)
				
				if (type == .image && post.thumbnail != nil && !post.isSelfPost) || type == .normal {
					posts.append(post)
				}
				
			}
		}
		
		// Gets banner URL if subreddit name is not nil
		if !name.isEmpty {
			
			if let tempResponse = RedditHandler().getRedditResponse(urlSuffix: "/r/\(name)/about.json"){
				
				if let banner = tempResponse.jsonReturnedData["banner_img"] as? String {
					bannerURL = URL(string: banner)!
				}
				else {
					bannerURL = nil
				}
			}
			else {
				bannerURL = nil
			}
		}
		else {
			print("No name")
			bannerURL = nil
		}
	}
	
	/**
	Current number of posts stored within Subreddit Object
	
	- Returns: Int of
	*/
	var postCount: Int {
		return posts.count
	}
	
	/**
	- Returns: Post at index value of posts
	*/
	subscript(index:Int) -> RedditPost? {
		if index < posts.count {
			return getRedditPost(index: index)
		}
		else {
			return nil
		}
	}
	
	/**
	Loads additional posts into the subreddits array of posts
	- Parameter count: (Optional) Number of new posts to append with
	- Returns: Bool of whether the process was successful
	*/
	func loadAdditionalPosts(count:Int? = nil) -> Bool {
		
		if let id = self[postCount - 1]?.id {
			if count == nil {
				if let tempSub = RedditHandler().getSubreddit(Subreddit: name, id: id, type: type) {
					self.posts.append(contentsOf: tempSub.posts)
				}
				
			}
			else {
				if let tempSub = RedditHandler().getSubreddit(Subreddit: name, count: count!, id: id, type: type) {
					self.posts.append(contentsOf: tempSub.posts)
				}
			}
			
			return true
		}
		return false
	}
	
	/**
	Loads additional posts asyncriously into the subreddits array of posts
	- Parameter count: (Optional) Number of new posts to append with
	- Parameter completion: Block with boolean of success status of loading additional posts
	*/
	func asyncLoadAdditionalPosts(count:Int? = nil, completion: @escaping (Bool)->Void){
		DispatchQueue.global().async {
			let result = self.loadAdditionalPosts(count: count)
			DispatchQueue.main.async {
				completion(result)
			}
		}
	}
	
	/**
	Gets a reddit post from the available stored posts
	- Parameter index: Index of post to return
	
	- Returns: RedditPost from Index
	*/
	func getRedditPost(index:Int) -> RedditPost? {
		if index < posts.count {
			return posts[index]
		}
		else {
			return nil
		}
	}
	/**
	Subreddit custom types
	*/
	enum SubredditType {
		/**
		Default subreddit type, no changes
		*/
		case normal
		/**
		Creates a subreddit where only links with thumbnails are added. Can create empty subreddit objects.
		*/
		case image
	}
	
	enum RedditError: Error {
		case invalidSubreddit(String)
		case invalidParse(String)
	}
}
