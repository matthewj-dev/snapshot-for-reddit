import Foundation

/**
Used to get subreddits and posts from Reddit's API
*/
class RedditHandler {
	var authenticatedUser: AuthenticatedUser? = nil
	
	init (authenticatedUser: AuthenticatedUser? = nil) {
		self.authenticatedUser = authenticatedUser
	}
	
	/**
	- Parameter authCode: String user authorization code to login
	
	- Returns:
	*/
	func getAuthenticatedUser(authCode: String) -> AuthenticatedUser? {
		
		var authData: [String:Any]? = nil
		
		// http request for oauth
		var request = URLRequest(url: URL(string: "https://www.reddit.com/api/v1/access_token")!)
		// make the request POST
		request.httpMethod = "POST"
		
		// fill the request body with the auth code from the callback
		request.httpBody = "grant_type=authorization_code&code=\(authCode)&redirect_uri=snapshot://response".data(using: .utf8)
		
		// add developer code to HTTP header
		let authorizationString = "udgVMzpax63hJQ:".data(using: .utf8)?.base64EncodedString()
		request.addValue("Basic \(authorizationString!)", forHTTPHeaderField: "Authorization")
		
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
	
	private func getRedditResponse(url: URL) -> RedditResponse? {
		
		if authenticatedUser != nil {
			print("Authenticated User Found")
			if authenticatedUser!.tokenIsExpired() {
				if !authenticatedUser!.refreshAccessToken() {
					print("Proceeding as unauthenticated")
					let request = URLRequest(url: url)
					return getRedditResponse(request: request)
				}
			}
			print(url.absoluteString.components(separatedBy: "https://www.reddit.com"))
			let newSuffix = url.absoluteString.components(separatedBy: "https://www.reddit.com")[1]
			print("New Suffix: \(newSuffix)")
			return getRedditResponse(request: authenticatedUser!.getAuthenticatedRequest(urlSuffix: newSuffix))
		}
		let request = URLRequest(url: url)
		return getRedditResponse(request: request)
	}
	
	/**
	Creates a subreddit with a RedditResponse
	- Parameter response: RedditResponse from Reddit API
	
	- Returns: Subreddit
	*/
	private func getSubreddit(response:RedditResponse) -> Subreddit? {
		do  {
			return try Subreddit(response: response)
		}
		catch {
			return nil
		}
	}
	
	/**
	Creates a subreddit from a Json formatted Subreddit URL
	- Parameter url: URL formatted with the json suffix
	
	- Returns: Subreddit
	*/
	func getSubreddit(url:URL, type: Subreddit.SubredditType = .normal) -> Subreddit? {
		if let response = getRedditResponse(url: url){
			do {
				return try Subreddit(response: response, type: type)
			}
			catch {
				print(error)
				return nil
			}
		}
		else {
			return nil
		}
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
		if id != nil {
			let stringURL = "https://www.reddit.com/r/" + name + "/.json?limit=" + String(count) + "&after=" + id!
			if let url = URL(string: stringURL) {
				print(url)
				return getSubreddit(url: url, type: type)
			}
		}
		else {
			let stringURL = "https://www.reddit.com/r/" + name + "/.json?limit=" + String(count)
			if let url = URL(string: stringURL) {
				print(url)
				return getSubreddit(url: url, type: type)
			}
		}
		return nil
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
	
	func getUser(username: String) -> RedditUser? {
		let userURLString = "https://www.reddit.com/user/\(username)/about.json"
		let postsURLString = "https://www.reddit.com/user/\(username).json"
		
		guard let url = URL(string: userURLString), let postsURL = URL(string: postsURLString) else {
			return nil
		}
		
		guard let response = getRedditResponse(url: url), let postsResponse = getRedditResponse(url: postsURL) else {
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
		Parsed from JSON response
		*/
		var parsedData: [String:Any]? {
			guard let returnableData = data["data"] as? [String:Any] else {
				return nil
			}
			return returnableData
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
		var name: String?
		let type: SubredditType
		let bannerURL: URL?
		
		/**
		- Parameter response: Response from Reddit API
		- Parameter type: Type of subreddit to create
		
		- throws: If the subreddit is invalid or there is an issue parsing
		*/
		init(response:RedditResponse, type:SubredditType = .normal) throws {
			self.type = type
			
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
			if !posts.isEmpty {
				name = posts[0].subreddit
			}
			
			// Gets banner URL if subreddit name is not nil
			if name != nil {
				
				if let tempResponse = RedditHandler().getRedditResponse(url: URL(string: "https://www.reddit.com/r/\(name!)/about.json")!){
					
					if let parsedData = tempResponse.parsedData as? [String:Any] {
						
						if var urlString = parsedData["banner_img"] as? String {
							
							urlString = urlString.replacingOccurrences(of: "&amp;", with: "&", options: .literal, range: nil)
							bannerURL = URL(string: urlString)
						}
						else {
							print("No Key")
							bannerURL = nil
						}
					}
					else{
						bannerURL = nil
					}
				}
				else {
					print("Response not valid")
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
			
			if let name = name, let id = self[postCount - 1]?.id {
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
	
	class RedditUser {
		let data: [String:Any?]
		let posts: [Subreddit.RedditPost]
		
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
		
		var name: String? {
			guard let username = data["name"] as? String else {
				return nil
			}
			return username
		}
		
		var postKarma: String? {
			guard let importantKarma = data["link_karma"] as? Int else {
				return nil
			}
			return String(importantKarma)
		}
		
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
	*/
	class AuthenticatedUser: RedditUser {
		var accessToken: String
		var refreshToken: String
		var authenticationData: Dictionary<String, Any>
		var expireyDate: Date?
		
		init(authResponse: RedditResponse) throws {
			
			let apiInstance = RedditHandler()
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
			
			guard let accessResponse = apiInstance.getRedditResponse(request: request) else {
				throw UserError.invalidResponse()
			}
			guard let username = accessResponse.data["name"] as? String else {
				throw UserError.invalidResponse()
			}
			
			let userURLString = "https://www.reddit.com/user/\(username)/about.json"
			let postsURLString = "https://www.reddit.com/user/\(username).json"
			
			guard let url = URL(string: userURLString), let postsURL = URL(string: postsURLString) else {
				throw UserError.invalidURLs()
			}
			
			guard let response = RedditHandler().getRedditResponse(url: url), let postsResponse = RedditHandler().getRedditResponse(url: postsURL) else {
				throw UserError.invalidResponse()
			}
			
			do {
				authenticationData = authResponse.data
				try super.init(aboutResponse: response, postsResponse: postsResponse)
				print("WE DID IT!")
			}
			catch {
				throw error
			}
			
		}
		
		func refreshAccessToken() -> Bool {
			var request = URLRequest(url: URL(string: "https://www.reddit.com/api/v1/access_token")!)
			// make the request POST
			request.httpMethod = "POST"
			
			// fill the request body with the auth code from the callback
			request.httpBody = "grant_type=refresh_token&refresh_token=\(refreshToken)".data(using: .utf8)
			
			// add developer code to HTTP header
			let authorizationString = "udgVMzpax63hJQ:".data(using: .utf8)?.base64EncodedString()
			request.addValue("Basic \(authorizationString!)", forHTTPHeaderField: "Authorization")
			
			guard let authResponse = RedditHandler().getRedditResponse(request: request) else {
				return false
			}
			
			guard let authToken = authResponse.data["access_token"] as? String, let refreshToken = authResponse.data["refresh_token"] as? String else {
				return false
			}
			
			accessToken = authToken
			self.refreshToken = refreshToken
			
			if let deadTime = authResponse.data["expires_in"] as? Int {
				expireyDate = Date().addingTimeInterval(TimeInterval(deadTime))
			}
			else {
				return false
			}
			
			return true
		}
		
		
		func tokenIsExpired() -> Bool {
			return Date() > expireyDate!
		}
		
		func getAuthenticatedRequest(urlSuffix: String) -> URLRequest {
			let url = "https://oauth.reddit.com" + urlSuffix
			var request = URLRequest(url: URL(string: url)!)
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
