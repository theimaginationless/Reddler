//
//  SubredditTableViewDataSource.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 04.02.2021.
//

import UIKit

class SubredditTableViewDataSource: NSObject, UITableViewDataSource {
    var subreddits: [Subreddit]?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.subreddits?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "SubredditTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! SubredditTableViewCell
        let subreddit = self.subreddits![indexPath.row]
        cell.titleLabel.text = subreddit.title
        cell.descriptionLabel.text = subreddit.desc
        cell.isFavorite = subreddit.isFavorite
        cell.name = subreddit.name
        return cell
    }
}
