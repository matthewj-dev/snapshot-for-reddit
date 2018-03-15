//
//  RedditRequest.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/15/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import Foundation

/**
Base Json response from Reddit API, also used to parse the data
*/
class RedditResponse {
	/**
	Base response data as dictionary
	*/
	let jsonReturnedData: [String:Any]
	let httpResponseCode: Int
	
	/**
	- Parameter jsonReturnData: Dictionary created from the Reddit API
	*/
	init(jsonReturnData: [String:Any], httpResponseCode: Int) {
		jsonReturnedData = jsonReturnData
		self.httpResponseCode = httpResponseCode
	}
	
	/**
	Parsed data object from JSON response
	*/
	var parsedData: [String:Any]? {
		guard let returnableData = jsonReturnedData["data"] as? [String:Any] else {
			return nil
		}
		return returnableData
	}
	
	/**
	Parsed children data from parsed data
	*/
	var childrenData: NSArray? {
		guard let dataToParse = parsedData else {
			return nil
		}
		guard let children = dataToParse["children"] as? NSArray else {
			return nil
		}
		return children
	}
	
	/**
	Size of children data
	*/
	var childrenDataCount: Int {
		if childrenData == nil {
			return 0
		}
		return childrenData!.count
	}
	
	/**
	Parsed Data from data object of children data - Usually Reddit Posts of a subreddit
	*/
	func parsedChildData(index: Int) -> [String:Any?]? {
		if childrenData == nil || index >= childrenData!.count {
			return nil
		}
		if let postDictionary = childrenData![index] as? [String:Any], let postData = postDictionary["data"] as? [String:Any?] {
			return postData
		}
		return nil
	}
}
