//
//  AuthenticatedUser.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/15/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import Foundation

/**
Authenticated User that extends from RedditUser. Has access token management functions.
*/
class AuthenticatedUser: RedditUser {
	var accessToken: String
	var refreshToken: String
	var authenticationData: Dictionary<String, Any>
	var expireyDate: Date?
	
	/**
	- Parameter authResponse: RedditResponse object that contains authorization data
	*/
	init(authResponse: RedditResponse) throws {
		
		let api = RedditHandler()
		var request = URLRequest(url: URL(string: "https://oauth.reddit.com/api/v1/me")!)
		
		if let deadTime = authResponse.jsonReturnedData["expires_in"] as? Int {
			expireyDate = Date().addingTimeInterval(TimeInterval(deadTime))
		}
		
		
		guard let authToken = authResponse.jsonReturnedData["access_token"] as? String, let refreshToken = authResponse.jsonReturnedData["refresh_token"] as? String else {
			throw UserError.invalidParse("User token not available")
		}
		
		accessToken = authToken
		self.refreshToken = refreshToken
		
		request.addValue("com.lapis.snapshot:v1.2 (by /u/Pokeh321)", forHTTPHeaderField: "User-Agent")
		request.addValue("bearer \(authToken)", forHTTPHeaderField: "Authorization")
		
		guard let accessResponse = api.getRedditResponse(request: request) else {
			throw UserError.invalidResponse()
		}
		guard let username = accessResponse.jsonReturnedData["name"] as? String else {
			throw UserError.invalidResponse()
		}
		
		guard let response = api.getRedditResponse(urlSuffix: "/user/\(username)/about.json"), let postsResponse = api.getRedditResponse(urlSuffix: "/user/\(username).json") else {
			throw UserError.invalidResponse()
		}
		
		do {
			authenticationData = authResponse.jsonReturnedData
			try super.init(aboutResponse: response, postsResponse: postsResponse)
			print("Authenticated User successfully created")
		}
		catch {
			throw error
		}
	}
	
	init(packagedData: [String:Any]) throws {
		let api = RedditHandler()
		
		guard let authData = packagedData["authenticationData"] as? [String:Any] else {
			throw UserError.invalidParse("Unable to parse Authentication Data")
		}
		
		guard let token = authData["access_token"] as? String, let refreshToken = authData["refresh_token"] as? String else {
			throw UserError.invalidParse("Error parsing from Authentication Data")
		}
		
		guard let name = packagedData["username"] as? String else {
			throw UserError.invalidParse("Error getting username")
		}
		
		guard let expires = packagedData["expireDate"] as? Date else {
			throw UserError.invalidParse("Error parsing previous expirey date")
		}
		
		self.authenticationData = authData
		self.accessToken = token
		self.refreshToken = refreshToken
		self.expireyDate = expires
		
		if Date() > expires {
			let request = api.getAccessTokenRequest(grantType: "refresh_token", grantLogic: "refresh_token=\(self.refreshToken)")
			
			guard let authResponse = api.getRedditResponse(request: request) else {
				print("AuthResponse failure")
				throw UserError.invalidResponse()
			}
			
			guard let authToken = authResponse.jsonReturnedData["access_token"] as? String else {
				print("Token parse failure")
				throw UserError.invalidParse("Token is invalid")
			}
			
			accessToken = authToken
			
			if let deadTime = authResponse.jsonReturnedData["expires_in"] as? Int {
				expireyDate = Date().addingTimeInterval(TimeInterval(deadTime))
			}
			else {
				print("Date Update failure")
				throw UserError.invalidParse("Could not parse expire time")
			}
		}
		
		guard let response = api.getRedditResponse(urlSuffix: "/user/\(name)/about.json"), let postsResponse = api.getRedditResponse(urlSuffix: "/user/\(name).json") else {
			throw UserError.invalidResponse()
		}
		
		do {
			try super.init(aboutResponse: response, postsResponse: postsResponse)
			print("Authenticated User successfully created")
		}
		catch {
			throw error
		}
	}
	
	
	
	func packageDataforFutureCreation() -> [String:Any] {
		var packagedData = [String:Any]()
		
		packagedData["username"] = name!
		packagedData["authenticationData"] = authenticationData
		packagedData["expireDate"] = expireyDate
		
		return packagedData
	}
	
	/**
	Refreshes the access token currently stored using the refresh token that is stored
	- Returns: Bool of whether the refresh was successful or not
	*/
	func refreshAccessToken() -> Bool {
		let api = RedditHandler()
		
		let request = api.getAccessTokenRequest(grantType: "refresh_token", grantLogic: "refresh_token=\(self.refreshToken)")
		
		guard let authResponse = api.getRedditResponse(request: request) else {
			print("AuthResponse failure")
			return false
		}
		
		guard let authToken = authResponse.jsonReturnedData["access_token"] as? String else {
			print("Token parse failure")
			return false
		}
		
		accessToken = authToken
		
		if let deadTime = authResponse.jsonReturnedData["expires_in"] as? Int {
			expireyDate = Date().addingTimeInterval(TimeInterval(deadTime))
		}
		else {
			print("Date Update failure")
			return false
		}
		
		print("Token refresh complete")
		return true
	}
	
	/**
	Compares current date to determine whether the key has expired
	- Returns: Bool on state of if key has expired
	*/
	func tokenIsExpired() -> Bool {
		return Date() > expireyDate!
	}
	
	/**
	Creates an authorized URLRequest based on the currently stored key and passed Oauth URL
	- Parameter urlSuffix: Suffix to add to the end of the oauth request URL
	- Returns: URLRequest that has been setup to authenticate as the current user
	*/
	func getAuthenticatedRequest(url: URL) -> URLRequest {
		var request = URLRequest(url: url)
		request.addValue("com.lapis.snapshot:v1.2 (by /u/Pokeh321)", forHTTPHeaderField: "User-Agent")
		request.addValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		
		return request
	}
	
}
