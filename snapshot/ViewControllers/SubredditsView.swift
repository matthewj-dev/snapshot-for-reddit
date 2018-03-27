//
//  SubredditsView.swift
//  snapshot
//
//  Created by Hunter Forbus on 3/16/18.
//  Copyright © 2018 Lapis Software. All rights reserved.
//

import UIKit

class SubredditsView: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIViewControllerPreviewingDelegate {
    
    @IBOutlet weak var redditTable: UITableView!
    
    var redditAPI = RedditHandler()
    var subreddits = [String]()
    let ncCenter = NotificationCenter.default

    override func loadView() {
        super.loadView()
        
        // Creates the Search controller that is used as the 'Go to Subreddit' option
        let searchy = UISearchController(searchResultsController: nil)
        searchy.searchBar.placeholder = "Go to Subreddit"
        searchy.searchBar.returnKeyType = .continue
        searchy.searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchy.searchBar.delegate = self
        
        // Assigns the controller to the navigationitem's reference for a searchcontroller
        self.navigationItem.searchController = searchy
        
        // Registers the tableview as able to accept 3D touch
        self.registerForPreviewing(with: self, sourceView: self.redditTable)
        
        redditTable.delegate = self
        redditTable.dataSource = self
        
        //Notification for when the user has logged in
        ncCenter.addObserver(self, selector: #selector(repopulateSubTable), name: Notification.Name.init(rawValue: "userLogin"), object: nil)
        
        repopulateSubTable()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		darkMode(isOn: darkModeEnabled)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    //Creates a new view based on the cell selected and then pushed onto the navigation controller
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newView = loadPostViewForPush(name: (redditTable.cellForRow(at: indexPath) as! RedditListCell).subredditName.text)
		
        self.navigationController?.pushViewController(newView, animated: true)
        self.redditTable.deselectRow(at: indexPath, animated: true)
    }
    
    //Creates and returns each cell of the table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = redditTable.dequeueReusableCell(withIdentifier: "subredditListCell") as! RedditListCell
		
		if darkModeEnabled {
			cell.backgroundColor = .black
			cell.subredditName.textColor = .white
			cell.selectionStyle = .gray
		}
		else {
			cell.backgroundColor = .white
			cell.subredditName.textColor = .black
			cell.selectionStyle = .default
		}
		
		if indexPath.section == 0 {
			switch indexPath.row {
			case 0: cell.subredditName.text = "Home"
			case 1: cell.subredditName.text = "Popular"
			default: cell.subredditName.text = "Home"
			}
		}
		
        if indexPath.section == 1 {
            cell.subredditName.text = subreddits[indexPath.row]
            return cell
        }
		
        return cell
        
    }
    
    //Sets the title per header in table
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Reddit"
        }
        if section == 1 {
            return "Subscribed"
        }
        return ""
    }
	
	// Allows editing of the view that are the headers of the tableview
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		if darkModeEnabled {
			view.tintColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
			(view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor(iOSColor: .iOSBlue)
		}
		else {
			(view as! UITableViewHeaderFooterView).tintColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
			(view as! UITableViewHeaderFooterView).textLabel?.textColor = .black
		}
		
	}
	
    //Tells the table the height of the row
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    //Tells the tableview how many rows are in a section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        if section == 1 {
            return subreddits.count
        }
        return 0
    }
    
    //Tells the tableview how many sections the tableview will contain
    func numberOfSections(in tableView: UITableView) -> Int {
		if subreddits.count != 0 {
			return 2
		}
        return 1
    }
    
    //repopulates the subreddit table
    @objc func repopulateSubTable(){
		if let api = (self.tabBarController as? TabBarControl)?.redditAPI {
			redditAPI = api
			
			if redditAPI.authenticatedUser != nil {
				redditAPI.authenticatedUser!.asyncGetSubscribedSubreddits(api: redditAPI, completition: {(subs) in
					self.subreddits = subs

					// Starts updates onto the TableView
					self.redditTable.beginUpdates()
					
					if self.redditTable.numberOfSections != 2 {
						self.redditTable.insertSections(IndexSet(integer: 1), with: .right)
					}
					for i in 0..<self.subreddits.count {
						// Inserts a row for each Subreddit in list
						self.redditTable.insertRows(at: [IndexPath(row: i, section: 1)], with: .top)
					}
					// Informs the tableview that the updates have concluded
					self.redditTable.endUpdates()
					
				})
			}
		}
    }
    
    // Function called when the 'continue' button is pressed while editing the text of the searchbar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.navigationItem.searchController?.dismiss(animated: true, completion: nil)
        let newView = storyboard?.instantiateViewController(withIdentifier: "PostsView") as! PostsView
        newView.subredditToLoad = searchBar.text!
        self.navigationController?.pushViewController(newView, animated: true)
        searchBar.text = ""
        
    }
    
    // Function called when previewing a view with 3D Touch
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Uses the point provided by the function to get the indexpath of the item selected from the tableview
        guard let indexPath = redditTable.indexPathForRow(at: location) else {
            return nil
        }
        
        // Uses the indexpath mentioned above to reference the cell
        guard let cell = redditTable.cellForRow(at: indexPath) else {
            return nil
        }
        
        let newView = storyboard?.instantiateViewController(withIdentifier: "PostsView") as! PostsView
        if indexPath.section == 1 {
            newView.subredditToLoad = subreddits[indexPath.row]
        } else {
            newView.subredditToLoad = ""
        }
        
        self.redditTable.deselectRow(at: indexPath, animated: true)
        
        // Tells the UI which rectangle to animate with the 3D touch animation
        previewingContext.sourceRect = cell.frame
        
        return newView
    }
    
    // Function called when pressing a view with 3D Touch
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
    
}
