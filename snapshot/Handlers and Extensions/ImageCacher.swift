//
//  ImageCacher.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/17/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class ImageCacher {
    
    // Dictionary used for caching
    var cache = [String:UIImage]()
    
    /**
    Loads the image cache pair from memory or retrieves it from memory
    - Parameter pair: Pair used for loading and storing the pair
    - Returns: UIImage once the image has been stored
    */
    func retreive(pair: ImageCachePair) -> UIImage? {
        var image: UIImage? = nil
        
        if cache.keys.contains(pair.key) && cache[pair.key] != nil {
            return cache[pair.key]
        }
            
        else {
            do {
                let imageData = try Data(contentsOf: pair.url)
                image = UIImage(data: imageData)
                self.cache[pair.key] = image
            }
            catch {
                image = nil
            }
        }
        return image
    }
    
    /**
    Preloads imagepairs into memory
    - Parameters:
        - pairs: Array of ImageCachePair to iterate through
        - IndexToAsyncAt: At what index should the preloading be taken of the main thread and move to asynchronous loading
        - completion: Code block to be executed before the code moves the asynchronous loading
    */
    func preload(pairs: [ImageCachePair], IndexToAsyncAt: Int, completion: (() -> ())?) {
        var goTo = IndexToAsyncAt
        if pairs.count < IndexToAsyncAt{
            goTo = pairs.count - 1
        }
        
        if !pairs.isEmpty {
            for i in 0 ..< goTo {
                retreive(pair: pairs[i])
            }
            if completion != nil {
                DispatchQueue.main.async {
                    completion!()
                }
            }
            
//            for i in goTo ..< pairs.count {
//                DispatchQueue.global().async {
//                    self.retreive(pair: pairs[i])
//                }
//            }
			DispatchQueue.global().async {
				for i in goTo ..< pairs.count {
					self.retreive(pair: pairs[i])
				}
			}
			
        }
    }
    
}

struct ImageCachePair {
    let key: String
    let url: URL
    
    init(key: String, url: URL) {
        self.key = key
        self.url = url
    }
    
}
