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
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signinAction(_ sender: Any) {
        self.authenticationProcess()
    }
    
    @objc func authenticationProcess() {
        self.originVerificationState = UUID().uuidString
        guard
            let url = RedditAPI.generateAuthorizeUrl(clientId: RedditConfig.clientId, responseType: .code, state: originVerificationState, scope: [.read])
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
            print("\(#function): Cannot extract verification payload from notification")
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
                case let .AuthenticationSuccess(token):
                    print("Success! \(token)")
                    let mainSB = UIStoryboard(name: "Main", bundle: nil)
                    guard
                        let postTableNC = mainSB.instantiateInitialViewController() as? UINavigationController
                    else {
                        print("\(#function): Instantiate PostTable NC/VC failed!")
                        return
                    }
                    
                    self.dismiss(animated: false) {
                        postTableNC.modalPresentationStyle = .fullScreen
                        self.present(postTableNC, animated: true)
                    }
                    
                default:
                    print("\(#function): Error: \(result)")
                }
            }
        }
    }
}
