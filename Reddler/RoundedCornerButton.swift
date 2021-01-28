//
//  RoundedCornerButton.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 28.01.2021.
//

import UIKit

@IBDesignable
class RoundedCornerButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat {
        set {
            self.layer.cornerRadius = newValue
        }
        
        get {
            self.layer.cornerRadius
        }
    }
    
}
