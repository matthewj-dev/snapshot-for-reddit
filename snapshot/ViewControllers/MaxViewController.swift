//
//  MaxViewController.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/15/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit
import SafariServices
import ImageIO
import AVFoundation
import AVKit

class MaxViewController: UIViewController {

    @IBOutlet var maxView: UIImageView!
    @IBOutlet weak var postTitle: UILabel!
	@IBOutlet weak var player: UIView!
	
    var ncObject = NotificationCenter.default
	
	var avPlayer: AVPlayer!
	var playerLayer = AVPlayerLayer()
	
    var imageToLoad: URL!
    var subreddit: Subreddit!
    var index = 0
    
    override func loadView() {
        super.loadView()
		
        //Creates gesture to dismiss view
        let tappy = UITapGestureRecognizer(target: self, action: #selector(dismissView))
		
		let holdy = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        
        //Creates gesture to change image when swiping left
        let swippyLeft = UISwipeGestureRecognizer(target: self, action: #selector(changeImageLeft))
        swippyLeft.direction = .left
        
        //Creates gesture to change image when swiping right
        let swippyRight = UISwipeGestureRecognizer(target: self, action: #selector(changeImageRight))
        swippyRight.direction = .right
        
        //Adds gestures to the image and views
        self.view.addGestureRecognizer(tappy)
		self.player.addGestureRecognizer(tappy)
        maxView.addGestureRecognizer(tappy)
		maxView.addGestureRecognizer(holdy)
        maxView.addGestureRecognizer(swippyRight)
        maxView.addGestureRecognizer(swippyLeft)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = subreddit[index]?.preview {
            imageToLoad = image
            postTitle.text = subreddit[index]?.title
            //Switches URL to load if it is of certain types
            if let contentURL = subreddit[index]?.content, ["png","jpg","gif"].contains(contentURL.pathExtension) {
                print(contentURL.pathExtension)
                imageToLoad = contentURL
            }
			else if let contentURL = subreddit[index]?.content, ["mp4","webm","gifv"].contains(contentURL.pathExtension) {
				print(contentURL.pathExtension)
				var videoURL = contentURL
				videoURL = URL(string: videoURL.absoluteString.replacingOccurrences(of: ".webm", with: ".mp4"))!
				videoURL = URL(string: videoURL.absoluteString.replacingOccurrences(of: ".gifv", with: ".mp4"))!
				
				self.maxView.image = nil
				print(videoURL)
				avPlayer = AVPlayer(url: videoURL)
				playerLayer = AVPlayerLayer(player: avPlayer)
				playerLayer.frame = self.player.frame
				
				self.view.layer.addSublayer(playerLayer)
				
				avPlayer.play()
				
				return
			}
			else {
				print("Nothing special about: \(subreddit[index]?.content)")
			}
        }
        else {
            return
        }
        playerLayer.removeFromSuperlayer()
        DispatchQueue.global().async {
            do{
                let imageData = try Data(contentsOf: self.imageToLoad)
                
                if self.imageToLoad.pathExtension == "gif"{
                    let gifToLoad = UIImage.animatedImage(data: imageData)
                    DispatchQueue.main.sync {
                        self.maxView.image = gifToLoad
                        self.maxView.startAnimating()
                    }
                }
                else {
                    DispatchQueue.main.sync {
                        self.maxView.image = UIImage(data: imageData)
                    }
                }
            }
            catch{
                print("Image loading has failed")
            }
        }
    }
	
	override func viewDidLayoutSubviews() {
		playerLayer.frame = player.frame
	}
	
	@objc func longPress() {
		// Creates UIAlertController
		let alert = UIAlertController(title: "Actions", message: "Select an action to perform", preferredStyle: .actionSheet)
		
		// Action creates a SafariViewController and then presents it
		alert.addAction(UIAlertAction(title: "Open in Safari", style: .default, handler: { Void in
			let safariView = SFSafariViewController(url: (self.subreddit[self.index]?.content)!)
			self.present(safariView, animated: true, completion: nil)
		}))
		
		// Sharing Action button
		alert.addAction(UIAlertAction(title: "Share", style: .default, handler: { Void in
			
			// Creates new UIAlertController for selection share option
			let shareAlert = UIAlertController(title: "Sharing", message: "Select what to share", preferredStyle: .actionSheet)
			
			// Action button that when pressed creates a sharesheet with the shareable content being the Image currently loaded
			shareAlert.addAction(UIAlertAction(title: "Image", style: .default, handler: { Void in
				let shareSheet = UIActivityViewController(activityItems: [self.maxView.image], applicationActivities: nil)
				self.present(shareSheet, animated: true, completion: nil)
			}))
			
			// Action button that when pressed creates a sharesheet with the shareable content being the url for the content currently loaded
			shareAlert.addAction(UIAlertAction(title: "Link", style: .default, handler: { Void in
				let shareSheet = UIActivityViewController(activityItems: [(self.subreddit[self.index]?.content)!], applicationActivities: nil)
				self.present(shareSheet, animated: true, completion: nil)
			}))
			shareAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			
			// If the current image loaded into the ImageView is nil then the button for image is disabled
			if self.maxView.image == nil {
				shareAlert.actions[0].isEnabled = false
			}
			
			// Presents the share selection controller
			self.present(shareAlert, animated: true, completion: nil)
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		// Presents first UIAlertController
		self.present(alert, animated: true, completion: nil)
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
