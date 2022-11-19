//
//  Session.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 20.01.2021.
//

import Foundation

struct Token {
    var date = Date()
    var accessToken: String
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
    var token: Token
    var account: String {
        get {
            RedditConfig.account
        }
    }
    
    required init(accessToken: String, refreshToken: String, expiresIn: Int, tokenType: String) {
        self.token = Token(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn, tokenType: tokenType)
    }
    
    func refreshToken(completionHandler: @escaping () -> Void) {
        DispatchQueue.global().async {
            RedditAPI.refreshAccessToken(with: self) {
                (result) in
                
                switch result {
                case .RefreshTokenSuccess(let newAccessToken, let expiresIn):
                    self.token = Token(accessToken: newAccessToken, refreshToken: self.token.refreshToken, expiresIn: expiresIn, tokenType: self.token.tokenType)
                    print("Refreshed: \(self.token.accessToken)")
                    try! KeychainUtils.updateCredentials(for: self)
                default:
                    print("Nothing!")
                }
                
                completionHandler()
            }
        }
    }
}
