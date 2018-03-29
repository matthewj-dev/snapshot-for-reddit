//
//  MoreInfoView.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/28/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class MoreInfoView: UIView {

	@IBOutlet weak var urlLabel: UILabel!
	@IBOutlet weak var typeLabel: UILabel!
	@IBOutlet weak var subredditLabel: UILabel!
	
	var contentView: UIView!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupView()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func setupView() {
		let nib = UINib(nibName: "MoreInfoView", bundle: Bundle.main)
		self.contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView
		
		self.contentView.frame = self.frame
		self.contentView.center = self.center
		self.contentView.translatesAutoresizingMaskIntoConstraints = true
		self.contentView.layer.masksToBounds = true
		self.contentView.clipsToBounds = true
		
		addSubview(self.contentView)
	}
	
}
