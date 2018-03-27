//
//  Popup.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/21/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class Popup: UIView {
	
	var contentView: UIView!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		prepareView()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func prepareView() {
		// Creates a nib from the xib file of the same name
		let nib = UINib(nibName: "PopupView", bundle: Bundle.main)
		self.contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView
		
		// Set locations and layout of items within the view
		self.contentView.center = self.center
		self.contentView.autoresizingMask = []
		self.contentView.translatesAutoresizingMaskIntoConstraints = true
		
		self.contentView.layer.masksToBounds = true
		self.contentView.clipsToBounds = true
		
		// Rounds the corner of the view
		self.contentView.layer.cornerRadius = 10
		
		addSubview(self.contentView)
		self.frame = self.contentView.frame
	}
	
}
