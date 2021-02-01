//
//  PostDetailViewController.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 01.02.2021.
//

import UIKit

class PostDetailViewController: UIViewController {
    @IBOutlet weak var contentTextView: UITextView!
    var post: RedditPost!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.post.title
        self.contentTextView.text = self.post.selftext
    }
}
