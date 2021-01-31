//
//  ProcessingIndicator.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 31.01.2021.
//

import UIKit

class ProcessingIndicator: UIView {
    var activityIndicator: UIActivityIndicatorView
    var cornerRadius: CGFloat = 15
    
    override init(frame: CGRect) {
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        super.init(frame: frame)
        self.initialize(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        super.init(coder: coder)
        self.initialize(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    }
    
    private func initialize(frame: CGRect) {
        let defaultFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let frameView = UIVisualEffectView(frame: defaultFrame)
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        frameView.effect = blurEffect
        self.addSubview(frameView)
        frameView.contentView.addSubview(self.activityIndicator)
        frameView.center = self.center
        frameView.layer.cornerRadius = self.cornerRadius
        frameView.layer.masksToBounds = true
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        let hActivityIndicatorConstraint = NSLayoutConstraint(item: self.activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: frameView, attribute: .centerX, multiplier: 1, constant: 0)
        let vActivityIndicatorConstraint = NSLayoutConstraint(item: self.activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: frameView, attribute: .centerY, multiplier: 1, constant: 0)
        hActivityIndicatorConstraint.isActive = true
        vActivityIndicatorConstraint.isActive = true
    }
    
    public func startAnimating() {
        self.activityIndicator.startAnimating()
    }
    
    public func stopAnimating() {
        self.activityIndicator.stopAnimating()
    }
}
