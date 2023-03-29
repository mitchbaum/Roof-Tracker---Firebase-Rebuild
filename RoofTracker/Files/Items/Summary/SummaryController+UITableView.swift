//
//  SummaryController+UITableView.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 5/24/22.
//

import UIKit
import FirebaseAuth
// this file will hold all my tableView delegate functions
extension SummaryController {
    // creates style of header
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        
        let label = IndentedLabelSummary()
        // make headers refelct what goes information goes into the sections
        let insChecksRecievedTotalFormat = currencyFormatter.string(from: NSNumber(value: insChecksRecievedTotal))
        let ACVOwedToHOTotalFormat = currencyFormatter.string(from: NSNumber(value: ACVOwedToHOTotal))

        if section == 0 {
            label.text = "Insurance Payments Recieved by Homeowner\n\(insChecksRecievedTotalFormat ?? "$0.00")"
        } else  {
            label.text = "ACV of Work Not Completed\n\(ACVOwedToHOTotalFormat ?? "$0.00")"
        }

        label.backgroundColor = UIColor.darkBlue
        label.textColor = UIColor.white
        //label.font = UIFont.boldSystemFont(ofSize: 16)
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakMode.byWordWrapping



        return label
    }

    // creates height of header
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // creates header
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewItems.count
    }
    
    // get items to show up in tableView for the file selected
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: itemCellId, for: indexPath)
        // check employee based on which section they are in
        // print names in cell
        // if we are section 0 we will use all employees at 0 (shortnameEmployees) and we will select correct indexPath row
        let item = tableViewItems[indexPath.section][indexPath.row]
//        cell.textLabel?.text = item.name
//        cell.textLabel?.text = "\(item.name ?? "") - Check Amount:  \(item.itemInformation?.checkDate ?? nil)"
        
//        let lineItem = allLineItems[indexPath.section][indexPath.row]
//        cell.textLabel?.text = lineItem.name
        // print check date in cell
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current

        if let date = item.checkDate, let amount = Double(item.checkAmount ?? " ") {
            let checkCell = tableView.dequeueReusableCell(withIdentifier: "InsuranceCheckCell", for: indexPath) as! InsuranceCheckCell
            checkCell.myCheckNumberLabel?.text = "#\(item.name ?? "")"
            let shortAmount = currencyFormatter.string(from: NSNumber(value: amount))
            checkCell.myCheckAmountLabel?.text = shortAmount
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMddyyyy"
            var checkDateString = ""
            if date != "" {
                let anotherDateformatter = DateFormatter()
                anotherDateformatter.dateFormat = "MMM dd, yyyy"
                if date.count == 4 {
                    let checkDateFormat = dateFormatter.date(from: date + "2023")
                    checkDateString = "\(anotherDateformatter.string(from: checkDateFormat!))"
                } else if date.count == 8 {
                    let checkDateFormat = dateFormatter.date(from: date)
                    checkDateString = "\(anotherDateformatter.string(from: checkDateFormat!))"
                }
                if checkDateString == "Jan 01, 2000" {
                    checkCell.myCheckDateLabel?.text = " "
                } else {
                    checkCell.myCheckDateLabel?.text = checkDateString
                }
            } else {
                checkCell.myCheckDateLabel?.text = " "
            }
            checkCell.selectionStyle = UITableViewCell.SelectionStyle.none
            return checkCell
                
            
        } else if let lineNumber = item.lineNumber, let amount = Double(item.linePrice ?? " ") {
            // this is for all work to do
            let lineItemCell = tableView.dequeueReusableCell(withIdentifier: "ACVItemCell", for: indexPath) as! ACVItemCell
            let shortAmount = currencyFormatter.string(from: NSNumber(value: amount))
            lineItemCell.myLineItemLabel?.text = "\(item.name ?? " ")"
            lineItemCell.myPriceLabel?.text = shortAmount
            lineItemCell.myLineNumberLabel?.text = "Line #\(lineNumber)"
            lineItemCell.selectionStyle = UITableViewCell.SelectionStyle.none
            return lineItemCell
        }

        return cell
    }
}


