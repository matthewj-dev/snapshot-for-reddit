//
//  color.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/24/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

extension UIColor {
	
	enum appleColors {
		case iOSBlue
		case iOSOrange
		case iOSRed
		case iOSGreen
	}
	
	convenience init(iOSColor: appleColors) {
		switch iOSColor {
		case .iOSBlue:
			self.init(red: 0, green: 122/255, blue: 1, alpha: 1.0)
		
		case .iOSOrange:
			self.init(red: 1, green: 149/255, blue: 0, alpha: 1.0)
			
		case .iOSRed:
			self.init(red: 1, green: 59/255, blue: 48/255, alpha: 1.0)
			
		case .iOSGreen:
			self.init(red: 76/255, green: 217/255, blue: 100/255, alpha: 1.0)
		}
	}
	
}

