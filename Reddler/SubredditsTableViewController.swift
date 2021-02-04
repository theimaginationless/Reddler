//
//  SubredditsTableViewController.swift
//  Reddler
//
//  Created by Dmitry Teplyakov on 03.02.2021.
//

import UIKit

class SubredditsTableViewController: UITableViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.placeholder = NSLocalizedString("Search subreddit", comment: "Placeholder for subreddit searching field")
    }
}
