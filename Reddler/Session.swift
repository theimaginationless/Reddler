//
//  Session.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 20.01.2021.
//

import Foundation

struct Token {
    let date = Date()
    let accessToken: String
    let refreshToken: String
    var expiresIn: Int
    var tokenType: String
    
    var isValid: Bool {
        let now = Date()
        let sec = TimeInterval(self.expiresIn)
        return now.timeIntervalSince(self.date) < sec
    }
}

class Session {
    var accessToken: String
    var refreshToken: String
    var account: String {
        get {
            RedditConfig.account
        }
    }
    
    required init(accessToken: String, refreshToken: String) {
        //self.token = Token(accessToken: accessToken, refreshToken: refreshToken, expiresIn: <#T##Int#>, tokenType: <#T##String#>)
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
