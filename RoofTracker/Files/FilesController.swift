//
//  ViewController.swift
//  TrainingCourse
//
//  Created by Mitch Baumgartner on 2/27/21.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase
import SwiftUI
import LBTATools
import JGProgressHUD
import CoreData


// controller name should reflect what it is presenting
class FilesController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {
    
    let reachability = try! Reachability()
    var files = [FB_File]() // empty array
    // this variable is for the search feature
    var filteredFiles = [FB_File]()
    // this variable is for the open close segmented control feature
    var rowsToDisplay = [FB_File]()
    var file: FB_File?
    
    var filesNameOnly = [String]()
    // this variable is for the open close segmented control feature
    // the "lazy" means that this variable is created AFTER the files variable is created.
    let searchController = UISearchController()
    
    var filesCollectionRef: CollectionReference!
    let db = Firestore.firestore()
    

    
    // this function will refresh the viewController when user goes back from the file summary controller, refreshing the cell to reflect the most accurate ins still owes HO
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // check for internet connection, if there is none show an error
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("reachable via wifi")
            } else {
                print("reachable via cellular")
            }
        }
        reachability.whenUnreachable = { _ in
            print("no internet connection, not reachable")
            self.showError(title: "No internet connection", message: "This app requires internet to store your data. Any changes will be lost if you proceed without a connection.")
        }
        do {
            try reachability.startNotifier()
        } catch { // catch an error
            print("unable to start notifier")
        }
        print("view did appear reload files")
//        // this will give all the files in the coreDatabase layer
        //self.files = CoreDataManager.shared.fetchFiles()
        checkIfSignedIn()
        tableView.reloadData()

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // this will give all the files in the coreDatabase layer
        //self.files = CoreDataManager.shared.fetchFiles()
        tableView.backgroundColor = UIColor.darkBlue
        showNavigationBar(animated: false)
        navigationController?.setTintColor(.white)
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.title = "My Files"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddFile))
        let settings = UIBarButtonItem(title: NSString(string: "\u{2699}\u{0000FE0E}") as String, style: .plain, target: self, action: #selector(handleSettings))
        let font = UIFont.systemFont(ofSize: 33) // adjust the size as required
        let attributes = [NSAttributedString.Key.font : font]
        settings.setTitleTextAttributes(attributes, for: .normal)
        navigationItem.leftBarButtonItems = [settings]
    
        
        // nav item for Reset all button in top left corner
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(handleReset))
        //filterFiles()
        // this sets up the tableView so that rows are actually visible
        // this modifies the property on table view (accesses the white list of cells)
        // changes color of list to dark blue
        // removes lines of tableView
        //tableView.separatorStyle = .none
        // change color of seperator lines
        tableView.separatorColor = .darkBlue
        
        // removes lines below cells
        tableView.tableFooterView = UIView() // blank UIView
        // this method takes in a cell class of type "any class" and takes in a string of "cellId" the class type is found by using .self
        // call the fileCell in fileCell.swift file for the type of cell we are returning, this gives us custom cell abilities
        // register fileCell wiht cellId
        tableView.register(FileCell.self, forCellReuseIdentifier: "cellId")
        
    
        // plus sign image for bar button item: UIBarButtonItem(image: #imageLiteral(resourceName: "plus").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleAddFile))
        
        print("reloaded files")
        
    }
    
    func checkIfSignedIn() {
        // user is signed in
        if Auth.auth().currentUser != nil {
            print("user is signed in")
            fetchFiles()
            setupSegmentedControlUI()
            initSearchController()

        }  else {
            print("user is signed out")
            files = []
            filteredFiles = []
            rowsToDisplay = []
            setupSegmentedControlUI()
            navigationItem.searchController = nil
        }
    }
    
    
    // function that handles the settings button in top right corner
    @objc func handleSettings() {
        print("Settings..")
        let settingsController = SettingsController()
        let navController = CustomNavigationController(rootViewController: settingsController)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
        
        
    }
    
    @objc private func handleSignOut() {
        print("signing out")
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { (action) in
            self.hud.textLabel.text = "Signing Out"
            self.hud.show(in: self.view, animated: true)
            do {
                try Auth.auth().signOut()
                self.hud.dismiss(animated: true)
                self.dismiss(animated: true, completion: nil)
                self.viewWillAppear(true)
            
                print("user signed out")
                
            } catch let err {
                self.hud.dismiss(animated: true)
                print("Failed to sign out with error ", err)
                self.showError(title: "Sign Out Error", message: "Please try again.")
            }
        }
        // alert
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        optionMenu.addAction(signOutAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }


    func fetchFiles() {
        files = []
        print("Fetching files from Firebase")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        filesCollectionRef = db.collection("Users").document(uid).collection("Files")
        filesCollectionRef.getDocuments { (snapshot, error) in
            if let err = error {
                debugPrint("Error fetching files: \(err)")
            } else {
                guard let snap = snapshot else { return }
                for document in snap.documents {
                    let data = document.data()
                    let name = data["name"] as? String ?? ""
                    let coc = data["coc"] as? String ?? ""
                    let cocSwitch = data["cocSwitch"] as? Bool ?? false
                    let deductible = data["deductible"] as? String ?? ""
                    let imageData = data["imageData"] as? String ?? ""
                    let timeStamp = data["timeStamp"] as? String ?? ""
                    let modified = data["modified"] as? Date ?? nil
                    let type = data["type"] as? String ?? ""
                    let id = data["id"] as? String ?? ""
                    let insCheckACVTotal = data["insCheckACVTotal"] as? String ?? ""
                    let acvItemTotal = data["acvItemTotal"] as? String ?? ""
                    let cashItemTotal = data["cashItemTotal"] as? String ?? ""
                    let insCheckTotal = data["insCheckTotal"] as? String ?? ""
                    let pymtCheckTotal = data["pymtCheckTotal"] as? String ?? ""
                    let rcvItemTotal = data["rcvItemTotal"] as? String ?? ""
                    let note = data["note"] as? String ?? ""
                    let creditItemTotal = data["creditItemTotal"] as? String ?? ""
                    let missingFunds = data["missingFunds"] as? Double ?? nil
                    let missingFundsSwitch = data["missingFundsSwitch"] as? Bool ?? false
                     
                    let newFile = FB_File(name: name, coc: coc, deductible: deductible, cocSwitch: cocSwitch, imageData: imageData, timeStamp: timeStamp, modified: modified, type: type, insCheckACVTotal: insCheckACVTotal, id: id, acvItemTotal: acvItemTotal, cashItemTotal: cashItemTotal, insCheckTotal: insCheckTotal, pymtCheckTotal: pymtCheckTotal, rcvItemTotal: rcvItemTotal, note: note, creditItemTotal: creditItemTotal, missingFunds: missingFunds, missingFundsSwitch: missingFundsSwitch)
                    self.files.append(newFile)
                    

                }
        
                if self.searchController.isActive {
                    let searchBar = self.searchController.searchBar
                    let scopeButton = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
                    let searchText = searchBar.text!
                    self.filterForSearchAndScopeButton(searchText: searchText, scopeButton: scopeButton)
                } else {
                    self.filterFiles()
                }
                self.tableView.reloadData()
            }
            //self.sortExercises()
        }
    }
    
    
 
    func initSearchController() {
        searchController.loadViewIfNeeded()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.enablesReturnKeyAutomatically = true
        //searchController.searchBar.placeholder = "Search for files"
        // change color and text of placeholder
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString.init(string: "Search for files", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        // makes text in search bar white
        searchController.searchBar.barStyle = .black
        // makes color of "Cancel" and cursor blinking white
        searchController.searchBar.tintColor = .white
        // Text field in search bar.
        let textField = searchController.searchBar.value(forKey: "searchField") as! UITextField
        let glassIconView = textField.leftView as! UIImageView
        glassIconView.image = glassIconView.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        glassIconView.tintColor = UIColor.white
        // Scope: Normal text color
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        // Scope: Selected text color
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
    
        
        searchController.searchBar.returnKeyType = UIReturnKeyType.search
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        //navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.scopeButtonTitles = ["Open", "Closed", "All"]

        //searchController.searchBar.showsScopeBar = true
        searchController.searchBar.delegate = self
        searchController.searchBar.becomeFirstResponder()
        
    }
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scopeButton = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        let searchText = searchBar.text!
        filterForSearchAndScopeButton(searchText: searchText, scopeButton: scopeButton)

    }
    func filterForSearchAndScopeButton(searchText: String, scopeButton : String = "Open") { // default to open
        setupSegmentedControlUI()
        // this will give all the files in the coreDatabase layer
//        files = CoreDataManager.shared.fetchFiles()
        print("filterForSearchAndScopeButton() number of files = ", files.count)
        filteredFiles = files.filter {
            file in
            // this sets the filter by type
            let scopeMatch = (scopeButton == "All" || file.type!.lowercased().contains(scopeButton.lowercased()))
            if (searchController.searchBar.text != "") {
                let searchTextMatch = file.name!.lowercased().contains(searchText.lowercased())
                return scopeMatch && searchTextMatch
            } else {
                return scopeMatch
            }
        }
        self.filteredFiles.sort(by: {$0.timeStamp! > $1.timeStamp!})
        tableView.reloadData()
    }
    
    
    func filterFiles() {
        let fileType = openClosedSegmentedControl.titleForSegment(at: openClosedSegmentedControl.selectedSegmentIndex)
        rowsToDisplay = files.filter {
            file in
            let match = (file.type!.lowercased().contains((fileType?.lowercased())!))
        
            return match
        }
        
        // sort by name
        //self.files.sort(by: {$0.name! < $1.name!})
        // sort by last modified
        let longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .long
        longDateFormatter.timeStyle = .long
        
        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "MMMM dd,yyyy"
        
        //self.rowsToDisplay.sort(by: {$0.timeStamp! > $1.timeStamp!})
        self.rowsToDisplay.sort(by: {longDateFormatter.date(from: $0.timeStamp!) ?? shortDateFormatter.date(from: $0.timeStamp!)! > longDateFormatter.date(from: $1.timeStamp!) ?? shortDateFormatter.date(from: $1.timeStamp!)!})
        
        self.files.sort(by: {longDateFormatter.date(from: $0.timeStamp!) ?? shortDateFormatter.date(from: $0.timeStamp!)! > longDateFormatter.date(from: $1.timeStamp!) ?? shortDateFormatter.date(from: $1.timeStamp!)!})
        //self.files.sort(by: {$0.timeStamp! > $1.timeStamp!})
        tableView.reloadData()
        
    }
    
    
    // function that handles the plus button in top right corner
    @objc func handleAddFile() {
        print("Adding file..")
        
        // present modal presentation style (window will pop up from bottom)
        // this will access the CreatefileController.swift file and use the variables/functions defined in there
        let createFileController = CreateFileController()

        // customNavigationController is found in the appDelegate.swift file to use light content
        let navController = CustomNavigationController(rootViewController: createFileController)
        // fullscreen modal view
        //navController.modalPresentationStyle = .fullScreen
        // create link between createfileController and filesController
        createFileController.delegate = self
        present(navController, animated: true, completion: nil)
    }
    
    
    // segmented control for open or close files
    let openClosedSegmentedControl: UISegmentedControl = {
        let types = ["Open", "Closed"]
        let sc = UISegmentedControl(items: types)
        // default as first item
        sc.selectedSegmentIndex = 0
        // this handles then segment changing action
        sc.addTarget(self, action: #selector(handleSegmentChange), for: .valueChanged)
        
        sc.overrideUserInterfaceStyle = .light
        sc.translatesAutoresizingMaskIntoConstraints = false
        // highlighted filter color
        sc.selectedSegmentTintColor = UIColor.white
        // changes text color to black for selected button text
        sc.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
        // changes text color to black for non selected button text
        sc.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        return sc
    }()
    
    @objc fileprivate func handleSegmentChange() {
        print(openClosedSegmentedControl.selectedSegmentIndex)
        // these lines are to handle the different segment indexes (0 = open, 1 = closed)
        switch openClosedSegmentedControl.selectedSegmentIndex {
        case 0:
            filterFiles()
            //print("OPEN rowsToDisplay: ", rowsToDisplay.count)
        case 1:
            filterFiles()
            //print("CLOSED rowsToDisplay: ", rowsToDisplay.count)
        default:
            filterFiles()
        }
        tableView.reloadData()
    }
    
    
    
    func setupSegmentedControlUI() {
        let HEADER_HEIGHT = 34
        
        tableView.addSubview(openClosedSegmentedControl)
        openClosedSegmentedControl.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        openClosedSegmentedControl.bottomAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        openClosedSegmentedControl.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        openClosedSegmentedControl.heightAnchor.constraint(equalToConstant: 34).isActive = true
        tableView.tableHeaderView = openClosedSegmentedControl
        tableView.tableHeaderView?.frame.size = CGSize(width: tableView.frame.width, height: CGFloat(HEADER_HEIGHT))
        // this hides the segmented control buttons when search is active
        if searchController.isActive {
            tableView.tableHeaderView = nil
            tableView.tableHeaderView?.isHidden = true
        }
        
    }
    
    // add loading HUD status for when fetching data from server
    let hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .dark)
        hud.interactionType = .blockAllTouches
        return hud
    }()
    
    // create alert that will present an error, this can be used anywhere in the code to remove redundant lines of code
    private func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        return
    }
    
    
}









