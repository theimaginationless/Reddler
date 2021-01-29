//
//  PostTableVIewDataSource.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 28.01.2021.
//

import UIKit

class PostTableViewDataSource: NSObject, UITableViewDataSource {
    var posts: [RedditPost]?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "PostTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! PostTableViewCell
        let post = self.posts![indexPath.row]
        cell.authorLabel.text = post.author
        cell.titleLabel.text = post.title
        cell.contentTextView.text = post.selftext
        cell.numCommentsLabel.text = "\(post.numComments)"
        cell.scoreLabel.text = "\(post.score)"
        cell.subredditLabel.text = "r/\(post.subreddit)"
        if post.images.count == 0 {
            cell.imageCollectionViewHeightConstant.constant = 0
        }
        
        cell.titleLabel.numberOfLines = 0
        cell.titleLabel.sizeToFit()
        return cell
    }
}
