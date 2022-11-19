//
//  ImageStore.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 15.02.2021.
//

import Foundation
import UIKit

class ImageStore {
    private var cache = NSCache<NSString, UIImage>()
    
    public func setImageFor(id: String, with image: UIImage) {
        self.cache.setObject(image, forKey: NSString(string: id))
    }
    
    public func imageFor(id: String) -> UIImage? {
        guard let image = self.cache.object(forKey: NSString(string: id)) else {
            return nil
        }
        
        return image
    }
}
