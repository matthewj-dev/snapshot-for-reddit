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
        
        
        if var image = subreddit[index]?.preview {
            imageToLoad = image
        }
        else {
            return
        }

        DispatchQueue.global().async {
            do{
                let imageData = try Data(contentsOf: self.imageToLoad)
                DispatchQueue.main.sync {
                    self.maxView.image = UIImage(data: imageData)
                }
            }
            catch{
                print("No u")
            }
        }
        
        let tappy = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        
        maxView.addGestureRecognizer(tappy)
        
        let swippyLeft = UISwipeGestureRecognizer(target: self, action: #selector(changeImageLeft))
        
        swippyLeft.direction = .left
        
        maxView.addGestureRecognizer(swippyLeft)
        
        let swippyRight = UISwipeGestureRecognizer(target: self, action: #selector(changeImageRight))
        
        swippyRight.direction = .right
        
        maxView.addGestureRecognizer(swippyRight)
        
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
