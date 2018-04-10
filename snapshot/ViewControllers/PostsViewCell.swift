//
//  PostsViewCell.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/12/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class PostsViewCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var postTitle: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnail.image = nil
		thumbnail.layer.cornerRadius = 10
		thumbnail.clipsToBounds = true
    }
}
