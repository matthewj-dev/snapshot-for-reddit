import Foundation

/**
 Used to get subreddits and posts from Reddit's API
 */
class RedditHandler {
    var authenticatedUser: AuthenticatedUser? = nil
    
    /**
	Sets an authenticated user to be used with Reddit API Requests
	- Parameter authenticatedUser: Authenticated user to be used for Reddit Requests
     */
    init (authenticatedUser: AuthenticatedUser? = nil) {
        self.authenticatedUser = authenticatedUser
    }
    
    /**
	Creates a URL request for an access token using
	*/
    internal func getAccessTokenRequest(grantType: String, grantLogic: String) -> URLRequest {
        // http request for oauth
        var request = URLRequest(url: URL(string: "https://www.reddit.com/api/v1/access_token")!)
        // make the request POST
        request.httpMethod = "POST"
        
        // fill the request body with the auth code from the callback
        request.httpBody = "grant_type=\(grantType)&\(grantLogic)&redirect_uri=snapshot://response".data(using: .utf8)
        
        // add developer code to HTTP header
        let authorizationString = "udgVMzpax63hJQ:".data(using: .utf8)?.base64EncodedString()
        request.addValue("Basic \(authorizationString!)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    /**
     Creates an Authenticated User from an authorization code obtained from Reddit
     - Parameter authCode: String user authorization code from Oauth callback
     - Returns: AuthenticatedUser
     */
    func getAuthenticatedUser(authCode: String) -> AuthenticatedUser? {
        
        var authData: [String:Any]? = nil
		var responseCode = 0
        let request = getAccessTokenRequest(grantType: "authorization_code", grantLogic: "code=\(authCode)")
        
        //Creates and enters DispatchGroup
        let group = DispatchGroup()
        group.enter()
        
        let task = URLSession.shared.dataTask(with: request) {data, response, error in
			print((response as? HTTPURLResponse)?.statusCode as Any)
            if data != nil, error == nil {
                do {
                    if let jsonData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]{
                        authData = jsonData
						responseCode = (response! as! HTTPURLResponse).statusCode
                    }
                }
                catch {
                    print(error)
                }
            }
            else {
				print(error!)
            }
            
            //Leave DispatchGroup once the callback has concluded
            group.leave()
        }
        //Starts the task
        task.resume()
        
        //Waits for the DispatchGroup
        group.wait()
        
        print("Group Exited")
        if authData != nil {
            do {
				let authUser = try AuthenticatedUser(authResponse: RedditResponse(jsonReturnData: authData!, httpResponseCode: responseCode))
                return authUser
            }
            catch {
                print("Error creating authorized data")
            }
        }
        return nil
    }
    
    /**
     Creates a RedditResponse object that is able to be parsed by the Subreddit constructor.
     Will wait until response is returned.
     - Parameter url: URL object to Reddit API to be parsed
     
     - Returns: RedditResponse object
     */
    func getRedditResponse(request: URLRequest) -> RedditResponse? {
        
        var redditResponse: RedditResponse? = nil
        
        //Creates and enters DispatchGroup
        let responseGroup = DispatchGroup()
        responseGroup.enter()
        
        let responseTask = URLSession.shared.dataTask(with: request) {data, response, error in
			print((response as? HTTPURLResponse)?.statusCode as Any)
            if data != nil, error == nil {
                do {
                    if let jsonData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]{
						redditResponse = RedditResponse(jsonReturnData: jsonData, httpResponseCode: (response as! HTTPURLResponse).statusCode)
                    }
                }
                catch {
                    print(error)
                }
            }
            else {
				print(error!)
            }
            
            //Leave DispatchGroup once the callback has concluded
            responseGroup.leave()
        }
        //Starts the task
        responseTask.resume()
        
        //Waits for the DispatchGroup
        responseGroup.wait()
        
        return redditResponse
    }
    
    /**
     Creates a RedditResponse from a URL. Will use stored AuthenticatedUser to attempt to create authenticated response
     - Parameter urlSuffix: Portion to add to Reddit API request (e: /u/User)
     - Returns: RedditResponse
     */
    func getRedditResponse(urlSuffix: String) -> RedditResponse? {
        let url: URL
        if authenticatedUser != nil {
            if !authenticatedUser!.tokenIsExpired() || authenticatedUser!.refreshAccessToken() {
                url = URL(string: "https://oauth.reddit.com" + urlSuffix)!
                print(url)
                return getRedditResponse(request: authenticatedUser!.getAuthenticatedRequest(url: url))
            }
        }
        
        url = URL(string: "https://reddit.com" + urlSuffix)!
        print(url)
        return getRedditResponse(request: URLRequest(url: url))
        
    }
    
    /**
     Creates a subreddit from the Subreddit's name
     - Parameter name: String name of the subreddit
     - Parameter count: DEFAULT 25 - Number of posts to fetch
     - Parameter id: (Optional) ID to append for when fetching additional items past initial load
     - Parameter type: DEFAULT normal - Type of subreddit to create
     
     - Returns: Subreddit
     */
    func getSubreddit(Subreddit name:String, count: Int = 25 ,id: String? = nil, type: Subreddit.SubredditType = .normal) -> Subreddit? {
        let suffix: String
        
        if name.isEmpty {
            if id != nil {
                suffix = "/.json?limit=\(String(count))&after=\(id!)"
            }
            else {
                suffix = "/.json?limit=\(String(count))"
            }
        }
        else {
            if id != nil {
                suffix = "/r/\(name)/.json?limit=\(String(count))&after=\(id!)"
            }
            else {
                suffix = "/r/\(name)/.json?limit=\(String(count))"
            }
        }
        
        do {
            guard let response = getRedditResponse(urlSuffix: suffix) else {
                return nil
            }
            return try Subreddit(response: response, name: name)
        }
        catch {
            print(error)
            return nil
        }
    }
    
    /**
     Creates a subreddit asyncriously and feeds the subreddit into the completion block
     - Parameter Subreddit: String name of the subreddit
     - Parameter count: DEFAULT 25 - Number of posts to fetch
     - Parameter id: (Optional) ID to append for when fetching additional items past initial load
     - Parameter type: DEFAULT normal - Type of subreddit to create
     - Parameter completion: Block with subreddit? parameter with no return
     */
    func asyncGetSubreddit(Subreddit name: String, count: Int = 25, id: String? = nil, type: Subreddit.SubredditType = .normal, completion: @escaping (Subreddit?) -> Void) {
        DispatchQueue.global().async {
            let sub = self.getSubreddit(Subreddit: name, count: count, id: id, type: type)
            DispatchQueue.main.async {
                completion(sub)
            }
        }
    }
    
    /**
     Creates a RedditUser object from a username
     - Parameter username: String of a reddit username
     - Returns: RedditUser
     */
    func getUser(username: String) -> RedditUser? {
        
        guard let response = getRedditResponse(urlSuffix: "/user/\(username)/about.json"), let postsResponse = getRedditResponse(urlSuffix: "/user/\(username).json") else {
            return nil
        }
        do {
            return try RedditUser.init(aboutResponse: response, postsResponse: postsResponse)
        }
        catch {
            print(error)
            return nil
        }
        
    }
}

