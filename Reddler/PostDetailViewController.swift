//
//  PostDetailViewController.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 01.02.2021.
//

import UIKit

class PostDetailViewController: UIViewController {
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subredditLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var imageCollectionView: ImageCollectionView!
    @IBOutlet weak var imageCollectionViewHeightConstraint: NSLayoutConstraint!
    var post: RedditPost!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.post?.title
        self.contentTextView.text = self.post.selftext
        self.titleLabel.text = self.post.title
        self.authorLabel.text = self.post.author
        self.subredditLabel.text = "r/\(self.post.subreddit)"
        self.scoreLabel.text = "\(self.post.score)"
        if self.post.images.count == 0 {
            self.imageCollectionViewHeightConstraint.constant = 0
        }
    }
}
