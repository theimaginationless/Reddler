//
//  PostTableViewController.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 13.01.2021.
//

import UIKit

class PostTableViewController: UITableViewController {
    var session: Session!
    var postDataSource = PostTableViewDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self.postDataSource
        self.tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        RedditAPI.fetchPost(limit: 10, category: .hot) {
            (result) in
            
            DispatchQueue.main.async {
                switch result {
                case let .PostFetchSuccess(posts):
                    self.postDataSource.posts = posts
                    self.tableView.reloadData()
                default:
                    print("\(#function): Nothing!")
                }
            }
        }
    }
}
