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
    case unexpectedCredentialsData
    case emptyCredentialsData
    case credentialsNotFound
}

struct KeychainUtils {
    static let accessTokenField = "accessToken"
    static let refreshTokenField = "refreshToken"
    
    public static func saveCredentials(for session: Session) throws {
        let account = session.account
        let accessToken = session.accessToken
        let refreshToken = session.refreshToken
        let credentialsDict: [String: String] = [self.accessTokenField: accessToken,
                                                 self.refreshTokenField: refreshToken]
        
        guard let credentialsData = try? JSONSerialization.data(withJSONObject: credentialsDict, options: []) else {
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
    
    public static func loadCredentials(for account: String) throws -> Session {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                      kSecAttrAccount as String: account,
                                      kSecMatchLimit as String: kSecMatchLimitOne,
                                      kSecReturnAttributes as String: true,
                                      kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            print("\(#function): Error: \(KeychainError.credentialsNotFound)")
            throw KeychainError.credentialsNotFound
        }
        
        guard status == errSecSuccess else {
            print("\(#function): Error: \(KeychainError.unhandledError(status: status))")
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let credentialsItem = item as? [String: Any],
              let credentialsData = credentialsItem[kSecValueData as String] as? Data,
              let credentialsDict = try? JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: String]
        else {
            print("\(#function): Error: \(KeychainError.unexpectedCredentialsData)")
            throw KeychainError.unexpectedCredentialsData
        }
        
        guard let accessToken = credentialsDict[self.accessTokenField],
              let refreshToken = credentialsDict[self.refreshTokenField]
        else {
            print("\(#function): Error: \(KeychainError.emptyCredentialsData)")
            throw KeychainError.emptyCredentialsData
        }
        
        let session = Session(accessToken: accessToken, refreshToken: refreshToken)
        
        return session
    }
    
    public static func removeCredentials(for session: Session) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
