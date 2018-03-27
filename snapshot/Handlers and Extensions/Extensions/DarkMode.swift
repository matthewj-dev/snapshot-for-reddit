//
//  DarkMode.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/24/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

protocol DarkMode {
	
	var darkModeEnabled: Bool {get set}
	
	/**
	Function used to toggle darkmode on UI elements
	- Parameter isOn: Variable used to tell whether the dark mode UI should be on
	*/
	func darkMode(isOn: Bool)
}
