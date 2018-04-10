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

class MaxViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet var maxView: UIImageView!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var player: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    var ncObject = NotificationCenter.default
    var settingGurl: SettingsHandler!
    
    var avPlayer: AVPlayer!
    var playerLayer = AVPlayerLayer()
    
    var imageToLoad: URL!
    var subreddit: Subreddit!
    var index = 0
    
    var popup: Popup!
    
    override func loadView() {
        super.loadView()
        popup = Popup()
        
        scrollView.minimumZoomScale = 1
        scrollView.delegate = self
        
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
        popup.contentView.addGestureRecognizer(tappy)
        self.view.addGestureRecognizer(tappy)
        self.player.addGestureRecognizer(tappy)
        
        maxView.addGestureRecognizer(tappy)
        maxView.addGestureRecognizer(holdy)
        maxView.addGestureRecognizer(swippyRight)
        maxView.addGestureRecognizer(swippyLeft)
		
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.setZoomScale(1.0, animated: false)
        
        ncObject.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        playerLayer.removeFromSuperlayer()
        
        if avPlayer != nil {
            avPlayer.pause()
        }
        
        self.view.addSubview(popup)
        
        
        
        if let image = subreddit[index]?.preview {
            imageToLoad = image
            postTitle.text = subreddit[index]?.title
            
            // Switches URL to load images if it is of certain types
            if let contentURL = subreddit[index]?.content, ["png","jpg","gif", "jpeg"].contains(contentURL.pathExtension), !settingGurl.get(id: "imgSwitch", setDefault: false) {
                print(contentURL.pathExtension)
                imageToLoad = contentURL
            }
                
                // Loads Video types into an AVplayer layer
			else if let contentURL = subreddit[index]?.content, ["mp4","webm","gifv"].contains(contentURL.pathExtension) {
				print(contentURL.pathExtension)
				var videoURL = contentURL
				videoURL = URL(string: videoURL.absoluteString.replacingOccurrences(of: ".webm", with: ".mp4"))!
				videoURL = URL(string: videoURL.absoluteString.replacingOccurrences(of: ".gifv", with: ".mp4"))!
				
				loadVideoToAVPlayer(videoURL: videoURL)
				return
			}
				
			// Loads .mp4 video from gfycat URL and loads into AVPlayer
			else if let contentURL = subreddit[index]?.content, contentURL.absoluteString.contains("gfycat") {
				let gfycatID = contentURL.absoluteString.components(separatedBy: "gfycat.com/")
				if gfycatID.count > 1 {
					if let videoURL = URL(string: "https://giant.gfycat.com/\(gfycatID[1]).mp4") {
						loadVideoToAVPlayer(videoURL: videoURL)
						return
					}
				}
				
			}
                
			// Gets and plays videos hosted by Reddit itself in an AVplayer layer
            else if subreddit[index]?.content != nil, (subreddit[index]?.content?.absoluteString.contains("v.redd.it"))! {
                print("You are here")
                if let secureMedia = subreddit[index]?.data["secure_media"] as? [String:Any], let redditVideo = secureMedia["reddit_video"] as? [String:Any], let videoString = redditVideo["hls_url"] as? String, let videoURL = URL(string: videoString) {
					loadVideoToAVPlayer(videoURL: videoURL)
                    return
                }
            }
			else {
				print("Nothing special about: \(subreddit[index]?.content)")
			}
		}
		else if let image = subreddit[index]?.thumbnail {
            imageToLoad = image
            postTitle.text = subreddit[index]?.title
		}
        else {
            return
        }
        
        DispatchQueue.global().async {
            do{
                let imageData = try Data(contentsOf: self.imageToLoad)
                
                if self.imageToLoad.pathExtension == "gif" {
                    let gifToLoad = UIImage.animatedImage(data: imageData)
                    DispatchQueue.main.sync {
                        self.maxView.image = gifToLoad
                        self.maxView.startAnimating()
                        self.popup.removeFromSuperview()
                    }
                }
                else {
                    DispatchQueue.main.sync {
                        self.maxView.image = UIImage(data: imageData)
                        self.popup.removeFromSuperview()
                    }
                }
            }
			catch{
				print("Image loading has failed, fallback to Preview")
				do {
					if let previewURL = self.subreddit[self.index]?.preview {
						let imageData = try Data(contentsOf: previewURL)
						DispatchQueue.main.async {
							self.maxView.image = UIImage(data: imageData)
							self.popup.removeFromSuperview()
						}
					}
				}
				catch {
					
				}
            }
        }
    }
	
	override func viewDidLayoutSubviews() {
		playerLayer.frame = player.frame
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
        imageHeight.constant = scrollView.frame.height
        popup.frame.origin = self.view.center
	}
    
	func loadVideoToAVPlayer(videoURL: URL) {
		self.maxView.image = nil
		print(videoURL)
		avPlayer = AVPlayer(url: videoURL)
		playerLayer = AVPlayerLayer(player: avPlayer)
		playerLayer.frame = self.player.frame
		
		self.view.layer.addSublayer(playerLayer)
		
		ncObject.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.avPlayer.currentItem, queue: .main, using: {(Void) in
			self.avPlayer.seek(to: kCMTimeZero)
			self.avPlayer.play()
		})
		avPlayer.play()
		self.popup.removeFromSuperview()
		return
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
    
	
    let taptic = UINotificationFeedbackGenerator()
    var isZoomedIn = true
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        taptic.prepare()
        
        if scrollView.zoomScale == scrollView.minimumZoomScale && isZoomedIn == false {
            taptic.notificationOccurred(.success)
            isZoomedIn = true
        }
        else if scrollView.zoomScale > scrollView.minimumZoomScale {
            isZoomedIn = false
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.maxView
    }
    
    @objc func dismissView() {
        ncObject.post(name: Notification.Name.init(rawValue: "isDismissed"), object: nil)
		if avPlayer != nil {
			avPlayer.pause()
		}
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
