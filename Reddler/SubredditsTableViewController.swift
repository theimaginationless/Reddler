//
//  SubredditsTableViewController.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 03.02.2021.
//

import UIKit

protocol SwitchSubredditDelegate {
    func switchSubreddit(to subreddit: Subreddit)
}

class SubredditsTableViewController: UITableViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    var switchSubredditDelegate: SwitchSubredditDelegate?
    var session: Session!
    var subredditDataSource: SubredditTableViewDataSource?
    var lastTriggeredIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.placeholder = NSLocalizedString("Search subreddit", comment: "Placeholder for subreddit searching field")
        self.tableView.dataSource = self.subredditDataSource
        self.tableView.delegate = self
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let triggeredIndex = self.subredditDataSource!.subreddits!.count - 1
        guard triggeredIndex > self.lastTriggeredIndex else {
            return
        }
        
        if triggeredIndex == indexPath.row {
            self.lastTriggeredIndex = triggeredIndex
            self.loadMore(tableView: tableView, indexPath: indexPath, limit: 20, session: self.session)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SubredditTableViewCell
        guard let subreddit = self.subredditDataSource?.subreddits?.first(where: {$0.name == cell.name}) else {
            return
        }
        
        self.dismiss(animated: true) {
            self.switchSubredditDelegate?.switchSubreddit(to: subreddit)
        }
    }
    
    func loadMore(tableView: UITableView, indexPath: IndexPath, limit: Int, session: Session) {
        let lastSubreddit = self.subredditDataSource!.subreddits!.last!
        RedditAPI.fetchSubreddits(after: lastSubreddit.name, limit: limit, session: session) {
            (result) in

            DispatchQueue.main.async {
                switch result {
                case let .SubredditsFetchSuccess(subreddits):
                    var lastIndex = self.subredditDataSource!.subreddits!.count - 1
                    self.subredditDataSource!.subreddits!.append(contentsOf: subreddits)
                    let newIndexPaths = subreddits.map{
                        post -> IndexPath in
                        
                        lastIndex += 1
                        let newIndexPath = IndexPath(row: lastIndex, section: indexPath.section)
                        return newIndexPath
                    }
                    
                    UIView.performWithoutAnimation {
                        tableView.insertRows(at: newIndexPaths, with: .none)
                    }
                default:
                    print("\(#function): Nothing!")
                }
            }
        }
    }
}
