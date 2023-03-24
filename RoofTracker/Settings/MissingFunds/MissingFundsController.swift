//
//  MissingFundsController.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/22/23.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase
import SwiftUI
import LBTATools
import JGProgressHUD
import CoreData

protocol MissingFundsControllerDelegate {
    func refreshMissingFunds()
}

class MissingFundsController: UITableViewController, UINavigationControllerDelegate {
    var delegate: MissingFundsControllerDelegate!
    let db = Firestore.firestore()
    var missingFunds = [MissingFund]()
    var missingFund: MissingFund?
    var missingFundsCollectionRef: Query!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Missing Funds"
        tableView.separatorColor = .darkBlue
        tableView.backgroundColor = UIColor.darkBlue
        
        tableView.register(MissingFundsCell.self, forCellReuseIdentifier: "cellId")
        
        // removes lines below cells
        tableView.tableFooterView = UIView() // blank UIView
        
        let done = UIBarButtonItem(title: NSString(string: "Done") as String, style: .plain, target: self, action: #selector(handleDone))
        
        navigationItem.rightBarButtonItems = [done]
        fetchMissingFunds()
    
    }
    func fetchMissingFunds() {
        print("Fetching missing funds from Firebase")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        missingFundsCollectionRef = db.collection("Users").document(uid).collection("Files").whereField("missingFunds", isNotEqualTo: 0)
        missingFundsCollectionRef.getDocuments { (snapshot, error) in
            if let err = error {
                debugPrint("Error fetching files: \(err)")
            } else {
                guard let snap = snapshot else { return }
                for document in snap.documents {
                    let data = document.data()
                    let id = data["id"] as? String ?? ""
                    let name = data["name"] as? String ?? ""
                    let modified = data["modified"] as? Timestamp ?? nil
                    let date = modified?.dateValue()
                    let missingFunds = data["missingFunds"] as? Double ?? nil
                    let missingFundsSwitch = data["missingFundsSwitch"] as? Bool ?? false
                    
                    let newItem = MissingFund(id: id, name: name, missingFunds: missingFunds, missingFundsSwitch: missingFundsSwitch, modified: date)
                    self.missingFunds.append(newItem)
                    
                }
                // sort file by date
                self.missingFunds.sort(by: {$0.modified! > $1.modified!})
                self.tableView.reloadData()
            }
        }
    }
    
    func updateMissingFundsTotalInFile(missingFundsId: String, missingFunds: Double){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var currentUserMissingFundsTotal = 0.0
        db.collection("Users").document(uid).getDocument(completion: { snapshot, error in
            if let err = error {
                debugPrint("Error fetching user: \(err)")
            } else {
                if let data = snapshot?.data() {
                    let companyId = data["companyId"] as? String
                    let missingFundsTotal = data["missingFundsTotal"] as? Double
                    
                    if missingFundsTotal != nil {
                        currentUserMissingFundsTotal = missingFundsTotal!
                    }
                    self.db.collection("Users").document(uid).updateData(["missingFundsTotal" : currentUserMissingFundsTotal - missingFunds])
                    if companyId != "" {
                        return self.updateCompanyTotalMissingFunds(missingFundsId: missingFundsId, missingFunds: missingFunds, companyId: companyId!)
                    }
                }
            }
        })
        
    }
    private func updateCompanyTotalMissingFunds(missingFundsId: String, missingFunds: Double, companyId: String) {
        var currentCompanyMissingFundsTotal = 0.0
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Companies").document(companyId).getDocument(completion: { snapshot, error in
            if let err = error {
                debugPrint("Error fetching profile: \(err)")
            } else {
                if let data = snapshot?.data() {
                    let missingFundsTotal = data["missingFundsTotal"] as? Double ?? nil
                    
                    if missingFundsTotal != nil {
                        currentCompanyMissingFundsTotal = missingFundsTotal!
                    }
                    self.db.collection("Companies").document(companyId).updateData(["missingFundsTotal" : currentCompanyMissingFundsTotal - missingFunds])
                    self.deleteMissingFundsFromCompany(missingFundsId: missingFundsId, companyId: companyId)
                }
            }
        })
        
    }
    
    private func deleteMissingFundsFromCompany(missingFundsId: String, companyId: String) {
        missingFundsCollectionRef = db.collection("Companies").document(companyId).collection("MissingFundsLog").whereField("fileId", isEqualTo: missingFundsId)
        missingFundsCollectionRef.getDocuments { (snapshot, error) in
            if let err = error {
                debugPrint("Error fetching files: \(err)")
            } else {
                guard let snap = snapshot else { return }
                for document in snap.documents {
                    let data = document.data()
                    let id = data["id"] as? String ?? ""
                    self.db.collection("Companies").document(companyId).collection("MissingFundsLog").document(id).delete()

                }
            }
        }
        
    }
    @objc func handleDone() {
        print("in done missingfunds")
        dismiss(animated: true) {
                        self.delegate?.refreshMissingFunds()
                    }
    }
    // create UILabel subclass for custom text drawing - usually for my headers
    class IndentedLabelSummary: UILabel {
        override func drawText(in rect: CGRect) {
            let insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
            let customRect = rect.inset(by: insets)
            super.drawText(in: customRect)
        }
    }
    func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        return
    }
}

