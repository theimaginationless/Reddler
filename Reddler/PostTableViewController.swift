//
//  PostTableViewController.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 13.01.2021.
//

import UIKit
import SafariServices

class PostTableViewController: UITableViewController {
    var safariViewController: SFSafariViewController?
    var sceneDelegate: SceneDelegate!
    var authorized: Bool = false
    var randomState: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.randomState = UUID().uuidString
        let url = RedditAPI.generateAuthorizeUrl(clientId: "placeholder", responseType: .code, state: self.randomState, scope: [.read])!
        self.sceneDelegate = (self.view.window!.windowScene!.delegate as! SceneDelegate)
        self.safariViewController = SFSafariViewController(url: url)
        if !self.authorized {
            self.present(safariViewController!, animated: true)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.testNotif(_:)), name: Notification.Name(NotificationNames.AuthorizationRedirect.rawValue), object: nil)
    }
    
    @objc func testNotif(_ notification: Notification) {
        guard self.sceneDelegate.state == self.randomState else {
            return
        }
        
        self.authorized = true
        self.safariViewController?.dismiss(animated: true)
        RedditAPI.authrization(clientId: "placeholder", code: self.sceneDelegate!.code!) {
            result in
            print("Result: \(result)")
        }
    }
}
