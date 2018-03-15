//
//  RedditPost.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/15/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import Foundation

/**
Object of a single Reddit Post's data
*/
class RedditPost {
	let data: [String:Any?]
	
	/**
	- Parameter postData: Dictionary of Reddit Post Data
	*/
	init(postData:[String:Any?]) {
		data = postData
	}
	
	/**
	Title of Post
	*/
	var title: String? {
		if let title = data["title"] as? String {
			return title.replacingOccurrences(of: "&amp;", with: "&", options: .literal, range: nil)
		}
		return nil
	}
	
	/**
	URL of Post contents
	*/
	var content: URL? {
		if let tempString = data["url"] as? String {
			if let url = URL(string: tempString.replacingOccurrences(of: "&amp;", with: "&", options: .literal, range: nil)) {
				return url
			}
		}
		return nil
	}
	
	/**
	Thumbnail URL for picture used on Subreddit for post
	*/
	var thumbnail: URL? {
		if let tempString = data["thumbnail"] as? String {
			if tempString == "self" || tempString == "nsfw" || tempString == "default" {
				return nil
			}
			if let url = URL(string: tempString.replacingOccurrences(of: "&amp;", with: "&", options: .literal, range: nil)) {
				return url
			}
		}
		return nil
	}
	
	/**
	Higher Resolution thumbnail URL icon
	*/
	var preview: URL? {
		guard let preview = data["preview"] as? [String:Any?] else {
			print("No Preview")
			return nil
		}
		guard let images = preview["images"] as? NSArray else {
			print("No source Image")
			return nil
		}
		
		if images.count < 1 {
			return nil
		}
		if let nextDictionary = images[0] as? [String:Any?] {
			
			if let resolutions = nextDictionary["resolutions"] as? NSArray {
				
				var highest = 0
				var index = 0
				if resolutions.count < 1 {
					return nil
				}
				for i in 0..<resolutions.count {
					if let result = resolutions[i] as? [String:Any?] {
						if let imageWidth = result["width"] as? Int {
							if imageWidth > highest {
								highest = imageWidth
								index = i
							}
						}
					}
				}
				guard let previewURL = (resolutions[index] as! [String:Any?])["url"] as? String else {
					print("String does not exist here")
					return nil
				}
				if let URL = URL(string: previewURL.replacingOccurrences(of: "&amp;", with: "&", options: .literal, range: nil)){
					return URL
				}
			}
		}
		return nil
	}
	
	/**
	Subreddit name that the post belongs to
	*/
	var subreddit: String? {
		return data["subreddit"] as? String
	}
	
	/**
	ID Name used by Reddit for identification
	*/
	var id: String? {
		return data["name"] as? String
	}
	
	/**
	Link to Post's comment section
	*/
	var commentLink: URL? {
		if let permalink = data["permalink"] as? String {
			return URL(string: "https://www.reddit.com" + permalink.replacingOccurrences(of: "&amp;", with: "&", options: .literal, range: nil))
		}
		return nil
	}
	
	/**
	Whether the content link is marked NSFW
	*/
	var isNSFW: Bool {
		return thumbnail?.absoluteString == "nsfw"
	}
	
	/**
	Whether the content link is a self post
	*/
	var isSelfPost: Bool {
		return thumbnail?.absoluteString == "self"
	}
}
