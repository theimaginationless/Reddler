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
    static let dateField = "date"
    static let expiresInField = "expiresIn"
    static let tokenTypeField = "tokenType"
    
    public static func saveCredentials(for session: Session) throws {
        let query = self.prepareQuery(for: session)
        let error = SecItemAdd(query as CFDictionary, nil)
        
        guard error == errSecSuccess else {
            print("Cannot add security item with error: \(error)")
            throw KeychainError.unhandledError(status: error)
        }
    }
    
    public static func updateCredentials(for session: Session) throws {
        let query = self.prepareQuery(for: session)
        let newValue = query[kSecValueData as String] as! Data
        let attributes: [String: Any] = [kSecValueData as String: newValue]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.credentialsNotFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
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
              let credentialsDict = try? JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: Any]
        else {
            print("\(#function): Error: \(KeychainError.unexpectedCredentialsData)")
            throw KeychainError.unexpectedCredentialsData
        }
        
        guard let accessToken = credentialsDict[self.accessTokenField] as? String,
              let refreshToken = credentialsDict[self.refreshTokenField] as? String,
              let date = credentialsDict[self.dateField] as? TimeInterval,
              let expiresIn = credentialsDict[self.expiresInField] as? Int,
              let tokenType = credentialsDict[self.tokenTypeField] as? String
        else {
            print("\(#function): Error: \(KeychainError.emptyCredentialsData)")
            throw KeychainError.emptyCredentialsData
        }
        
        let session = Session(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn, tokenType: tokenType)
        session.token.date = Date(timeIntervalSince1970: date)
        
        return session
    }
    
    private static func prepareQuery(for session: Session) -> [String: Any] {
        let account = session.account
        let accessToken = session.token.accessToken
        let refreshToken = session.token.refreshToken
        let date = session.token.date
        let expiresIn = session.token.expiresIn
        let tokenType = session.token.tokenType
        let credentialsDict: [String: Any] = [self.accessTokenField: accessToken,
                                                 self.refreshTokenField: refreshToken,
                                                 self.dateField: date.timeIntervalSince1970,
                                                 self.expiresInField: expiresIn,
                                                 self.tokenTypeField: tokenType]
        let credentialsData = try! JSONSerialization.data(withJSONObject: credentialsDict, options: [])
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecValueData as String: credentialsData]
        
        return query
    }
    
    public static func removeCredentials(for session: Session) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
