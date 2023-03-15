//
//  SummaryController.swift
//  PaymentTracker
//
//  Created by Mitch Baumgartner on 4/1/21.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase
import SwiftUI
import LBTATools
import JGProgressHUD


// this controller creates a view controller for creating an employee when user taps plus button
class SummaryController: UITableViewController {
    var filesCollectionRef: CollectionReference!
    let db = Firestore.firestore()
    
    let itemCellId = "itemCellId"
    
    var file: FB_File? // File? (optional) means it can start as nil
    // an array of arrays of employees
    var allItems = [[FileItem]]()
    var FB_allItems = [FB_ItemInformation]()
    var tableViewItems = [[FB_ItemInformation]]()
    
    var insChecksRecievedTotal = 0.0
    var ACVOwedToHOTotal = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFileItems()
        tableView.backgroundColor = UIColor.darkBlue
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 2
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: itemCellId)
        // title
        navigationItem.title = file?.name
        navigationController?.transparentNavigationBar()
        navigationController?.setTintColor(.white)
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        setupUI()
        getSummaryValues()
        
        tableView.separatorColor = .darkBlue
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleDone))
        // create new custom cell for insurance check table view
        let nib_insCheck = UINib(nibName: "InsuranceCheckCell", bundle: nil)
        tableView.register(nib_insCheck, forCellReuseIdentifier: "InsuranceCheckCell")
        // create new custom cell for line item table view
        let nib_lineItem = UINib(nibName: "ACVItemCell", bundle: nil)
        tableView.register(nib_lineItem, forCellReuseIdentifier: "ACVItemCell")

    }
    
    func fetchFileItems() {
        FB_allItems = []
        print("Fetching files from Firebase")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        filesCollectionRef = db.collection("Users").document(uid).collection("Files").document((file?.id)!).collection("FileInformation")
        filesCollectionRef.getDocuments { (snapshot, error) in
            if let err = error {
                debugPrint("Error fetching files: \(err)")
            } else {
                guard let snap = snapshot else { return }
                for document in snap.documents {
                    let data = document.data()
                    let checkId = data["id"] as? String ?? ""
                    let itemName = data["itemName"] as? String ?? ""
                    let itemType = data["itemType"] as? String ?? ""
                    let checkDate = data["checkDate"] as? String ?? ""
                    let checkAmount = data["checkAmount"] as? String ?? ""
                    let lineNumber = data["lineNumber"] as? String ?? ""
                    let itemPrice = data["linePrice"] as? String ?? ""
                    let lineNote = data["lineNote"] as? String ?? ""
                    let fileId = data["fileId"] as? String ?? ""
                    
                    let newItem = FB_ItemInformation(id: checkId, checkAmount: checkAmount, checkDate: checkDate,  lineNote: lineNote, lineNumber: lineNumber, linePrice: itemPrice, name: itemName, timeStamp: checkDate, type: itemType, fileId: fileId)
                    self.FB_allItems.append(newItem)
                    
                }
                self.fetchItems()
            }
        }
    }
    
    // fetch FileInformation for each file when user taps on file
    private func fetchItems() {
        // filter senior management for "Executives"
        var insChecksRecieved = FB_allItems.filter { (item) -> Bool in
            return item.type == "Insurance" || item.type == "Insurance PAID"
        }
        // filter senior management for "Executives"
        var ACVtoHO = FB_allItems.filter { (item) -> Bool in
            return item.type == "ACV owed to HO"
        }
        

        for item in insChecksRecieved {
            insChecksRecievedTotal += Double(item.checkAmount ?? "") ?? 0.0
        }
        for item in ACVtoHO {
            ACVOwedToHOTotal += Double(item.linePrice ?? "") ?? 0.0
            
        }

        

        // sort the rows in each section by time added to itemsController
        insChecksRecieved.sort(by: {$0.timeStamp! > $1.timeStamp!})
        ACVtoHO.sort(by: {$0.timeStamp! > $1.timeStamp!})

        tableViewItems = [
            insChecksRecieved,
            ACVtoHO,
        ]
        tableView.reloadData()

    }
    

    
    private func getSummaryValues() {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current

        // make date show up pretty in cell by unwrapping name and founded property
        if let insCheckACVTotal = Double(file?.insCheckACVTotal ?? ""), let coc = Double(file?.coc ?? ""), let deductible = Double(file?.deductible ?? ""), let insChecksTotal = Double(file?.insCheckTotal ?? ""), let acvItemTotal = Double(file?.acvItemTotal ?? "") {
            let moneyOwedToHO = coc + insCheckACVTotal - deductible
            let amountOwed = currencyFormatter.string(from: NSNumber(value: moneyOwedToHO))
            insStillOwesHOLabelInfo.text = amountOwed


            let totalInsChecks = currencyFormatter.string(from: NSNumber(value: insChecksTotal + moneyOwedToHO))
            insChecksShouldEqualLabelInfo.text = totalInsChecks
            totalLabelInfo.text = totalInsChecks

            let cocTotal = currencyFormatter.string(from: NSNumber(value: coc))
            cocLabelInfo.text = cocTotal

            let acvTotal = currencyFormatter.string(from: NSNumber(value: acvItemTotal))
            acvLabelInfo.text = acvTotal

            let deductibleTotal = currencyFormatter.string(from: NSNumber(value: deductible))
            deductibleLabelInfo.text = "-\(deductibleTotal ?? "")"

//            let insTotal = currencyFormatter.string(from: NSNumber(value: insChecksTotal))
//            insChecksLabelInfo.text = insTotal
        } else if let deductible = Double(file?.deductible ?? "") {
            let deductibleTotal = currencyFormatter.string(from: NSNumber(value: deductible))
            deductibleLabelInfo.text = "-\(deductibleTotal ?? "")"
            totalLabelInfo.text = "-\(deductibleTotal ?? "")"
        } else if let coc = Double(file?.coc ?? "") {
            let cocTotal = currencyFormatter.string(from: NSNumber(value: coc))
            cocLabelInfo.text = cocTotal
            totalLabelInfo.text = "-\(cocTotal ?? "")"
        }
        else {
            insStillOwesHOLabelInfo.text = "Not available"
            insChecksShouldEqualLabelInfo.text = "Not available"
        }

        if file?.acvItemTotal == "0.0"{
            acvLabelInfo.text = "No entry"
        } else if file?.acvItemTotal != "" && file?.deductible != "" && file?.coc != "" {
            let acvItemTotal = Double(file?.acvItemTotal ?? "")
            let acvTotal = currencyFormatter.string(from: NSNumber(value: acvItemTotal ?? 0.0))
            acvLabelInfo.text = acvTotal

            let deductible = Double(file?.deductible ?? "")
            let deductibleTotal = currencyFormatter.string(from: NSNumber(value: deductible ?? 0.0))
            deductibleLabelInfo.text = "-\(deductibleTotal ?? "")"

            let coc = Double(file?.coc ?? "")
            let cocTotal = currencyFormatter.string(from: NSNumber(value: coc ?? 0.0))
            cocLabelInfo.text = cocTotal

            let total = (coc ?? 0.0) + (acvItemTotal ?? 0.0) - (deductible ?? 0.0)
            let totalFormatted = currencyFormatter.string(from: NSNumber(value: total))
            totalLabelInfo.text = totalFormatted

        }else if file?.acvItemTotal != "" && file?.deductible != "" {
            let acvItemTotal = Double(file?.acvItemTotal ?? "")
            let acvTotal = currencyFormatter.string(from: NSNumber(value: acvItemTotal ?? 0.0))
            acvLabelInfo.text = acvTotal

            let deductible = Double(file?.deductible ?? "")
            let deductibleTotal = currencyFormatter.string(from: NSNumber(value: deductible ?? 0.0))
            deductibleLabelInfo.text = "-\(deductibleTotal ?? "")"
            let total = (acvItemTotal ?? 0.0) - (deductible ?? 0.0)
            let totalFormatted = currencyFormatter.string(from: NSNumber(value: total))
            totalLabelInfo.text = totalFormatted
        } else if file?.acvItemTotal != "" {
            let acvItemTotal = Double(file?.acvItemTotal ?? "")
            let acvTotal = currencyFormatter.string(from: NSNumber(value: acvItemTotal ?? 0.0))
            acvLabelInfo.text = acvTotal
        }


    }
    
    // create work item name label
    let insStillOwesHOLabel: UILabel = {
        let label = UILabel()
        label.text = "Insurance Still Owes Homeowner:"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create info for amount owed to HO
    let insStillOwesHOLabelInfo: UILabel = {
        let label = UILabel()
        label.text = "Not available"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 20.0)
        label.textColor = .white
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create work item name label
    let insChecksShouldEqualLabel: UILabel = {
        let label = UILabel()
        label.text = "Insurance Checks Issued SHOULD Equal:"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create info for amount owed to HO
    let insChecksShouldEqualLabelInfo: UILabel = {
        let label = UILabel()
        label.text = "Not available"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 20.0)
        label.textColor = .white
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // because label
    let becauseLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = "Because..."
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // coc label
    let cocLabel: UILabel = {
        let label = UILabel()
        label.text = "COC"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // coc info label
    let cocLabelInfo: UILabel = {
        let label = UILabel()
        label.text = "No entry"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // acv label
    let acvLabel: UILabel = {
        let label = UILabel()
        label.text = "ACV"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // acv info label
    let acvLabelInfo: UILabel = {
        let label = UILabel()
        label.text = "No entry"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // deductible label
    let deductibleLabel: UILabel = {
        let label = UILabel()
        label.text = "Deductible"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // deductinble info label
    let deductibleLabelInfo: UILabel = {
        let label = UILabel()
        label.text = "No entry"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
//    // all insurance checks label
//    let insChecksLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Insurance Checks Recieved"
//        label.textColor = .white
//        // label.backgroundColor = .red
//        // enable autolayout
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    // all insurance checks info label
//    let insChecksLabelInfo: UILabel = {
//        let label = UILabel()
//        label.text = "$0.00"
//        label.textColor = .white
//        // label.backgroundColor = .red
//        // enable autolayout
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
    
    // equation line
    let line: UILabel = {
        let line = UILabel()
        line.backgroundColor = UIColor.white
        // enable autolayout
        line.translatesAutoresizingMaskIntoConstraints = false
    
        return line
    }()
    
    // Total label
    let totalLabel: UILabel = {
        let label = UILabel()
        label.text = "Total"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // total info label
    let totalLabelInfo: UILabel = {
        let label = UILabel()
        label.text = "Not available"
        label.textColor = .white
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let line2: UILabel = {
        let line = UILabel()
        line.backgroundColor = .lightRed
        // enable autolayout
        line.translatesAutoresizingMaskIntoConstraints = false
    
        return line
    }()
    
    private func setupUI() {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 233))
        

        let headerView = UILabel(frame: header.bounds)
        //headerView.backgroundColor = .lightBlue
        header.addSubview(headerView)
        
        // add and position item name label
        header.addSubview(insStillOwesHOLabel)
        insStillOwesHOLabel.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
        // move label to the right a bit
        insStillOwesHOLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 16).isActive = true
//        insStillOwesHOLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        insStillOwesHOLabel.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true
        insStillOwesHOLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true

        header.addSubview(insStillOwesHOLabelInfo)
        insStillOwesHOLabelInfo.topAnchor.constraint(equalTo: insStillOwesHOLabel.bottomAnchor).isActive = true
        insStillOwesHOLabelInfo.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 16).isActive = true
        insStillOwesHOLabelInfo.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true

        header.addSubview(insChecksShouldEqualLabel)
        insChecksShouldEqualLabel.topAnchor.constraint(equalTo: insStillOwesHOLabelInfo.bottomAnchor).isActive = true
        insChecksShouldEqualLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 16).isActive = true
        insChecksShouldEqualLabel.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true
        insChecksShouldEqualLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true

        header.addSubview(insChecksShouldEqualLabelInfo)
        insChecksShouldEqualLabelInfo.topAnchor.constraint(equalTo: insChecksShouldEqualLabel.bottomAnchor).isActive = true
        insChecksShouldEqualLabelInfo.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 16).isActive = true
        insChecksShouldEqualLabelInfo.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true

        header.addSubview(becauseLabel)
        becauseLabel.topAnchor.constraint(equalTo: insChecksShouldEqualLabelInfo.bottomAnchor, constant: 5).isActive = true
        becauseLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 16).isActive = true
        becauseLabel.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true
        becauseLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true

        header.addSubview(cocLabel)
        cocLabel.topAnchor.constraint(equalTo: becauseLabel.topAnchor).isActive = true
        cocLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 210).isActive = true
        cocLabel.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true
        cocLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true

        header.addSubview(cocLabelInfo)
        cocLabelInfo.rightAnchor.constraint(equalTo: header.rightAnchor, constant: -24).isActive = true
        cocLabelInfo.topAnchor.constraint(equalTo: cocLabel.topAnchor).isActive = true
        cocLabelInfo.bottomAnchor.constraint(equalTo: cocLabel.bottomAnchor).isActive = true

        header.addSubview(acvLabel)
        acvLabel.topAnchor.constraint(equalTo: cocLabel.bottomAnchor).isActive = true
        acvLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 210).isActive = true
        acvLabel.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true
        acvLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true

        header.addSubview(acvLabelInfo)
        acvLabelInfo.rightAnchor.constraint(equalTo: header.rightAnchor, constant: -24).isActive = true
        acvLabelInfo.topAnchor.constraint(equalTo: acvLabel.topAnchor).isActive = true
        acvLabelInfo.bottomAnchor.constraint(equalTo: acvLabel.bottomAnchor).isActive = true

        header.addSubview(deductibleLabel)
        deductibleLabel.topAnchor.constraint(equalTo: acvLabel.bottomAnchor).isActive = true
        deductibleLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 164).isActive = true
        deductibleLabel.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true
        deductibleLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true

        header.addSubview(deductibleLabelInfo)
        deductibleLabelInfo.rightAnchor.constraint(equalTo: header.rightAnchor, constant: -24).isActive = true
        deductibleLabelInfo.topAnchor.constraint(equalTo: deductibleLabel.topAnchor).isActive = true
        deductibleLabelInfo.bottomAnchor.constraint(equalTo: deductibleLabel.bottomAnchor).isActive = true

//        header.addSubview(insChecksLabel)
//        insChecksLabel.topAnchor.constraint(equalTo: deductibleLabel.bottomAnchor).isActive = true
//        insChecksLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 38).isActive = true
//        insChecksLabel.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true
//        insChecksLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
//
//        header.addSubview(insChecksLabelInfo)
//        insChecksLabelInfo.rightAnchor.constraint(equalTo: header.rightAnchor, constant: -24).isActive = true
//        insChecksLabelInfo.topAnchor.constraint(equalTo: insChecksLabel.topAnchor).isActive = true
//        insChecksLabelInfo.bottomAnchor.constraint(equalTo: insChecksLabel.bottomAnchor).isActive = true

        header.addSubview(line)
        line.rightAnchor.constraint(equalTo: header.rightAnchor, constant: -22).isActive = true
        line.topAnchor.constraint(equalTo: deductibleLabelInfo.bottomAnchor, constant: 5).isActive = true
        line.heightAnchor.constraint(equalToConstant: 2).isActive = true
        line.widthAnchor.constraint(equalToConstant: 100).isActive = true

        header.addSubview(totalLabel)
        totalLabel.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 5).isActive = true
        totalLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 210).isActive = true
        totalLabel.rightAnchor.constraint(equalTo: header.rightAnchor).isActive = true
        totalLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true

        header.addSubview(totalLabelInfo)
        totalLabelInfo.rightAnchor.constraint(equalTo: header.rightAnchor, constant: -24).isActive = true
        totalLabelInfo.topAnchor.constraint(equalTo: totalLabel.topAnchor).isActive = true
        totalLabelInfo.bottomAnchor.constraint(equalTo: totalLabel.bottomAnchor).isActive = true
        
        header.addSubview(line2)
        line2.rightAnchor.constraint(equalTo:header.rightAnchor, constant: -16).isActive = true
        line2.topAnchor.constraint(equalTo: totalLabelInfo.bottomAnchor, constant: 8).isActive = true
        line2.heightAnchor.constraint(equalToConstant: 1).isActive = true
        line2.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 16).isActive = true

        
        tableView.tableHeaderView = header
        print("label should appear...")

    }
    
    @objc func handleDone() {
        dismiss(animated: true, completion: nil)
    }
    
    
    // create UILabel subclass for custom text drawing - usually for my headers
    class IndentedLabelSummary: UILabel {
        override func drawText(in rect: CGRect) {
            let insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
            let customRect = rect.inset(by: insets)
            super.drawText(in: customRect)
        }
    }
    
    class IndentedLabelSummary2: UILabel {
        override func drawText(in rect: CGRect) {
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
            let customRect = rect.inset(by: insets)
            super.drawText(in: customRect)
        }
    }
    
}

