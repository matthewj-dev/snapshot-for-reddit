//
//  SettingsTableViewController.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/28/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, DarkMode {

	@IBOutlet var table: UITableView!
	
	@IBOutlet var labels: [UILabel]!
	@IBOutlet var tableCells: [UITableViewCell]!
	
	
	@IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var darkModeSlider: UISlider!
    @IBOutlet weak var imgQualitySwitch: UISwitch!
    
    var settingsBoi: SettingsHandler!
    
    var darkModeEnabled: Bool = true
    
    func darkMode(isOn: Bool) {
        self.darkModeEnabled = isOn
		
		if darkModeEnabled {
			if table != nil {
				table.backgroundView?.backgroundColor = .black
				table.backgroundColor = .black
				darkModeSwitch.onTintColor = UIColor(iOSColor: .iOSOrange)
				imgQualitySwitch.onTintColor = UIColor(iOSColor: .iOSOrange)
				darkModeSlider.minimumValueImage = #imageLiteral(resourceName: "Moon Dark Mode")
				darkModeSlider.maximumValueImage = #imageLiteral(resourceName: "Sun Night Mode")
				for i in tableCells {
					i.backgroundColor = .black
				}
				for i in labels {
					i.textColor = .white
				}
			}
			return
		}
		if table != nil {
			table.backgroundView?.backgroundColor = UIColor.groupTableViewBackground
			table.backgroundColor = UIColor.groupTableViewBackground
			darkModeSwitch.onTintColor = UIColor(iOSColor: .iOSGreen)
			imgQualitySwitch.onTintColor = UIColor(iOSColor: .iOSGreen)
			darkModeSlider.minimumValueImage = #imageLiteral(resourceName: "Moon Day Mode")
			darkModeSlider.maximumValueImage = #imageLiteral(resourceName: "Sun Day Mode")
			for i in tableCells {
				i.backgroundColor = .white
			}
			for i in labels {
				i.textColor = .black
			}
		}
    }
	
    override func loadView() {
        super.loadView()
        if let tabBar = self.tabBarController as? TabBarControl {
            settingsBoi = tabBar.settings
			self.darkModeEnabled = tabBar.darkModeEnabled
        }
        else {
            settingsBoi = SettingsHandler()
        }
        darkModeSwitch.isOn = settingsBoi.get(id: "darkSwitch", setDefault: false)
        darkModeSlider.value = settingsBoi.get(id: "darkSlider", setDefault: 0.5)
        imgQualitySwitch.isOn = settingsBoi.get(id: "imgSwitch", setDefault: false)
		self.navigationItem.title = "Settings"
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print(darkModeEnabled)
		darkMode(isOn: darkModeEnabled)
	}
	
    @IBAction func DarkModeSliderChange(_ sender: Any) {
        do {
            try settingsBoi.set(id: "darkSlider", object: darkModeSlider.value)
            if let tabBar = self.tabBarController as? TabBarControl {
                tabBar.brightnessChanged()
            }
        } catch {
            print("Oh no not the dark mode slider!")
        }
    }
    
    
    @IBAction func DarkModeSwitch(_ sender: Any) {
        do {
            try settingsBoi.set(id: "darkSwitch", object: darkModeSwitch.isOn)
            if let tabBar = self.tabBarController as? TabBarControl {
                tabBar.brightnessChanged()
            }
        } catch {
            print("Oh no not the dark mode switch!")
        }
    }
    
    @IBAction func CrappySignalSwitch(_ sender: Any) {
        do {
            try settingsBoi.set(id: "imgSwitch", object: imgQualitySwitch.isOn)
        } catch {
            print("Oh no not the shitty image slider!")
        }
    }
    
}
