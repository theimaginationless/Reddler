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
    var lastTriggeredIndex = 0
    var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self.postDataSource
        self.tableView.delegate = self
        self.navigationBar = self.navigationController!.navigationBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let rootView = UIApplication.shared.windows.first!
        let processingIndicatorTag = 1
        OperationQueue.main.addOperation {
            self.addActivityIndicator(at: rootView, tag: processingIndicatorTag)
        }
        
        RedditAPI.fetchPosts(limit: 20, category: .hot, session: self.session) {
            (result) in
            
            OperationQueue.main.addOperation {
                switch result {
                case let .PostFetchSuccess(posts):
                    self.postDataSource.posts = posts
                    self.tableView.reloadData()
                default:
                    print("\(#function): Nothing!")
                }
                
                let processingIndicator = rootView.viewWithTag(processingIndicatorTag) as? ProcessingIndicator
                UIView.animate(withDuration: 0.5, animations: {processingIndicator?.alpha = 0.0})  {
                    finished in
                    processingIndicator?.stopAnimating()
                    processingIndicator?.removeFromSuperview()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let triggeredIndex = self.postDataSource.posts!.count - 1
        guard triggeredIndex > self.lastTriggeredIndex else {
            return
        }
        
        if triggeredIndex == indexPath.row {
            self.lastTriggeredIndex = triggeredIndex
            self.loadMore(tableView: tableView, indexPath: indexPath, limit: 20, category: .hot, session: self.session)
        }
    }
    
    func addActivityIndicator(at rootView: UIView, tag: Int) {
        let rootFrame = rootView.frame
        let processIndicator = ProcessingIndicator(frame: rootFrame)
        processIndicator.tag = tag
        processIndicator.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(processIndicator)
        processIndicator.center = rootView.center
        processIndicator.startAnimating()
    }
    
    func removeActivityIndicator(from: UIView, tag: Int) {
        let rootView = UIApplication.shared.windows.first
        let view = rootView?.viewWithTag(tag) as? ProcessingIndicator
        view?.stopAnimating()
        view?.removeFromSuperview()
    }
    
    func loadMore(tableView: UITableView, indexPath: IndexPath, limit: Int, category: RedditEndpoint, session: Session) {
        let lastPost = self.postDataSource.posts!.last!
        RedditAPI.fetchPosts(after: lastPost.name, limit: limit, category: category, session: session) {
            (result) in

            DispatchQueue.main.async {
                switch result {
                case let .PostFetchSuccess(posts):
                    var lastIndex = self.postDataSource.posts!.count - 1
                    self.postDataSource.posts!.append(contentsOf: posts)
                    let newIndexPaths = posts.map{
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
