//
//  TeamController.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/18/23.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase
import SwiftUI
import LBTATools
import JGProgressHUD
import CoreData

class TeamController: UITableViewController {
    let db = Firestore.firestore()
    var teamMembers = [TeamMember]()
    var teamMember: TeamMember?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "My Team"
        tableView.separatorColor = .darkBlue
        tableView.backgroundColor = UIColor.darkBlue
        
        // removes lines below cells
        tableView.tableFooterView = UIView() // blank UIView
        tableView.register(TeamCell.self, forCellReuseIdentifier: "cellId")
        fetchCompanyId()
    
    }
    
    func fetchCompanyId() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Users").document(uid).getDocument(completion: { snapshot, error in
            if let err = error {
                debugPrint("Error fetching user: \(err)")
            } else {
                if let data = snapshot?.data() {
                    let companyId = data["companyId"] as? String
                    
                    if companyId != "" {
                        return self.fetchTeam(companyId: companyId!)
                    }
                }
            }
        })
        
    }
    
    func fetchTeam(companyId: String) {
        teamMembers = []
        print("Fetching team from Firebase")
        db.collection("Users").whereField("companyId", isEqualTo: companyId).order(by: "name").getDocuments { (snapshot, error) in
            if let err = error {
                debugPrint("Error fetching files: \(err)")
            } else {
                guard let snap = snapshot else { return }
                for document in snap.documents {
                    let data = document.data()
                    let name = data["name"] as? String ?? ""
                    let companyId = data["companyId"] as? String ?? ""
                    let id = data["uid"] as? String ?? ""
                    let imageData = data["profile pic url"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let access = data["access"] as? String ?? ""
                    let missingFundsTotal = data["missingFundsTotal"] as? Double ?? 0.0
                    
                     
                    let newTeamMember = TeamMember(name: name, companyId: companyId, id: id, imageData: imageData, email: email, access: access, missingFundsTotal: missingFundsTotal)
                    self.teamMembers.append(newTeamMember)
                    

                }
                self.tableView.reloadData()
            }
        }
    }
}
