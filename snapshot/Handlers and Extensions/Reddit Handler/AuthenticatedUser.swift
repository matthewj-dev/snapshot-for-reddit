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
class AuthenticatedUser: RedditUser, NSCoding {
    
    

    
    
    
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
    
    /**
    Decodes object and verifies that expire date has not passed
    */
    required init?(coder aDecoder: NSCoder) {
        let packagedData = aDecoder.decodeObject(forKey: "packagedContents") as! [String:Any]
        
        authenticationData = packagedData["authenticationData"] as! [String:Any]
        accessToken = authenticationData["access_token"] as! String
        refreshToken = packagedData["refreshToken"] as! String
        expireyDate = (packagedData["expireDate"] as! Date)
        
        //If expireydate for access token has passed, a new request is created and sent to obtain new access token and expire time
        if Date() > expireyDate! {
			print("Token expired, retrieving new.")
            let api = RedditHandler()
            if let response = api.getRedditResponse(request: api.getAccessTokenRequest(grantType: "refresh_token", grantLogic: "refresh_token=\(self.refreshToken)")) {
                authenticationData = response.jsonReturnedData
                
                if response.httpResponseCode == 200 {
                    accessToken = authenticationData["access_token"] as! String
                    expireyDate = Date().addingTimeInterval(TimeInterval(authenticationData["expires_in"] as! Int))
                }
                
            }
        }
        super.init(userData: packagedData["userData"] as! [String:Any], postsData: nil)
    }
    
    /**
    Creates dictionary of data needed to restore object
    - Returns: Dictionary
    */
    private func packageDataforFutureCreation() -> [String:Any] {
        var packagedData = [String:Any]()
        
        packagedData["username"] = name!
        packagedData["authenticationData"] = authenticationData
        packagedData["accessToken"] = accessToken
        packagedData["userData"] = data
        packagedData["expireDate"] = expireyDate
		packagedData["refreshToken"] = refreshToken
        
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
		saveUserToFile()
        return true
    }
    
    /**
    Compares current date to determine whether the key has expired
    - Returns: Bool on state of if key has expired
    */
    func tokenIsExpired() -> Bool {
		print("Token is expired")
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
    
    /**
    Encode object with persistent storage
    */
    func encode(with aCoder: NSCoder) {
        aCoder.encode(packageDataforFutureCreation(), forKey: "packagedContents")
    }
	
	/**
	Saves AuthenticatedUser to file
	*/
	func saveUserToFile() {
		let saveLocation = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!).appendingPathComponent("userData").path
		NSKeyedArchiver.archiveRootObject(self, toFile: saveLocation)
	}
}
