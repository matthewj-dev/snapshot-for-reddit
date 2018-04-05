//
//  JSON.swift
//
//  Created by Hunter Forbus on 4/1/18.
//  Copyright © 2018 Hunter Forbus. All rights reserved.
//

/**
JSON object that can parse items multiple levels down
*/
struct JSON {
	private var data = [String:Any]()
	private let isArray: Bool
	
	init(json: [String:Any]) {
		data = json
		isArray = false
	}
	
	init(json: [Any]) {
		data = ["array":json]
		isArray = true
	}
	
	/**
	Parses Bool at a JSONPath
	- Parameter jsonPath: JSONPath to Bool
	- Returns: Bool?
	*/
	func parseBool(at jsonPath: JSONPath) -> Bool? {
		if isArray {
			return traverse(path: jsonPath.byInserting(at: 0, pathItem: "array"), type: Bool.self)
		}
		return traverse(path: jsonPath, type: Bool.self)
	}
	
	/**
	Parses String at a JSONPath
	- Parameter jsonPath: JSONPath to String
	- Returns: String?
	*/
	func parseString(at jsonPath: JSONPath) -> String? {
		if isArray {
			return traverse(path: jsonPath.byInserting(at: 0, pathItem: "array"), type: String.self)
		}
		return traverse(path: jsonPath, type: String.self)
	}
	
	/**
	Parses Int at a JSONPath
	- Parameter jsonPath: JSONPath to Int
	- Returns: Int?
	*/
	func parseInt(at jsonPath: JSONPath) -> Int? {
		if isArray {
			return traverse(path: jsonPath.byInserting(at: 0, pathItem: "array"), type: Int.self)
		}
		return traverse(path: jsonPath, type: Int.self)
	}
	
	/**
	Parses Float at a JSONPath
	- Parameter jsonPath: JSONPath to Float
	- Returns: Float?
	*/
	func parseFloat(at jsonPath: JSONPath) -> Float? {
		if isArray {
			return traverse(path: jsonPath.byInserting(at: 0, pathItem: "array"), type: Float.self)
		}
		return traverse(path: jsonPath, type: Float.self)
	}
	
	/**
	Parses Dictionary of [String:Any] at a JSONPath
	- Parameter jsonPath: JSONPath to Dictionary
	- Returns: Dictionary?
	*/
	func parseDictionary(at jsonPath: JSONPath) -> [String:Any]? {
		if isArray {
			return traverse(path: jsonPath.byInserting(at: 0, pathItem: "array"), type: [String:Any].self)
		}
		return traverse(path: jsonPath, type: [String:Any].self)
	}
	
	/**
	Parses Array at a JSONPath
	- Parameter jsonPath: JSONPath to Array
	- Returns: Array?
	*/
	func parseArray(at jsonPath: JSONPath) -> [Any]? {
		if isArray {
			return traverse(path: jsonPath.byInserting(at: 0, pathItem: "array"), type: [Any].self)
		}
		return traverse(path: jsonPath, type: [Any].self)
	}
	
	/**
	Uses the JSONPath to go through the JSON Object and returns the value specified to it
	- Parameter jsonPath: JSONPath to Bool
	- Parameter type: Type of object the function will attempt to parse
	- Returns: Type?
	*/
	private func traverse<Type>(path: JSONPath, type: Type.Type) -> Type? {
		var currentArray = [Any]()
		var currentDictionary: [String:Any]? = nil
		for i in 0..<path.count {
			
			if i == path.count - 1 {
				if let key = path[i] as? String {
					if currentDictionary == nil {
						return data[key] as? Type
					}
					else {
						return currentDictionary![key] as? Type
					}
				}
				else if let index = path[i] as? Int, index < currentArray.count {
					return currentArray[index] as? Type
				}
				else { return nil }
			}
				
			else if let key = path[i] as? String {
				if currentDictionary == nil {
					if let dictionary = data[key] as? [String:Any] {
						currentDictionary = dictionary
					}
					else if let array = data[key] as? [Any] {
						currentArray = array
					}
					else { return nil }
				}
				else {
					if let dictionary = currentDictionary![key] as? [String:Any] {
						currentDictionary = dictionary
					}
					else if let array = currentDictionary![key] as? [Any] {
						currentArray = array
					}
					else { return nil }
				}
			}
			else if let index = path[i] as? Int {
				if index < currentArray.count, let dictionary = currentArray[index] as? [String:Any] {
					currentDictionary = dictionary
				}
				else if index < currentArray.count, let array = currentArray[index] as? [Any] {
					currentArray = array
				}
				else { return nil }
			}
			else { return nil }
			
		}
		
		return nil
	}
	
}

struct JSONPath {
	private var path = [Any]()
	
	init(path: Any...) {
		for i in path {
			if i is Int || i is String {
				self.path.append(i)
			}
		}
	}
	
	private init(path: [Any]){
		self.path = path
	}
	
	var count: Int { return path.count }
	
	subscript(index:Int) -> Any {
		return path[index]
	}
	
	/**
	Returns a new JSONPath object with the new item.
	Does not mutate the original
	- Parameters:
	- at: Index where to insert the item
	- pathItem: Item to be inserting
	- Returns: New JSONPath Object with inserted item
	*/
	func byInserting(at index: Int, pathItem: Any) -> JSONPath {
		if pathItem is Int || pathItem is String {
			var dataToReturn = path
			dataToReturn.insert(pathItem, at: index)
			return JSONPath(path: dataToReturn)
		}
		return self
	}
}
