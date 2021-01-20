//
//  Session.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 20.01.2021.
//

import Foundation

struct Session {
    static var code: String? {
        get {
            UserDefaults.standard.string(forKey: "code")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "code")
        }
    }
}
