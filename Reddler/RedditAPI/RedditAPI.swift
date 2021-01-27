//
//  RedditAPI.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 13.01.2021.
//

import Foundation

enum URLs: String {
    case reddit = "https://www.reddit.com"
}

enum RedditEndpoint: String {
    case hot = "/hot"
    case new = "/new"
}

enum RedditAuthEndpoint: String {
    case access_token = "/api/v1/access_token"
    case authorize = "/api/v1/authorize"
}

enum ResponseType: String {
    case code = "code"
}

enum RequestType: String {
    case GET = "GET"
    case POST = "POST"
}

enum RedditApiScope: String {
    case read = "read"
}

enum RedditApiResult {
    case AuthenticationSuccess(Session)
    case RefreshTokenSuccess(String)
    case ClientError(String)
    case AuthenticationError(String)
    case ServerError(String)
    case UnknownError(String)
    case UnexpectedError(String)
}

enum AuthenticationOpType {
    case authentication
    case refreshToken
}

struct RedditAPI {
    private static let baseURL = "https://oauth.reddit.com"
    private static let baseAuthURL = "https://www.reddit.com"
    private static let oauthRedirectURL = "reddler://redirect"
    
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    /// Generate URL for passed endpoint
    /// - Parameter endpoint: reddit endpoint
    /// - Returns: endpoint URL Instance
    private static func redditUrlFor(endpoint: RedditEndpoint) -> URL? {
        guard let components = URLComponents(string: self.baseURL + endpoint.rawValue) else {
            return nil
        }
        
        print("Generated url: \(components.url?.description ?? "")")
        return components.url
    }
    
    /// Generate URL for passed endpoint
    /// - Parameter endpoint: reddit endpoint
    /// - Returns: endpoint URL Instance
    private static func redditUrlFor(endpoint: RedditAuthEndpoint) -> URL? {
        guard let components = URLComponents(string: self.baseAuthURL + endpoint.rawValue) else {
            return nil
        }
        
        print("Generated url: \(components.url?.description ?? "")")
        return components.url
    }
    
    static func generateAuthorizeUrl(clientId: String, responseType: ResponseType, state: String, scope: [RedditApiScope]) -> URL? {
        let url = URL(string: self.baseAuthURL + RedditAuthEndpoint.authorize.rawValue)!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let scopes = scope.map{"\($0.rawValue)"}.joined(separator: ",")
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "client_id", value: clientId))
        queryItems.append(URLQueryItem(name: "duration", value: "permanent"))
        queryItems.append(URLQueryItem(name: "state", value: state))
        queryItems.append(URLQueryItem(name: "response_type", value: responseType.rawValue))
        queryItems.append(URLQueryItem(name: "redirect_uri", value: self.oauthRedirectURL))
        queryItems.append(URLQueryItem(name: "scope", value: scopes))
        components.queryItems = queryItems
        return components.url
    }
    
    /// Refresh access token with refresh token
    /// - Parameter with: active session
    /// - Parameter completion: completion with access to refreshed access token
    static func refreshAccessToken(with session: Session, completion: @escaping (RedditApiResult) -> Void) {
        let authenticationString = "\(RedditConfig.clientId):"
        guard let dataString = authenticationString.data(using: .utf8) else {
            return
        }
        
        let base64AuthenticationString = (dataString.base64EncodedString())
        let basicAuthenticationString = "Basic \(base64AuthenticationString)"
        var headerParams = [String: String]()
        headerParams["Authorization"] = basicAuthenticationString
        headerParams["Content-Type"] = "application/x-www-form-urlencoded"
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "grant_type", value: "refresh_token"))
        queryItems.append(URLQueryItem(name: "refresh_token", value: session.refreshToken))
        self.commonAuthenticationProcess(operationType: .refreshToken, bodyParams: queryItems, headerParams: headerParams, completion: completion)
    }
    
    private static func commonAuthenticationProcess(operationType: AuthenticationOpType, bodyParams: [URLQueryItem], headerParams: [String: String], completion: @escaping (RedditApiResult) -> Void) {
        let url = self.redditUrlFor(endpoint: .access_token)!
        self.commonRequestProcessing(requestType: .POST, url: url, bodyParams: bodyParams, urlParams: [], headerParams: headerParams) {
            (data, response, error) in
            
            let httpResponse = response as! HTTPURLResponse
            switch httpResponse.statusCode {
            case 200...299:
                guard let jsonDict = self.jsonDataEncoder(jsonData: data) else {
                    completion(.UnexpectedError("Bad response."))
                    return
                }
                
                if let bodyError = self.checkBodyError(dict: jsonDict) {
                    let errorMsg = "Unexpected response body: \(bodyError)"
                    completion(.UnexpectedError(errorMsg))
                    return
                }
                
                print("All data from response: \(jsonDict.description)")
                switch operationType {
                case .authentication:
                    guard let session = self.sessionJSONEncoder(jsonDict: jsonDict) else {
                        completion(.AuthenticationError("Empty response data."))
                        return
                    }
                    
                    completion(.AuthenticationSuccess(session))
                case .refreshToken:
                    guard let refreshedAccessToken = jsonDict["access_token"] as? String else {
                        completion(.AuthenticationError("Empty respinse data."))
                        return
                    }
                    
                    completion(.RefreshTokenSuccess(refreshedAccessToken))
                }
                
                print("Done!")
            case 400...499:
                let errorMsg = "Client error: \(httpResponse.statusCode)"
                completion(.ClientError(errorMsg))
            case 500...511:
                let errorMsg = "Server error: \(httpResponse.statusCode)"
                print("\(#function): \(errorMsg)")
                completion(.ServerError(errorMsg))
            default:
                let errorMsg = "Unknown error: \(httpResponse.statusCode)"
                completion(.UnknownError(errorMsg))
            }
        }
    }
    
    static func authenticationProcess(clientId: String, code: String, completion: @escaping (RedditApiResult) -> Void) {
        var headerParams = [String: String]()
        let authenticationString = "\(clientId):"
        guard let dataString = authenticationString.data(using: .utf8) else {
            return
        }
        
        let base64AuthenticationString = (dataString.base64EncodedString())
        let basicAuthenticationString = "Basic \(base64AuthenticationString)"
        headerParams["Authorization"] = basicAuthenticationString
        headerParams["Content-Type"] = "application/x-www-form-urlencoded"
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "grant_type", value: "authorization_code"))
        queryItems.append(URLQueryItem(name: "code", value: code))
        queryItems.append(URLQueryItem(name: "redirect_uri", value: self.oauthRedirectURL))
        self.commonAuthenticationProcess(operationType: .authentication, bodyParams: queryItems, headerParams: headerParams, completion: completion)
    }
    
    private static func commonRequestProcessing(requestType: RequestType, url: URL, bodyParams: [URLQueryItem], urlParams: [URLQueryItem], headerParams: [String: String], dataTask: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: url)
        headerParams.forEach{request.addValue($0.value, forHTTPHeaderField: $0.key)}
        var bodyContent = URLComponents(string: "")!
        bodyContent.queryItems = bodyParams
        var bodyString = bodyContent.string!
        
        // Remove leading "?" symbol from string
        bodyString.remove(at: bodyString.startIndex)
        guard let bodyData = bodyString.data(using: .utf8) else {
            return
        }
        
        request.httpBody = bodyData
        request.httpMethod = requestType.rawValue
        
        let task = self.session.dataTask(with: request) {
            (data, response, error) in
            
            dataTask(data, response, error)
        }
        
        task.resume()
    }
    
    private static func jsonDataEncoder(jsonData: Data?) -> [String:AnyObject]? {
        guard let data = jsonData else {
            print("JSON Data is empty!")
            return nil
        }
        
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
        else {
            print("Invalid JSON Data")
            return nil
        }
        
        return jsonDict
    }
    
    private static func sessionJSONEncoder(jsonDict: [String:AnyObject]?) -> Session? {
        guard let json = jsonDict,
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String
        else {
            print("\(#function): parse session failed!")
            return nil
        }
        
        let session = Session(accessToken: accessToken, refreshToken: refreshToken
        )
        
        return session
    }
    
    private static func checkBodyError(dict: [String:AnyObject]) -> String? {
        guard let error = dict["error"] as? String else {
            return nil
        }
        
        return error
    }
}
