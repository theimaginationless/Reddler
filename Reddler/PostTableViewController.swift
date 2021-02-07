//
//  PostTableViewController.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 13.01.2021.
//

import UIKit

protocol PostTableReloadDelegate {
    func prepareSubreddits()
}

class PostTableViewController: UITableViewController, SwitchSubredditDelegate {
    var session: Session!
    var postDataSource: PostTableViewDataSource!
    var postTableReloadDelegate: PostTableReloadDelegate?
    var lastTriggeredIndex = 0
    var navigationBar: UINavigationBar!
    var currentSubreddit: Subreddit? {
        didSet {
            if let subreddit = self.currentSubreddit {
                self.subredditTitleLabel.text = subreddit.displayNamePrefixed
            }
            else {
                self.subredditTitleLabel.text = "\(NSLocalizedString("Home", comment: "Home indicating main subreddit"))"
            }
            self.subredditTitleLabel.sizeToFit()
        }
    }
    var category: RedditEndpoint = .new
    var processingIndicator: UIProgressIndicatorView {
        get {
            let rootView = UIApplication.shared.windows.first!
            let processingIndicator = self.prepareActivityIndicator(at: rootView)
            return processingIndicator
        }
    }

    private lazy var concurrencyDispatchQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "me.theimless.reddler.concurrencyDispatchQueue", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        return queue
    }()
    @IBOutlet var subredditTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self.postDataSource
        self.tableView.delegate = self
        self.navigationBar = self.navigationController!.navigationBar
        self.subredditTitleLabel = UILabel()
        self.navigationBar.topItem!.titleView = self.subredditTitleLabel
        self.currentSubreddit = nil
        let refreshControl = UIRefreshControl()
        let handler: (UIAction) -> Void = {
            _ in
            self.reloadPosts {
                self.refreshControl?.endRefreshing()
            }
        }
        refreshControl.addAction(UIAction(handler: handler), for: .valueChanged)
        self.refreshControl = refreshControl
        let processingIndicator = self.processingIndicator
        processingIndicator.startAnimating()
        self.reloadPosts {
            processingIndicator.stopAnimating()
            UIView.animate(withDuration: 0.1, animations: {processingIndicator.alpha = 0.0})  {
                finished in
                processingIndicator.removeFromSuperview()
            }
        }
        self.postTableReloadDelegate?.prepareSubreddits()
    }
    
    @objc private func reloadPosts(completion: (() -> Void)? = nil) {
        RedditAPI.fetchPosts(subreddit: self.currentSubreddit?.displayNamePrefixed, limit: 20, category: self.category, session: self.session) {
            (result) in
            
            OperationQueue.main.addOperation {
                switch result {
                case let .PostFetchSuccess(posts):
                    self.postDataSource.posts = posts
                    self.tableView.reloadData()
                default:
                    print("\(#function): Nothing!")
                }
                
                if let completionForExecute = completion {
                    completionForExecute()
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let triggeredIndex = self.postDataSource.posts!.count - 1
        guard triggeredIndex > self.lastTriggeredIndex else {
            return
        }
        
        if triggeredIndex == indexPath.row {
            self.lastTriggeredIndex = triggeredIndex
            self.loadMore(tableView: tableView, indexPath: indexPath, limit: 20, category: self.category, session: self.session)
        }
    }
    
    func prepareActivityIndicator(at rootView: UIView) -> UIProgressIndicatorView {
        let rootFrame = rootView.frame
        let processIndicator = UIProgressIndicatorView(frame: rootFrame)
        processIndicator.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(processIndicator)
        processIndicator.center = rootView.center
        return processIndicator
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowPostDetail":
            guard let destination = segue.destination as? PostDetailViewController,
                  let cell = sender as? PostTableViewCell,
                  let indexPath = self.tableView.indexPath(for: cell),
                  let post = self.postDataSource.posts?[indexPath.row]
            else {
                print("Cannot initialize data for segue: \(String(describing: segue.identifier))")
                return
            }
            
            destination.post = post
        default:
            print("Nothing for segue: \(String(describing: segue.identifier))")
        }
    }
    
    func switchSubreddit(to subreddit: Subreddit?) {
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        self.currentSubreddit = subreddit
        let processingIndicator = self.processingIndicator
        processingIndicator.startAnimating()
        self.reloadPosts {
            processingIndicator.stopAnimating()
            UIView.animate(withDuration: 0.5, animations: {processingIndicator.alpha = 0.0})  {
                finished in
                processingIndicator.removeFromSuperview()
            }
        }
    }
    
    func loadMore(tableView: UITableView, indexPath: IndexPath, limit: Int, category: RedditEndpoint, session: Session) {
        let lastPost = self.postDataSource.posts!.last!
        RedditAPI.fetchPosts(subreddit: self.currentSubreddit?.displayNamePrefixed, after: lastPost.name, limit: limit, category: category, session: session) {
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
