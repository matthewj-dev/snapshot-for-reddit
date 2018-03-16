//
//  MaxViewController.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/15/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class MaxViewController: UIViewController {

    @IBOutlet var maxView: UIImageView!
    
    var ncObject = NotificationCenter.default
    
    var imageToLoad: URL!
    var subreddit: Subreddit!
    var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		if let image = subreddit[index]?.preview {
			imageToLoad = image
			
			//Switches URL to load if it is of certain types
			if let contentURL = subreddit[index]?.content, ["png","jpg"].contains(contentURL.pathExtension) {
				print(contentURL.pathExtension)
				imageToLoad = contentURL
			}
		}
        else {
            return
        }
		
        DispatchQueue.global().async {
            do{
                let imageData = try Data(contentsOf: self.imageToLoad)
                DispatchQueue.main.sync {
					
                    self.maxView.image = UIImage(data: imageData)
					if self.imageToLoad.pathExtension == "gif" {
						self.maxView.startAnimating()
					}
                }
            }
            catch{
                print("Image loading has failed")
            }
        }
		
		//Creates gesture to dismiss view
		let tappy = UITapGestureRecognizer(target: self, action: #selector(dismissView))
		
		//Creates gesture to change image when swiping left
		let swippyLeft = UISwipeGestureRecognizer(target: self, action: #selector(changeImageLeft))
		swippyLeft.direction = .left
		
		//Creates gesture to change image when swiping right
		let swippyRight = UISwipeGestureRecognizer(target: self, action: #selector(changeImageRight))
		swippyRight.direction = .right
		
		//Adds gestures to the image and views
		self.view.addGestureRecognizer(tappy)
        maxView.addGestureRecognizer(tappy)
        maxView.addGestureRecognizer(swippyRight)
        maxView.addGestureRecognizer(swippyLeft)
    }
    
    @objc func dismissView() {
        ncObject.post(name: Notification.Name.init(rawValue: "isDismissed"), object: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func changeImageLeft() {
        if index + 1 <= subreddit.postCount - 1 {
            self.index += 1
            self.viewDidLoad()
        }
    }
    
    @objc func changeImageRight() {
        if index > 0 {
            self.index -= 1
            self.viewDidLoad()
        }
    }
}
