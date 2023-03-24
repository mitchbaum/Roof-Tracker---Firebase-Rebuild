//
//  MissingFundsController+UITableView.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/22/23.
//
import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase
import FirebaseStorage
// this file will hold all my tableView delegate functions
extension MissingFundsController {
    
    
    
    
    // create footer that displays when there are no files in the table
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = "No missing funds found"
        
        label.textColor = .white
        label.textAlignment = .center
        
        return label
    }
    // create footer that is hidden when no rows are present
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return missingFunds.count == 0 ? 150 : 0
        
    }
    
    
    // create some cells for the rows
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // this will return a UITableViewCell
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! MissingFundsCell
        cell.selectionStyle = .none
        
        let missingFund: MissingFund
        missingFund = missingFunds[indexPath.row]
        cell.missingFund = missingFund
        
        
        
        return cell
}
//    // height of each cell
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 95
//    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    // add some rows to the tableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        missingFunds.count
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (_, indexPath) in
            // get file you are swiping on to get delete action
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let deleteAction = UIAlertAction(title: "Delete Missing Funds", style: .destructive) { (action) in
               
                let itemId = self.missingFunds[indexPath.row].id
                let missingFundsToBeDeleted = self.missingFunds[indexPath.row].missingFunds ?? 0.0
                self.missingFunds.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                
                self.db.collection("Users").document(uid).collection("Files").document((itemId)!).updateData([
                    "missingFunds": FieldValue.delete(),
                    "missingFundsSwitch": FieldValue.delete(),
                ]) { err in
                    if let err = err {
                        self.showError(title: "Something went wrong", message: "Unable to delete missing funds. \(err)")
                        print("Error updating document: \(err)")
                    } else {
                        print("sending over \(missingFundsToBeDeleted)")
                        self.updateMissingFundsTotalInFile(missingFundsId: itemId!, missingFunds: missingFundsToBeDeleted)
                    }
                }
                
                // refresh the balance remaining label
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.viewWillAppear(true)
                }
            }
            // alert
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            optionMenu.addAction(deleteAction)
            optionMenu.addAction(cancelAction)
            self.present(optionMenu, animated: true, completion: nil)
           
            
        }
        // change color of delete button
        deleteAction.backgroundColor = UIColor.lightRed
        return [deleteAction]
    }
    
    
}

