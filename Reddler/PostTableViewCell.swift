//
//  PostTableViewCell.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 13.01.2021.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subredditLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var numCommentsLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var imageCollectionView: ImageCollectionView!
    @IBOutlet weak var imageCollectionViewHeightConstant: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentTextView.textContainer.lineBreakMode = .byTruncatingTail
        self.contentTextView.textContainer.lineFragmentPadding = 0
    }
}
