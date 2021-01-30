//
//  RedditPost.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 13.01.2021.
//

import UIKit

class RedditPost {
    var id: String
    var name: String
    var subreddit: String
    var title: String
    var selftext: String
    var created: Date
    var numComments: Int
    var score: Int
    var author: String
    var permalink: String
    var link: String
    var saved: Bool
    var likes: Bool
    var images: [UIImage]
    
    init() {
        self.id = ""
        self.subreddit = ""
        self.title = ""
        self.author = ""
        self.selftext = ""
        self.created = Date(timeIntervalSince1970: TimeInterval(0))
        self.score = 0
        self.numComments = 0
        self.likes = false
        self.saved = false
        self.link = ""
        self.permalink = ""
        self.name = ""
        self.images = [UIImage]()
    }
}
