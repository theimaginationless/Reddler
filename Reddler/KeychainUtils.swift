//
//  KeychainUtils.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 21.01.2021.
//

import Foundation

enum KeychainError: Error {
    case preparingCredentialsError
    case unhandledError(status: OSStatus)
}

struct KeychainUtils {
    public static func saveCredential(for session: Session) throws {
        guard let account = session.account,
              let accessToken = session.accessToken,
              let refreshToken = session.refreshToken
        else {
            print("Cannot save non-completed session for username: \"\(session.account ?? "")\"")
            throw KeychainError.preparingCredentialsError
        }
        
        let credentialDict: [String:String] = ["accessToken": accessToken,
                                               "refreshToken": refreshToken]
        
        guard let credentialsData = try? JSONSerialization.data(withJSONObject: credentialDict, options: []) else {
            print("Error while encoding credentials to data")
            throw KeychainError.preparingCredentialsError
        }
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecValueData as String: credentialsData]
        
        let error = SecItemAdd(query as CFDictionary, nil)
        
        guard error == errSecSuccess else {
            print("Cannot add security item with error: \(error)")
            throw KeychainError.unhandledError(status: error)
        }
    }
}
