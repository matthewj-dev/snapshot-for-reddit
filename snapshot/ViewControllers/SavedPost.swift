//
//  SavedPost.swift
//  snapshot
//
//  Created by Hunter Forbus on 4/5/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class SavedPost: UITableViewCell {
	
	@IBOutlet weak var postTitle: UILabel!
	@IBOutlet weak var postThumb: UIImageView!
	
	override func prepareForReuse() {
		super.prepareForReuse()
		postThumb.image = nil
		self.backgroundColor = .white
		self.postTitle.textColor = .black
	}
}
