//
//  Settings Handler.swift
//  Night Stand
//
//  Created by Hunter Forbus on 1/23/18.
//  Copyright © 2018 Hunter Forbus. All rights reserved.
//

import Foundation

/**
 Handles moving in settings from UserDefaults and can handle setting defaults
 */
class SettingsHandler {
    private var settings = UserDefaults.standard
    
    /**
     Returns the value set in the ID. If the value is nil, then the default is placed into the slot
     for the ID
     - Parameter id: String value to be used as the key
     - Parameter setDefault: Default value to be set when the key is nil
     
     - Returns: Value of stored value from key
     */
    func get<T>(id: String, setDefault: T) -> T {
        if (settings.object(forKey: id) == nil || settings.object(forKey: id) as? T == nil){
            settings.set(setDefault, forKey: id)
        }
        settings.synchronize()
        return settings.object(forKey: id) as! T
    }
    
    /**
     Returns optional value set in the ID
     - Parameter id: String value to be used as the key
     - Parameter type: Object type to retrieve as object
     
     - Returns: Optional value of value stored in key
     */
    func get<T>(id:String, type:T.Type) -> T? {
        return settings.object(forKey: id) as? T
    }
    
    /**
     Sets object into passed key
     - Parameter id: String value to be used as the key
     - Parameter object: Object to be stored into key
     - throws: NotSettable
     */
    func set<T>(id: String, object: T) throws {
        if (object as? NSObject != nil){
            settings.set(object, forKey: id)
            settings.synchronize()
        }
        else {
            let typeOf = type(of: object)
            throw settingsError.NotSettable("\(typeOf) is not settable")
        }
        
    }
    
    enum settingsError:Error {
        case NotSettable(String)
    }
    
}
