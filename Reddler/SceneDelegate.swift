//
//  SceneDelegate.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 12.01.2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var state: String?
    var code: String?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
//        if let session = try? KeychainUtils.loadCredentials(for: RedditConfig.account) {
//            try! KeychainUtils.removeCredentials(for: session)
//        }
        
        if let session = try? KeychainUtils.loadCredentials(for: RedditConfig.account) {
            let mainSB = UIStoryboard(name: "Main", bundle: nil)
            guard let mainSVC = mainSB.instantiateInitialViewController() as? UISplitViewController,
                  let subredditsTableVC = mainSVC.viewController(for: .primary) as? SubredditsTableViewController,
                  let mainNC = mainSVC.viewController(for: .secondary) as? UINavigationController,
                  let postTableVC = mainNC.children.first as? PostTableViewController
            else {
                print("Cannot create PostTableViewController.")
                return
            }
            
            let subredditDS = SubredditTableViewDataSource()
            let postDS = PostTableViewDataSource()
            subredditsTableVC.switchSubredditDelegate = postTableVC
            subredditsTableVC.session = session
            subredditsTableVC.subredditDataSource = subredditDS
            subredditsTableVC.modalPresentationStyle = .popover
            postTableVC.session = session
            postTableVC.postDataSource = postDS
            postTableVC.postTableReloadDelegate = subredditsTableVC
            self.window!.rootViewController = mainSVC
        }
        else {
            let startupSB = UIStoryboard(name: "Startup", bundle: nil)
            guard let startupVC = startupSB.instantiateInitialViewController() as? StartupViewController else {
                print("Cannot create StartupViewController.")
                return
            }
            
            self.window!.rootViewController = startupVC
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let urlContext = URLContexts.first!
        let components = URLComponents(url: urlContext.url, resolvingAgainstBaseURL: false)
        if let queryItems = components?.queryItems {
            let queryDictItems = Dictionary(uniqueKeysWithValues: queryItems.lazy.compactMap{($0.name, $0.value ?? "")})
            self.state = queryDictItems["state"]
            self.code = queryDictItems["code"]
            NotificationCenter.default.post(name: Notification.Name(NotificationNames.AuthorizationRedirect.rawValue), object: queryDictItems)
        }
    }
}

