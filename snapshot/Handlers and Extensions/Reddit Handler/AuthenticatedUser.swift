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
    /**
    Date at which the current access token will expire
    */
    var expireyDate: Date?
    
    /**
    - Parameter authResponse: RedditResponse object that contains authorization data
    */
    init(api: RedditHandler, authResponse: RedditResponse) throws {
        
        if let deadTime = authResponse.jsonReturnedData["expires_in"] as? Int {
            expireyDate = Date().addingTimeInterval(TimeInterval(deadTime))
        }
        else {
            throw UserError.invalidParse("Unable to parse date that token will expire")
        }
        
        guard let authToken = authResponse.jsonReturnedData["access_token"] as? String, let refreshToken = authResponse.jsonReturnedData["refresh_token"] as? String else {
            throw UserError.invalidParse("User token not available")
        }
        
        self.accessToken = authToken
        self.refreshToken = refreshToken
        
        var request = URLRequest(url: URL(string: "https://oauth.reddit.com/api/v1/me")!)
        request.addValue("com.lapis.snapshot:v1.2 (by /u/Pokeh321)", forHTTPHeaderField: "User-Agent")
        request.addValue("bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        guard let userData = api.getRedditResponse(request: request) else {
            throw UserError.invalidResponse()
        }
        super.init(userData: userData.jsonReturnedData, postsData: nil)
        
        print("Authenticated User successfully created")
    }
    
    /**
    Decodes object and verifies that expire date has not passed
    */
    required init?(coder aDecoder: NSCoder) {
        let packagedData = aDecoder.decodeObject(forKey: "packagedContents") as! [String:Any]
        
        accessToken = packagedData["accessToken"] as! String
        refreshToken = packagedData["refreshToken"] as! String
        expireyDate = (packagedData["expireDate"] as! Date)
        
        if Date() > expireyDate! {
            print("Token expired, retrieving new.")
            let api = RedditHandler()
            if let response = api.getRedditResponse(request: api.getAccessTokenRequest(grantType: "refresh_token", grantLogic: "refresh_token=\(self.refreshToken)")) {
                
                if response.httpResponseCode == 200 {
                    accessToken = response.jsonReturnedData["access_token"] as! String
                    expireyDate = Date().addingTimeInterval(TimeInterval(response.jsonReturnedData["expires_in"] as! Int))
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
        return Date() > expireyDate!
    }
    
    /**
    Creates an authorized URLRequest based on the currently stored key and passed Oauth URL
    - Parameter urlSuffix: Suffix to add to the end of the oauth request URL
    - Returns: URLRequest that has been setup to authenticate as the current user
    */
    func getAuthenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("com.lapis.snapshot:v1.2", forHTTPHeaderField: "User-Agent")
        request.addValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    /**
    Creates an array of user subscribed subreddits
    - Parameter api: Reddit Handler to handle the request
    - Returns: String Array of Subscribed subreddit capitalized and sorted
    */
    func getSubscribedSubreddits(api: RedditHandler) -> [String] {
        var toReturn = [String]()
        
        if let request = api.getRedditResponse(urlSuffix: "/subreddits/mine/subscriber.json"), request.childrenData != nil {
            for i in 0..<request.childrenDataCount {
                if let subName = request.parsedChildData(index: i)!["display_name_prefixed"] as? String {
                    toReturn.append(subName.components(separatedBy: "r/")[1].capitalized)
                    
                }
            }
        }
        toReturn.sort()
        return toReturn
    }
	
	/**
	Creates a subreddit object with the posts being the contents of the current Authenticated User's saved posts
	- Parameter api: Reddit Handler to handle the request
	- Returns: Subreddit?
	*/
    func getSavedPosts(api: RedditHandler) -> Subreddit? {
        if let name = self.name, let url = URL(string: "https://oauth.reddit.com/user/\(name)/saved.json?limit=100&raw_json=1") {
            let request = getAuthenticatedRequest(url: url)
            if let response = api.getRedditResponse(request: request) {
                do {
                    return try Subreddit(api: api, response: response, name: "", type: .image, isReloadSub: true)
                }
                catch {
                    return nil
                }
            }
        }
        return nil
    }
	
	func asyncGetSavedPosts(api: RedditHandler, completion: ((Subreddit?)->())) {
		let subreddit = getSavedPosts(api: api)
		completion(subreddit)
	}
    
    /**
    Asyncriously get subscribed subreddits and then performs completion handler with the results
    - Parameters:
     - api: Reddit Handler to handle the request
     - completition: Block with [String] parameter of returned array
    */
    func asyncGetSubscribedSubreddits(api: RedditHandler, completition: @escaping ([String])->Void) {
        DispatchQueue.global().async {
            let subreddits = self.getSubscribedSubreddits(api: api)
            DispatchQueue.main.sync {
                completition(subreddits)
            }
        }
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
