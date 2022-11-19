//
//  Image.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 15.02.2021.
//

import UIKit

class Image {
    var previewImage: UIImage?
    var image: UIImage?
    var previewUrl: URL
    var url: URL
    
    required init() {
        self.url = URL(string: "empty")!
        self.previewUrl = URL(string: "empty")!
    }
}
