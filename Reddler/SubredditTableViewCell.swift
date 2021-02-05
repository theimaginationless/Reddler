//
//  SubredditTableViewCell.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 04.02.2021.
//

import UIKit

class SubredditTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    var name: String!
    var isFavorite: Bool = false {
        didSet {
            var imageName = "star"
            if self.isFavorite {
                imageName = "\(imageName).fill"
            }
            
            self.favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    @IBAction func favoriteButtonAction(_ sender: Any) {
        self.isFavorite = !self.isFavorite
    }
}
