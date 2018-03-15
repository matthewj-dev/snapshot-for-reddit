import Foundation

/**
 Used to get subreddits and posts from Reddit's API
 */
class RedditHandler {
    var authenticatedUser: AuthenticatedUser? = nil
    
    /**
     Sets an authenticated user to be used with Reddit API Requests
     */
    init (authenticatedUser: AuthenticatedUser? = nil) {
        self.authenticatedUser = authenticatedUser
    }
    
    
    private func getAccessTokenRequest(grantType: String, grantLogic: String) -> URLRequest {
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
        let request = getAccessTokenRequest(grantType: "authorization_code", grantLogic: "code=\(authCode)")
        
        //Creates and enters DispatchGroup
        let group = DispatchGroup()
        group.enter()
        
        let task = URLSession.shared.dataTask(with: request) {data, response, error in
            print((response as? HTTPURLResponse)?.statusCode)
            if data != nil, error == nil {
                do {
                    if let jsonData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]{
                        authData = jsonData
                    }
                }
                catch {
                    print(error)
                }
            }
            else {
                print(error)
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
                var authUser = try AuthenticatedUser(authResponse: RedditResponse(jsonReturnData: authData!))
                return authUser
            }
            catch {
                print("No go")
            }
        }
        return nil
    }
    
    /**
     Create an Authenticated User from packaged data from a previous Authenticated User
     - Parameter packagedData: Dictionary from previous authorized user
     - Returns: AuthenticatedUser?
     */
    func getAuthenticatedUser(packagedData: [String:Any]) -> AuthenticatedUser? {
        do {
            let authUser = try AuthenticatedUser(packagedData: packagedData)
            return authUser
        }
        catch {
            print(error)
        }
        return nil
    }
    
    /**
     Creates a RedditResponse object that is able to be parsed by the Subreddit constructor.
     Will wait until response is returned.
     - Parameter url: URL object to Reddit API to be parsed
     
     - Returns: RedditResponse object
     */
    private func getRedditResponse(request: URLRequest) -> RedditResponse? {
        
        var redditResponse: RedditResponse? = nil
        
        //Creates and enters DispatchGroup
        let responseGroup = DispatchGroup()
        responseGroup.enter()
        
        let responseTask = URLSession.shared.dataTask(with: request) {data, response, error in
            print((response as? HTTPURLResponse)?.statusCode)
            if data != nil, error == nil {
                do {
                    if let jsonData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]{
                        redditResponse = RedditResponse(jsonReturnData: jsonData)
                    }
                }
                catch {
                    print(error)
                }
            }
            else {
                print(error)
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
    private func getRedditResponse(urlSuffix: String) -> RedditResponse? {
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
    
    /**
     Base Json response from Reddit API - Used to pass into other constructors for parsing
     */
    class RedditResponse {
        let data: [String:Any]
        
        /**
         - Parameter jsonReturnData: Dictionary created from the Reddit API
         */
        init(jsonReturnData:[String:Any]) {
            data = jsonReturnData
        }
        
        /**
         Parsed data object from JSON response
         */
        var parsedData: [String:Any]? {
            guard let returnableData = data["data"] as? [String:Any] else {
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
    }
    
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
            
            guard let data = response.data["data"] as? [String:Any] else {
                throw RedditError.invalidSubreddit("Subreddit does not exist")
            }
            guard let children = data["children"] as? NSArray else {
                throw RedditError.invalidParse("Error parsing children data")
            }
            for i in children {
                guard let postData = (i as? [String:Any]) else {
                    throw RedditError.invalidParse("Unable to parse post")
                }
                guard let useablePostData = postData["data"] as? [String:Any?] else {
                    throw RedditError.invalidParse("Unable to parse post")
                }
                switch type {
                case .image:
                    if useablePostData["thumbnail"] != nil {
                        posts.append(RedditPost(postData: useablePostData))
                    }
                    break
                default:
                    posts.append(RedditPost(postData: useablePostData))
                }
            }
            
            // Gets banner URL if subreddit name is not nil
            if !name.isEmpty {
                
                if let tempResponse = RedditHandler().getRedditResponse(urlSuffix: "/r/\(name)/about.json"){
                    
                    if let banner = tempResponse.data["banner_img"] as? String {
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
    }
    
    /**
     Reddit user. Has access to posts and details of user
     */
    class RedditUser {
        let data: [String:Any?]
        let posts: [Subreddit.RedditPost]
        
        /**
         - Parameters:
         - aboutResponse: RedditResponse of users about page
         - postsResponse: RedditResponse of users main page
         */
        init(aboutResponse: RedditResponse, postsResponse: RedditResponse) throws {
            guard let userData = aboutResponse.parsedData else {
                throw UserError.invalidParse("Unable to parse some user data")
            }
            data = userData
            
            do {
                let tempSub = try Subreddit(response: postsResponse)
                posts = tempSub.posts
            }
            catch {
                print("User posts not found")
                print(error)
                throw error
            }
        }
        
        //        private init (userData: [String:Any?], postsData: [Subreddit.RedditPost]){
        //
        //        }
        
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
            
            if let deadTime = authResponse.data["expires_in"] as? Int {
                expireyDate = Date().addingTimeInterval(TimeInterval(deadTime))
            }
            
            
            guard let authToken = authResponse.data["access_token"] as? String, let refreshToken = authResponse.data["refresh_token"] as? String else {
                throw UserError.invalidParse("User token not available")
            }
            
            accessToken = authToken
            self.refreshToken = refreshToken
            
            request.addValue("com.lapis.snapshot:v1.2 (by /u/Pokeh321)", forHTTPHeaderField: "User-Agent")
            request.addValue("bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            guard let accessResponse = api.getRedditResponse(request: request) else {
                throw UserError.invalidResponse()
            }
            guard let username = accessResponse.data["name"] as? String else {
                throw UserError.invalidResponse()
            }
            
            guard let response = api.getRedditResponse(urlSuffix: "/user/\(username)/about.json"), let postsResponse = api.getRedditResponse(urlSuffix: "/user/\(username).json") else {
                throw UserError.invalidResponse()
            }
            
            do {
                authenticationData = authResponse.data
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
                
                guard let authToken = authResponse.data["access_token"] as? String else {
                    print("Token parse failure")
                    throw UserError.invalidParse("Token is invalid")
                }
                
                accessToken = authToken
                
                if let deadTime = authResponse.data["expires_in"] as? Int {
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
            
            guard let authToken = authResponse.data["access_token"] as? String else {
                print("Token parse failure")
                return false
            }
            
            accessToken = authToken
            
            if let deadTime = authResponse.data["expires_in"] as? Int {
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
    
    enum RedditError: Error {
        case invalidSubreddit(String)
        case invalidParse(String)
    }
}

