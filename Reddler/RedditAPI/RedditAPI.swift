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
    case AuthenticationSuccess(String)
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
    
    static func authrization(clientId: String, code: String, completion: @escaping (RedditApiResult) -> Void?) {
        var request = URLRequest(url: self.redditUrlFor(endpoint: .access_token)!)
        let authenticationString = "\(clientId):"
        guard let dataString = authenticationString.data(using: .utf8) else {
            return
        }
        
        let base64AuthenticationString = (dataString.base64EncodedString())
        print(base64AuthenticationString)
        let basicAuthenticationString = "Basic \(base64AuthenticationString)"
        request.addValue(basicAuthenticationString, forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let bodyString = "grant_type=authorization_code&code=\(code)&redirect_uri=\(self.oauthRedirectURL)"
        guard let bodyData = bodyString.data(using: .utf8) else {
            return
        }
        
        request.httpBody = bodyData
        request.httpMethod = RequestType.POST.rawValue
        
        let task = self.session.dataTask(with: request) {
            (data, response, error) in
            
            let httpResponse = response as! HTTPURLResponse
            switch httpResponse.statusCode {
            case 200...299:
                let json = try! JSONSerialization.jsonObject(with: data!, options: [])
                let jsonDict = json as! [String:AnyObject]
                let token = jsonDict["access_token"] as? String ?? ""
                print("All data from response: \(jsonDict.description)")
                completion(.AuthenticationSuccess(token))
                print("Done!")
            default:
                print("Nothing: \(httpResponse.statusCode)")
            }
        }
        
        task.resume()
    }
}
