//
//  RedditPost.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 13.01.2021.
//

import UIKit

class RedditPost {
    var id = ""
    var name = ""
    var subreddit = ""
    var title = ""
    var selftext = ""
    var created = Date(timeIntervalSince1970: TimeInterval(0))
    var numComments = 0
    var score = 0
    var author = ""
    var permalink = ""
    var link = ""
    var saved = false
    var likes = false
    var images = [UIImage]()
}
