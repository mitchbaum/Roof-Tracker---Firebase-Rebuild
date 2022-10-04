//
//  ItemsController+UITableView.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 5/23/22.
//

import UIKit
import FirebaseAuth
// this file will hold all my tableView delegate functions
extension ItemsController {
    // creates style of header
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = IndentedLabel()
        // make headers refelct what goes information goes into the sections
        print("section = ", section)

        if section == 0 {
            label.text = "Insurance Checks Recieved"
        } else if section == 1 {
            label.text = "Insurance Checks Recieved and Paid"
        } else if section == 2 {
            label.text = "Personal Checks Paid"
        } else if section == 3 {
            label.text = "ACV Owed to Homeowner"
        } else if section == 4 {
            label.text = "RCV Work to do"
        } else {
            label.text = "Cash Work to do"
        }
        

        label.backgroundColor = UIColor.darkBlue
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)



        return label
    }
    
    // creates header
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewItems.count
    }
    
    // creates height of header
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    // get employees to show up in tableView for the file selected
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems[section].count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: itemCellId, for: indexPath)
        // check employee based on which section they are in
        // print names in cell
        // if we are section 0 we will use all employees at 0 (shortnameEmployees) and we will select correct indexPath row
        let item = tableViewItems[indexPath.section][indexPath.row]

        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current

        if var date = item.checkDate, let amount = Double(item.checkAmount ?? "") {
            let checkCell = tableView.dequeueReusableCell(withIdentifier: "CheckTableViewCell", for: indexPath) as! CheckTableViewCell
            let shortAmount = currencyFormatter.string(from: NSNumber(value: amount))
            if item.name == "" {
                checkCell.myCheckNumberLabel?.text = " "
            } else {
                checkCell.myCheckNumberLabel?.text = "\(item.name ?? "")"
            }
            checkCell.myCheckAmountLabel?.text = shortAmount
            if date.count == 4 {
                date = date + "2022"
            }
            print("date = ", date)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMddyyyy"
            let checkDateFormat = dateFormatter.date(from: date)
            if date != "" {
                let anotherDateformatter = DateFormatter()
                anotherDateformatter.dateFormat = "MMM dd, yyyy"
                let checkDateString = "\(anotherDateformatter.string(from: checkDateFormat!))"
                if checkDateString == "Jan 01, 2000" {
                    checkCell.myCheckDateLabel?.text = " "
                } else {
                    checkCell.myCheckDateLabel?.text = checkDateString
                }
            } else {
                checkCell.myCheckDateLabel?.text = " "
            }
            let checkType = item.type
            if checkType == "Insurance PAID" {
                checkCell.myPaidLabel.text = "PAID"
                checkCell.myPaidLabel.textColor = .lightRed
            } else {
                checkCell.myPaidLabel.text = ""
            }

            checkCell.selectionStyle = UITableViewCell.SelectionStyle.none
            return checkCell


        } else if let lineNumber = item.lineNumber, let amount = Double(item.linePrice ?? "") {
            // this is for all work to do
            let lineItemCell = tableView.dequeueReusableCell(withIdentifier: "LineItemTableViewCell", for: indexPath) as! LineItemTableViewCell
            let shortAmount = currencyFormatter.string(from: NSNumber(value: amount))
            lineItemCell.myLineItemLabel?.text = "\(item.name ?? " ")"
            lineItemCell.myPriceLabel?.text = shortAmount
            if lineNumber == "" {
                lineItemCell.myLineNumberLabel?.text = " "
            }
            lineItemCell.myLineNumberLabel?.text = "\(lineNumber)"
            lineItemCell.myNotesTextView?.text = "\(item.lineNote ?? "None")"
            lineItemCell.selectionStyle = UITableViewCell.SelectionStyle.none
            return lineItemCell
        }
        


        return cell
    }
    
    // delete file from tableView and coredata
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (_, indexPath) in
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let itemId = self.tableViewItems[indexPath.section][indexPath.row].id
            self.tableViewItems[indexPath.section].remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            
            self.db.collection("Users").document(uid).collection("Files").document((self.file?.id)!).collection("FileInformation").document(itemId!).delete()
            
            // refresh the balance remaining label
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.viewWillAppear(true)
            }
            
           
        }
        // change color of delete button
        deleteAction.backgroundColor = UIColor.lightRed
        
        // perform edit action
        let editAction = UITableViewRowAction(style: .normal , title: "Edit", handler: editHandlerFunction)
        // change color of edit button
        editAction.backgroundColor = UIColor.darkBlue

        // this puts the action buttons in the row the user swipes so user can actually see the buttons to delete or edit
        return [deleteAction, editAction]
    }
    
    // edit line item
    func editHandlerFunction(action: UITableViewRowAction, indexPath: IndexPath) {
        print("Editing line item")
        // get the item user tapped "edit" button for
        let item = self.tableViewItems[indexPath.section][indexPath.row]
        
        // check item to see if its a check or line item
        if item.type == "Insurance" || item.type == "Insurance PAID" || item.type == "Personal" {
            // pop up modal that displays information about the selected check
            let editCheckController = CreateCheckController()
            // this allows the editCheckController() class to know which row the user tapped on and where to go in coredata to find the data at that specific row
            editCheckController.delegate = self
            // this basically says "editCheckController() class assign itemInformation as the data needed for this item i just tapped on because checkData and checkAmount variables are located in itemInformation in coredata"
            editCheckController.itemInformation = item


            let navController = CustomNavigationController(rootViewController: editCheckController)
//            print("item = ", item)
//            print("checkAmount = ", item.itemInformation)
            present(navController, animated: true, completion: nil)
        } else {
            let editLineItemController = CreateLineItemController()
            editLineItemController.delegate = self
            editLineItemController.itemInformation = item
            let navController = CustomNavigationController(rootViewController: editLineItemController)
            present(navController, animated: true, completion: nil)
        }
        
        
    }
    
}
