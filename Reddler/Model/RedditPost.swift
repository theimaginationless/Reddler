//
//  RedditPost.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 13.01.2021.
//

import Foundation

class RedditPost {
    var id: String!
    var subreddit: String!
    var title: String!
    var selftext: String!
    var created: Date!
    var numComments: Int!
    var score: Int!
    var author: String!
    var permalink: String!
    var link: String!
    var saved: Bool!
    var likes: Bool!
}
