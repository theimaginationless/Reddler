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
    case hot = "hot"
    case new = "new"
}

enum ResponseType: String {
    case json = ".json"
}

enum RedditAuthEndpoint: String {
    case access_token = "/api/v1/access_token"
    case authorize = "/api/v1/authorize"
}

enum AuthResponseType: String {
    case code = "code"
}

enum RequestType: String {
    case GET = "GET"
    case POST = "POST"
}

enum RedditApiScope: String {
    case read = "read"
    case account = "account"
    case identity = "identity"
}

enum RedditApiResult {
    case PostFetchSuccess([RedditPost])
    case UserFetchSuccess
    case FetchFailed(String)
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
    private static let baseOAuthURL = "https://oauth.reddit.com"
    private static let baseAuthURL = "https://www.reddit.com"
    private static let baseURL = "https://www.reddit.com"
    private static let oauthRedirectURL = "reddler://redirect"
    
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    /// Generate URL for passed endpoint
    /// - Parameter endpoint: reddit endpoint
    /// - Returns: endpoint URL Instance
    private static func redditUrlFor(subreddit: String? = nil, endpoint: RedditEndpoint, urlParams: [String: String]) -> URL? {
        var url = URL(string: self.baseOAuthURL)!
        if let subredditString = subreddit {
            url.appendPathComponent("r/\(subredditString)")
        }
        
        url.appendPathComponent(endpoint.rawValue)
        url.appendPathComponent(ResponseType.json.rawValue)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems = urlParams.map{param in URLQueryItem(name: param.key, value: param.value)}
        components.queryItems = queryItems
        
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
    
    static func generateAuthorizeUrl(clientId: String, responseType: AuthResponseType, state: String, scope: [RedditApiScope]) -> URL? {
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
    
    
    static func fetchPosts(subreddit: String? = nil, after: String? = nil, limit: Int, category: RedditEndpoint, session: Session, completion: @escaping (RedditApiResult) -> Void) {
        var params = ["limit": "\(limit)"]
        if let afterString = after {
            params["after"] = afterString
        }
        
        let url = self.redditUrlFor(subreddit: subreddit, endpoint: category, urlParams: params)!
        
        guard let headerParams = self.generateAuthorizationHeaderParams(with: session, withContent: false) else {
            return
        }
        
        self.commonRequestProcessing(requestType: .GET, url: url, bodyParams: [], headerParams: headerParams) {
            (data, response, error) in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.UnexpectedError("Something wrong with network!"))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard let jsonDict = self.jsonDataDecoder(jsonData: data) else {
                    return
                }
                
                guard let posts = self.parseJsonResponseToPosts(jsonDict: jsonDict) else {
                    return
                }
                
                print("Done! \(posts)")
                completion(.PostFetchSuccess(posts))
            case 401:
                fallthrough
            case 403:
                self.refreshAccessToken(with: session) {
                    (result) in
                    
                    switch result {
                    case let .RefreshTokenSuccess(newAccessToken):
                        session.accessToken = newAccessToken
                        try! KeychainUtils.updateCredentials(for: session)
                        print("Updated session: accessToken: \(session.accessToken)")
                        self.fetchPosts(subreddit: subreddit, after: after, limit: limit, category: category, session: session, completion: completion)
                    default:
                        completion(.AuthenticationError("Access denied! ErrNo: \(httpResponse.statusCode)"))
                    }
                }
            default:
                let errMsg = "ErrCode: \(httpResponse.statusCode)"
                print(errMsg)
                completion(.FetchFailed(errMsg))
            }
        }
    }
    
    private static func generateAuthorizationHeaderParams(with session: Session? = nil, withContent: Bool) -> [String: String]? {
        var basicAuthenticationString = ""
        if let activeSession = session {
            basicAuthenticationString = "bearer \(activeSession.accessToken)"
        }
        else {
            let authenticationString = "\(RedditConfig.clientId):"
            guard let dataString = authenticationString.data(using: .utf8) else {
                return nil
            }
            
            let base64AuthenticationString = (dataString.base64EncodedString())
            basicAuthenticationString = "Basic \(base64AuthenticationString)"
        }
        
        var headerParams = [String: String]()
        headerParams["Authorization"] = basicAuthenticationString
        if withContent {
            headerParams["Content-Type"] = "application/x-www-form-urlencoded"
        }
        
        return headerParams
    }
    
    /// Refresh access token with refresh token
    /// - Parameter with: active session
    /// - Parameter completion: completion with access to refreshed access token
    static func refreshAccessToken(with session: Session, completion: @escaping (RedditApiResult) -> Void) {
        guard let headerParams = self.generateAuthorizationHeaderParams(withContent: true) else {
            return
        }
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "grant_type", value: "refresh_token"))
        queryItems.append(URLQueryItem(name: "refresh_token", value: session.refreshToken))
        self.commonAuthenticationProcess(operationType: .refreshToken, bodyParams: queryItems, headerParams: headerParams, completion: completion)
    }
    
    private static func commonAuthenticationProcess(operationType: AuthenticationOpType, bodyParams: [URLQueryItem], headerParams: [String: String], completion: @escaping (RedditApiResult) -> Void) {
        let url = self.redditUrlFor(endpoint: .access_token)!
        self.commonRequestProcessing(requestType: .POST, url: url, bodyParams: bodyParams, headerParams: headerParams) {
            (data, response, error) in
            
            let httpResponse = response as! HTTPURLResponse
            switch httpResponse.statusCode {
            case 200...299:
                guard let jsonDict = self.jsonDataDecoder(jsonData: data) else {
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
                    guard let session = self.jsonToSession(jsonDict: jsonDict) else {
                        completion(.AuthenticationError("Empty response data."))
                        return
                    }
                    
                    completion(.AuthenticationSuccess(session))
                case .refreshToken:
                    guard let refreshedAccessToken = jsonDict["access_token"] as? String else {
                        completion(.AuthenticationError("Empty response data."))
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
    
    private static func commonRequestProcessing(requestType: RequestType, url: URL, bodyParams: [URLQueryItem], headerParams: [String: String], dataTask: @escaping (Data?, URLResponse?, Error?) -> Void) {
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
    
    private static func jsonDataDecoder(jsonData: Data?) -> [String:AnyObject]? {
        guard let data = jsonData else {
            print("JSON Data is empty!")
            return nil
        }
        
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
        else {
            print("\(#function): parse JSON failed!")
            return nil
        }
        
        return jsonDict
    }
    
    private static func parseJsonResponseToPosts(jsonDict: [String:AnyObject]?) -> [RedditPost]? {
        guard let json = jsonDict,
              let dataContent = json["data"] as? [String:AnyObject],
              let childrenContent = dataContent["children"] as? [[String:AnyObject]]
        else {
            print("\(#function): parse session failed!")
            return nil
        }
        
        let posts = childrenContent.compactMap{self.jsonToPost(jsonDict: $0)}
        
        return posts
    }
    
    private static func jsonToPost(jsonDict: [String:AnyObject]?) -> RedditPost? {
        print("Is: \(jsonDict!)")
        guard let jsonPost = jsonDict,
              let jsonPostData = jsonPost["data"] as? [String:AnyObject],
              let subreddit = jsonPostData["subreddit"] as? String,
              let selftext = jsonPostData["selftext"] as? String,
              let title = jsonPostData["title"] as? String,
              let createdTS = jsonPostData["created"] as? Double,
              let id = jsonPostData["id"] as? String,
              let score = jsonPostData["score"] as? Int,
              let permalink = jsonPostData["permalink"] as? String,
              let numComments = jsonPostData["num_comments"] as? Int,
              let author = jsonPostData["author"] as? String,
              let name = jsonPostData["name"] as? String
        else {
            print("\(#function): parse post JSON failed!")
            return nil
        }
        
        let createdTI = TimeInterval(createdTS)
        let created = Date(timeIntervalSince1970: createdTI)
        let likes = (jsonPostData["likes"] as? Bool) ?? false
        let saved = (jsonPostData["saved"] as? Bool) ?? false
        let post = RedditPost()
        post.author = author
        post.name = name
        post.created = created
        post.id = id
        post.likes = likes
        post.permalink = permalink
        post.numComments = numComments
        post.score = score
        post.saved = saved
        post.selftext = selftext
        post.subreddit = subreddit
        post.title = title
        
        return post
    }
    
    private static func jsonToSession(jsonDict: [String:AnyObject]?) -> Session? {
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
