//
//  TeamMemberController.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/19/23.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase
import SwiftUI
import LBTATools
import JGProgressHUD
import CoreData

class TeamMemberController: UITableViewController {
    let db = Firestore.firestore()
    var teamMemberFiles = [FB_File]()
    var teamMember: TeamMember?
    
    private var cursor: DocumentSnapshot?
    private let pageSize = 12 // use this for the document-limit value in the query
    private var dataMayContinue = true
    
    var filesCollectionRef: Query!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = teamMember?.name
        tableView.backgroundColor = UIColor.darkBlue
        showNavigationBar(animated: false)
        navigationController?.setTintColor(.white)
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // change color of seperator lines
        tableView.separatorColor = .darkBlue
        
        // removes lines below cells
        tableView.tableFooterView = UIView() // blank UIView
        tableView.register(FileCell.self, forCellReuseIdentifier: "cellId")
        print("reloaded team member \(teamMember?.name ?? "")'s files")
        fetchFiles()
    
    }
    
    func fetchFiles() {
        filesCollectionRef = db.collection("Users").document((teamMember?.id)!).collection("Files").order(by: "modified", descending: true).limit(to: pageSize)
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
                    let modified = data["modified"] as? Timestamp ?? nil
                    let date = modified?.dateValue()
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
                     
                    let newFile = FB_File(name: name, coc: coc, deductible: deductible, cocSwitch: cocSwitch, imageData: imageData, timeStamp: timeStamp, modified: date, type: type, insCheckACVTotal: insCheckACVTotal, id: id, acvItemTotal: acvItemTotal, cashItemTotal: cashItemTotal, insCheckTotal: insCheckTotal, pymtCheckTotal: pymtCheckTotal, rcvItemTotal: rcvItemTotal, note: note, creditItemTotal: creditItemTotal, missingFunds: missingFunds, missingFundsSwitch: missingFundsSwitch)
                    self.teamMemberFiles.append(newFile)
                    

                }
                if snapshot?.count ?? 0 < self.pageSize {
                    self.cursor = nil
                } else {
                    self.cursor = snapshot?.documents.last
                }
                    
                self.tableView.reloadData()
            }
        }
        
        
    }
    
    
    func fetchMoreFiles() {
        guard dataMayContinue, let cursor = cursor else { return }
        dataMayContinue = false /* Because scrolling to bottom will cause this method to be called
                                 in rapid succession, use a boolean flag to limit this method
                                 to one call. */
        print("scroll cursor:", cursor)
        filesCollectionRef = db.collection("Users").document((teamMember?.id)!).collection("Files").order(by: "modified", descending: true).start(afterDocument: cursor).limit(to: pageSize)
        print("Fetching more files from Firebase")
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
                    let modified = data["modified"] as? Timestamp ?? nil
                    let date = modified?.dateValue()
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
                     
                    let newFile = FB_File(name: name, coc: coc, deductible: deductible, cocSwitch: cocSwitch, imageData: imageData, timeStamp: timeStamp, modified: date, type: type, insCheckACVTotal: insCheckACVTotal, id: id, acvItemTotal: acvItemTotal, cashItemTotal: cashItemTotal, insCheckTotal: insCheckTotal, pymtCheckTotal: pymtCheckTotal, rcvItemTotal: rcvItemTotal, note: note, creditItemTotal: creditItemTotal, missingFunds: missingFunds, missingFundsSwitch: missingFundsSwitch)
                    self.teamMemberFiles.append(newFile)
                    

                }
                if snapshot?.count ?? 0 < self.pageSize {
                    self.cursor = nil
                } else {
                    self.cursor = snapshot?.documents.last
                    self.dataMayContinue = true
                }
                self.tableView.reloadData()
            }
        }
    }
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentSize = scrollView.contentSize.height
        print("scroll contentSize: ", contentSize)
        
        if contentSize - scrollView.contentOffset.y <= scrollView.bounds.height {
            didScrollToBottom()
        }
    }
        
    private func didScrollToBottom() {
        print("scrolled to bottom")
        fetchMoreFiles()
    }
    
}

