//
//  Subreddit.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 04.02.2021.
//

import UIKit

class Subreddit {
    var title = ""
    var name = ""
    var displayName = ""
    var displayNamePrefixed = ""
    var subscribers = 0
    var desc = ""
    var isSubscriber = false
    var isFavorite = false
    var permalink = ""
    lazy var url: URL = {
        var fullUrl = URL(string: RedditConfig.baseURL)!
        fullUrl.appendPathComponent(self.permalink)
        return fullUrl
    }()
}
