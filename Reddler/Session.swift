//
//  Session.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 20.01.2021.
//

import Foundation

class Session {
    var accessToken: String
    var refreshToken: String
    var account: String {
        get {
            RedditConfig.account
        }
    }
    
    required init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
