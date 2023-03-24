//
//  TeamFileDetails+UITableView.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/19/23.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
// this file will hold all my tableView delegate functions
extension TeamFileDetailsController {
    
    // creates style of header
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = IndentedLabel()
        if section == 0 {
            label.text = "Insurance Checks Received"
        } else if section == 1 {
            label.text = "Insurance Checks Received & Collected"
        } else if section == 2 {
            label.text = "Personal Checks Collected"
        } else if section == 3 {
            label.text = "ACV Owed to Homeowner"
        } else if section == 4 {
            label.text = "RCV Work to do"
        } else if section == 5 {
            label.text = "Cash Work to do"
        } else if section == 6 {
            label.text = "Credit"
        }
        
        label.backgroundColor = UIColor.darkBlue
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)

        return label
    }


    // creates height of header
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    // creates header
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewItems.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: itemCellId, for: indexPath)
        // check employee based on which section they are in
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

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    // add some rows to the tableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems[section].count
    }

    
}

