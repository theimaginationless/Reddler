//
//  StartupViewController.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 20.01.2021.
//

import UIKit
import SafariServices

class StartupViewController: UIViewController {
    var safariViewController: SFSafariViewController?
    var originVerificationState: String!
    var session: Session?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signinAction(_ sender: Any) {
        self.authenticationProcess()
    }
    
    @objc func authenticationProcess() {
        self.originVerificationState = UUID().uuidString
        guard
            let url = RedditAPI.generateAuthorizeUrl(clientId: RedditConfig.clientId, responseType: .code, state: originVerificationState, scope: [.read, .identity])
        else {
            print("\(#function): OAuth url generation failed!")
            return
        }
        
        self.safariViewController = SFSafariViewController(url: url)
        self.present(self.safariViewController!, animated: true)
        NotificationCenter.default.addObserver(self, selector: #selector(self.authenticationTrigger(_:)), name: Notification.Name(NotificationNames.AuthorizationRedirect.rawValue), object: nil)
    }
    
    @objc func authenticationTrigger(_ notification: Notification) {
        self.safariViewController?.dismiss(animated: true)
        
        guard let dataDict = notification.object as? [String: Any],
              let code = dataDict["code"] as? String,
              let verificationString = dataDict["state"] as? String
        else {
            print("\(#function): Cannot extract verification payload from notification.\nOAuth request was declined?")
            NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationNames.AuthorizationRedirect.rawValue), object: nil)
            let alertController = UIAlertController(title: "Failed!", message: "Sign in failed!\nTry again!", preferredStyle: .alert)
            let closeAlertAction = UIAlertAction(title: "Ok", style: .cancel)
            alertController.addAction(closeAlertAction)
            self.present(alertController, animated: true)
            return
        }
        
        guard self.originVerificationState == verificationString else {
            print("\(#function): OAuth response verification failed!\nReturned state: \(verificationString)")
            return
        }
        
        RedditAPI.authenticationProcess(clientId: RedditConfig.clientId, code: code) {
            (result) in
            
            OperationQueue.main.addOperation {
                switch result {
                case let .AuthenticationSuccess(session):
                    self.session = session
                    do {
                        try KeychainUtils.saveCredentials(for: session)
                    }
                    catch let error {
                        print("\(#function): \(error)")
                    }
                    
                    let mainSB = UIStoryboard(name: "Main", bundle: nil)
                    guard
                        let mainNC = mainSB.instantiateInitialViewController(),
                        let postTableVC = mainNC.children.first as? PostTableViewController
                    else {
                        print("\(#function): Instantiate PostTable NC/VC failed!")
                        return
                    }
                    
                    self.dismiss(animated: false) {
                        postTableVC.session = self.session
                        mainNC.modalPresentationStyle = .fullScreen
                        self.present(mainNC, animated: true)
                    }
                    
                default:
                    print("\(#function): Error: \(result)")
                }
            }
        }
    }
}
