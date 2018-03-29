//
//  SettingsTableViewController.swift
//  snapshot
//
//  Created by Matthew Jackson on 3/28/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, DarkMode {
    
    
    
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var darkModeSlider: UISlider!
    @IBOutlet weak var imgQualitySwitch: UISwitch!
    
    var settingsBoi: SettingsHandler!
    
    var darkModeEnabled: Bool = false
    
    func darkMode(isOn: Bool) {
        
    }
    
    
    override func loadView() {
        super.loadView()
        if let tabBar = self.tabBarController as? TabBarControl {
            settingsBoi = tabBar.settings
        }
        else {
            settingsBoi = SettingsHandler()
        }
        darkModeSwitch.isOn = settingsBoi.get(id: "darkSwitch", setDefault: false)
        darkModeSlider.value = settingsBoi.get(id: "darkSlider", setDefault: 0.5)
        imgQualitySwitch.isOn = settingsBoi.get(id: "imgSwitch", setDefault: false)
        
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
