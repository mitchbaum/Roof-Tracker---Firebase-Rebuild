//
//  TeamFileDetails.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/19/23.
//

import UIKit
import CoreData
import FirebaseAuth
import Firebase
import FirebaseDatabase
import SwiftUI
import LBTATools
import JGProgressHUD


class TeamFileDetailsController: UITableViewController {

    var teamMember: TeamMember?
    var file: FB_File?
    var itemInformation: FB_ItemInformation?
    let db = Firestore.firestore()
    
    var FB_allItems = [FB_ItemInformation]()
    var tableViewItems = [[FB_ItemInformation]]()
    
    let itemCellId = "itemCellId"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        fetchFileItems()
    }
    
    // this function controls how the controller is styled
    override func viewDidLoad() {
        super.viewDidLoad()
        //fetchInsToHOTotal()
        // title
        navigationItem.title = file?.name
        navigationController?.transparentNavigationBar()
        navigationController?.setTintColor(.white)
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        tableView.backgroundColor = UIColor.darkBlue
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: itemCellId)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleDone))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Sales's Rep: \(teamMember?.name ?? "")", style: .plain, target: self, action: nil)
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        // get the note first before UI is built and before table rows are built.
        noteLabelInfo.text = file?.note
        
        setupUI()
        
        // create new custom cell for insurance check table view
        let nib_insCheck = UINib(nibName: "CheckTableViewCell", bundle: nil)
        tableView.register(nib_insCheck, forCellReuseIdentifier: "CheckTableViewCell")
        // create new custom cell for line item table view
        let nib_lineItem = UINib(nibName: "LineItemTableViewCell", bundle: nil)
        tableView.register(nib_lineItem, forCellReuseIdentifier: "LineItemTableViewCell")
        // refresh the balance remaining label
        viewWillAppear(true)

    }
    
    func getSummaryValues() {
        print("in getSummaryValues")
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        // make date show up pretty in cell by unwrapping name and founded property
        if let coc = Double(file?.coc ?? ""), let deductible = Double(file?.deductible ?? "") {
            let cocMessage = currencyFormatter.string(from: NSNumber(value: coc))
            cocTotalLabelInfo.text = cocMessage
            let credit = Double(file?.creditItemTotal ?? "")
            let cocMinusCredit = coc - (credit ?? 0.0)
            let invoiceMessage = currencyFormatter.string(from: NSNumber(value: cocMinusCredit))
            invoiceTotalLabelInfo.text = invoiceMessage
            let deductibleMessage = currencyFormatter.string(from: NSNumber(value: deductible))
            deductibleTotalLabelInfo.text = deductibleMessage
            let cashTotal = Double(file?.cashItemTotal ?? "")
            let pymtsMade = Double(file?.pymtCheckTotal ?? "")
            let whatsDue = coc + (cashTotal ?? 0.00) - (pymtsMade ?? 0.00) - (credit ?? 0.0)
            let whatsDueMessage = currencyFormatter.string(from: NSNumber(value: whatsDue))
            invoiceBalanceTotalLabelInfo.text = whatsDueMessage
            

            
            
        } else if Double(file?.deductible ?? "") != nil  {
            cocTotalLabelInfo.text = ""
            if file?.coc != "" {
                let coc = Double(file?.coc ?? "")
                let cocMessage = currencyFormatter.string(from: NSNumber(value: coc ?? 0.00))
                cocTotalLabelInfo.text = cocMessage
            }
            
            // invoice and coc are the same unless there's credit applied
            invoiceTotalLabelInfo.text = ""
            if file?.coc != "" {
                let invoice = Double(file?.coc ?? "")
                let invoiceMessage = currencyFormatter.string(from: NSNumber(value: invoice ?? 0.00))
                invoiceTotalLabelInfo.text = invoiceMessage
            }
            
            deductibleTotalLabelInfo.text = ""
            if file?.deductible != "" {
                let deductible = Double(file?.deductible ?? "")
                let deductibleMessage = currencyFormatter.string(from: NSNumber(value: deductible ?? 0.00))
                deductibleTotalLabelInfo.text = deductibleMessage
            }
            
        } else if Double(file?.coc ?? "") != nil {
            cocTotalLabelInfo.text = ""
            if file?.coc != "" {
                let coc = Double(file?.coc ?? "")
                let cocMessage = currencyFormatter.string(from: NSNumber(value: coc ?? 0.00))
                cocTotalLabelInfo.text = cocMessage
                // set invoice label
                let invoice = Double(file?.coc ?? "")
                let invoiceMessage = currencyFormatter.string(from: NSNumber(value: invoice ?? 0.00))
                invoiceTotalLabelInfo.text = invoiceMessage
                deductibleTotalLabelInfo.text = file?.deductible
            }

            
        }
        else {
            cocTotalLabelInfo.text = ""
            invoiceTotalLabelInfo.text = ""
            deductibleTotalLabelInfo.text = ""
        }
        
        // this handles the RCV total section
        // print empty label to summary section
        rcvTotalLabelInfo.text = ""
        // if there has been an entered item, but deleted this will handle the making the label empty
        if file?.rcvItemTotal == "0.0" || file?.rcvItemTotal == "0"{
            rcvTotalLabelInfo.text = ""
        } else if file?.rcvItemTotal != "" { // else there is a number entered
            let rcv = Double(file?.rcvItemTotal ?? "")
            let rcvMessage = currencyFormatter.string(from: NSNumber(value: rcv ?? 0.0))
            rcvTotalLabelInfo.text = rcvMessage
        }
        
        // this handles the out of pocket label
        outOfPocketLabelInfo.text = ""
        if file?.deductible == "" {
            outOfPocketLabelInfo.text = ""
            outOfPocketLabel.text = "Enter a deductible to calulate the customer's out of pocket total."
        } else if file?.acvItemTotal == "0.0" || file?.acvItemTotal == "0" {
            let deductible = Double(file?.deductible ?? "")
            let deductibleMessage = currencyFormatter.string(from: NSNumber(value: deductible ?? 0.0))
            outOfPocketLabelInfo.text = deductibleMessage
            oopFlagMessage.text = "Your customer will owe their deductible when all insurance proceeds are paid."
        } else if file?.acvItemTotal != "" {
            let acv = Double(file?.acvItemTotal ?? "")
            let deductible = Double(file?.deductible ?? "")
            let oop = (deductible ?? 0.0) - (acv ?? 0.0)
            outOfPocketLabelInfo.text = currencyFormatter.string(from: NSNumber(value: oop))
            let oopMessage = currencyFormatter.string(from: NSNumber(value: abs(oop)))
            if oop < 0.0 {
                oopFlagMessage.text = "🎉 Your customer will get \(oopMessage ?? "_") back when all insurance proceeds are paid."
                oopFlagMessage.textColor = .systemGreen
            } else if oop > 0 {
                oopFlagMessage.text = "Your customer will owe \(oopMessage ?? "_") after all insurance proceeds are paid."
            }
            
        }
        
        creditLabelInfo.text = ""
        // if there has been an entered item, but deleted this will handle the making the label empty
        if file?.creditItemTotal == "0.0" || file?.creditItemTotal == "0"{
            creditLabelInfo.text = ""
            creditLabel.textColor = UIColor.white
            invoiceTotalLabel.text = "Invoice Total"
        } else if file?.creditItemTotal != "" {
            let credit = Double(file?.creditItemTotal ?? "")
            let creditMessage = currencyFormatter.string(from: NSNumber(value: credit ?? 0.0))
            creditLabelInfo.text = creditMessage
            creditLabelInfo.textColor = UIColor.lightRed
            creditLabel.textColor = UIColor.lightRed
            invoiceTotalLabel.text = "Invoice Total (COC - Credit)"
        }
        
    }
    
    
    func fetchFileItems() {
        FB_allItems = []
        print("Fetching files from Firebase")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Users").document((teamMember?.id)!).collection("Files").document((file?.id)!).collection("FileInformation").getDocuments { (snapshot, error) in
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
                    
                    let newItem = FB_ItemInformation(id: checkId, checkAmount: checkAmount, checkDate: checkDate, lineNote: lineNote, lineNumber: lineNumber, linePrice: itemPrice, name: itemName, timeStamp: checkDate, type: itemType, fileId: fileId)
                    self.FB_allItems.append(newItem)
                    
                }
                self.fetchInsToHOTotal()
                self.fetchItems()
            }
        }
    }
    
    func fetchInsToHOTotal() {
        tableView.reloadData()
        var insCheckTotal = 0.0
        var ACVItemTotal = 0.0
        var cashItemTotal = 0.0
        var pymtCheckTotal = 0.0
        var RCVItemTotal = 0.0
        var CreditItemTotal = 0.0
        for item in FB_allItems {
            if item.type! == "Insurance" || item.type! == "Insurance PAID" {
                let checkAmount = Double(item.checkAmount ?? "")
                insCheckTotal += checkAmount ?? 0.0

            }
            else if item.type! == "ACV owed to HO" {
                let itemAmount = Double(item.linePrice ?? "")
                ACVItemTotal += itemAmount ?? 0.0

            }
            else if item.type! == "Cash work to do" {
                let itemAmount = Double(item.linePrice ?? "")
                cashItemTotal += itemAmount ?? 0.0
            }
            else if item.type! == "RCV work to do" {
                let itemAmount = Double(item.linePrice ?? "")
                RCVItemTotal += itemAmount ?? 0.0

            } else if item.type! == "Credit" {
                let itemAmount = Double(item.linePrice ?? "")
                CreditItemTotal += itemAmount ?? 0.0

            }
            if item.type! == "Personal" || item.type! == "Insurance PAID"{
                let checkAmount = Double(item.checkAmount ?? "")
                pymtCheckTotal += checkAmount ?? 0.0
            }
        }
        
        file?.insCheckTotal = String(insCheckTotal)
        file?.acvItemTotal = String(ACVItemTotal)
        file?.insCheckACVTotal = String(ACVItemTotal - insCheckTotal)
        file?.cashItemTotal = String(cashItemTotal)
        file?.pymtCheckTotal = String(pymtCheckTotal)
        file?.rcvItemTotal = String(RCVItemTotal)
        file?.creditItemTotal = String(CreditItemTotal)

        
        getSummaryValues()
        tableView.reloadData()

    }
    
    // fetch item cells for each file when user taps on file
    private func fetchItems() {
        // filter senior management for "Executives"
        var insChecksRecieved = FB_allItems.filter { (item) -> Bool in
            return item.type == "Insurance"
        }
        // filter staff for "Executives"
        var insChecksRecievedAndPaid = FB_allItems.filter { (item) -> Bool in
            return item.type == "Insurance PAID"
        }
        // filter staff for "Executives"
        var personalPaymentMade = FB_allItems.filter { (item) -> Bool in
            return item.type == "Personal"
        }
        // filter for insurance and paid
        // filter senior management for "Executives"
        var RCVworkToDo = FB_allItems.filter { (item) -> Bool in
            return item.type == "ACV owed to HO"
        }
        // filter staff for "Executives"
        var ACVtoHO = FB_allItems.filter { (item) -> Bool in
            return item.type == "RCV work to do"
        }
        // filter staff for "Executives"
        var cashToDo = FB_allItems.filter { (item) -> Bool in
            return item.type == "Cash work to do"
        }
        // filter staff for "Executives"
        let credit = FB_allItems.filter { (item) -> Bool in
            return item.type == "Credit"
        }
        // sort the rows in each section by time added to itemsController
        insChecksRecieved.sort(by: {$0.timeStamp! > $1.timeStamp! })
        insChecksRecievedAndPaid.sort(by: {$0.timeStamp! > $1.timeStamp!})
        personalPaymentMade.sort(by: {$0.timeStamp! > $1.timeStamp!})
        RCVworkToDo.sort(by: {$0.timeStamp! > $1.timeStamp!})
        ACVtoHO.sort(by: {$0.timeStamp! > $1.timeStamp!})
        cashToDo.sort(by: {$0.timeStamp! > $1.timeStamp!})
        

        tableViewItems = [
            insChecksRecieved,
            insChecksRecievedAndPaid,
            personalPaymentMade,
            RCVworkToDo,
            ACVtoHO,
            cashToDo,
            credit
        ]
        tableView.reloadData()
        
        
        
    }
    
    let missingFundsFlag: UIButton = {
        let button = UIButton()
        button.layer.borderColor = UIColor.lightRed.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 10, bottom: 3, right: 10)
        button.setTitle("Missing Funds", for: .normal)
        button.setTitleColor(.lightRed, for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // create button to send summary to office
    let summaryButton: UIButton = {
        let button = UIButton()

        button.backgroundColor = .lightRed
        button.setTitle("Show Summary", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(handleSummaryPopUp(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let finalCOCTotalLabel: UILabel = {
        let label = UILabel()
        //label.text = "Final COC Total"
        label.textColor = .white
        // underline label
        // Create a new Attributed String
        let attributedString = NSMutableAttributedString.init(string: "Final COC Total")
        // Add Underline Style Attribute.
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range:
            NSRange.init(location: 0, length: attributedString.length));
        label.attributedText = attributedString
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    // create file coc total label
    let cocTotalLabel: UILabel = {
        let label = UILabel()
        label.text = "COC Total"
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        return label
    }()
    
    // create file coc total entry
    let cocTotalLabelInfo: UILabel = {
        let label = UILabel()
        
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 16)
        label.textColor = .white
        return label
    }()
    
    // create file invoice total label
    let invoiceTotalLabel: UILabel = {
        let label = UILabel()
        label.text = "Invoice Total"
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        return label
    }()
    
    // create file invoice total entry
    let invoiceTotalLabelInfo: UILabel = {
        let label = UILabel()
        label.text = ""
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 16)
        label.textColor = .white
        return label
    }()
    
    // create file deductible total label
    let deductibleTotalLabel: UILabel = {
        let label = UILabel()
        label.text = "Deductible Total"
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        return label
    }()
    
    // create file deductible total entry
    let deductibleTotalLabelInfo: UILabel = {
        let label = UILabel()
        label.text = ""
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 16)
        label.textColor = .white
        return label
    }()
    
    // create invoice balance total label
    let invoiceBalanceTotalLabel: UILabel = {
        let label = UILabel()
        label.text = "Remaining Invoice \"What's Due\""
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        return label
    }()
    
    // create file deductible total entry
    let invoiceBalanceTotalLabelInfo: UILabel = {
        let label = UILabel()
        label.text = ""
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 16)
        label.textColor = .white
        return label
    }()
    
    // create RCV total label
    let rcvTotalLabel: UILabel = {
        let label = UILabel()
        label.text = "RCV Total"
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        return label
    }()
    
    // create file deductible total entry
    let rcvTotalLabelInfo: UILabel = {
        let label = UILabel()
        label.text = ""
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 16)
        label.textColor = .white
        return label
    }()
    
    let outOfPocketLabel: UILabel = {
        let label = UILabel()
        label.text = "Out of Pocket"
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        return label
    }()
    
    // create file deductible total entry
    let outOfPocketLabelInfo: UILabel = {
        let label = UILabel()
        label.text = ""
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 16)
        label.textColor = .white
        return label
    }()
    
    let oopFlagMessage: UILabel = {
        let label = UILabel()
        label.text = ""
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        return label
    }()
    
    let creditLabel: UILabel = {
        let label = UILabel()
        label.text = "Credit"
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        return label
    }()

    let creditLabelInfo: UILabel = {
        let label = UILabel()
        label.text = ""
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name:"HelveticaNeue-Bold", size: 16)
        label.textColor = .white
        return label
    }()
    
    let line: UILabel = {
        let line = UILabel()
        line.backgroundColor = .lightRed
        // enable autolayout
        line.translatesAutoresizingMaskIntoConstraints = false
    
        return line
    }()
    
    let noteLabel: UILabel = {
        let label = UILabel()
        label.text = "Notes"
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        return label
    }()
    
    let noteLabelInfo: UILabel = {
        let label = UILabel()
        label.text = " "
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        return label
    }()
    
//    let noteLabelInfo: UITextView = {
//        let label = UITextView()
//        label.text = "This is a note that will be placed here and says many things that i would like tefile to read through."
//        // label.backgroundColor = .red
//        // enable autolayout
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
////        label.numberOfLines = 0
////        label.lineBreakMode = .byWordWrapping
//        label.backgroundColor = .darkBlue
//        label.textColor = .white
//        return label
//    }()
    
    let notesCardView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // add scroll to view controller
    let scrollView : UIScrollView = {
        let view = UIScrollView()
        //view.frame = self.view.bounds
        //view.contentInsetAdjustmentBehavior = .never
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkBlue
        //view.contentSize = contentViewSize
        return view
    }()
    
    let containerView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkBlue
        //view.frame.size = contentViewSize
        return view
    }()
    
    
    private func setupUI() {

        self.view.addSubview(containerView)


        if file?.missingFundsSwitch == true {
            view.addSubview(missingFundsFlag)
            missingFundsFlag.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
            missingFundsFlag.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0).isActive = true
            missingFundsFlag.heightAnchor.constraint(equalToConstant: 34).isActive = true
        }

        view.addSubview(summaryButton)
        summaryButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        summaryButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0).isActive = true
        summaryButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        summaryButton.widthAnchor.constraint(equalToConstant: 175).isActive = true

        if file?.cocSwitch == true {
            containerView.addSubview(finalCOCTotalLabel)
            finalCOCTotalLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
            finalCOCTotalLabel.topAnchor.constraint(equalTo: summaryButton.bottomAnchor, constant: 10).isActive = true
            finalCOCTotalLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

            containerView.addSubview(cocTotalLabelInfo)
            cocTotalLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
            cocTotalLabelInfo.bottomAnchor.constraint(equalTo: finalCOCTotalLabel.bottomAnchor).isActive = true
            cocTotalLabelInfo.topAnchor.constraint(equalTo: finalCOCTotalLabel.topAnchor).isActive = true

            containerView.addSubview(invoiceTotalLabel)
            invoiceTotalLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
            invoiceTotalLabel.topAnchor.constraint(equalTo: finalCOCTotalLabel.bottomAnchor).isActive = true
            invoiceTotalLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true
        } else {
            containerView.addSubview(cocTotalLabel)
            cocTotalLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
            cocTotalLabel.topAnchor.constraint(equalTo: summaryButton.bottomAnchor, constant: 10).isActive = true
            cocTotalLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

            containerView.addSubview(cocTotalLabelInfo)
            cocTotalLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
            cocTotalLabelInfo.bottomAnchor.constraint(equalTo: cocTotalLabel.bottomAnchor).isActive = true
            cocTotalLabelInfo.topAnchor.constraint(equalTo: cocTotalLabel.topAnchor).isActive = true

            containerView.addSubview(invoiceTotalLabel)
            invoiceTotalLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
            invoiceTotalLabel.topAnchor.constraint(equalTo: cocTotalLabel.bottomAnchor).isActive = true
            invoiceTotalLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

        }


        containerView.addSubview(invoiceTotalLabelInfo)
        invoiceTotalLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        invoiceTotalLabelInfo.bottomAnchor.constraint(equalTo: invoiceTotalLabel.bottomAnchor).isActive = true
        invoiceTotalLabelInfo.topAnchor.constraint(equalTo: invoiceTotalLabel.topAnchor).isActive = true

        containerView.addSubview(deductibleTotalLabel)
        deductibleTotalLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        deductibleTotalLabel.topAnchor.constraint(equalTo: invoiceTotalLabel.bottomAnchor).isActive = true
        deductibleTotalLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

        containerView.addSubview(deductibleTotalLabelInfo)
        deductibleTotalLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        deductibleTotalLabelInfo.bottomAnchor.constraint(equalTo: deductibleTotalLabel.bottomAnchor).isActive = true
        deductibleTotalLabelInfo.topAnchor.constraint(equalTo: deductibleTotalLabel.topAnchor).isActive = true

        containerView.addSubview(invoiceBalanceTotalLabel)
        invoiceBalanceTotalLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        invoiceBalanceTotalLabel.topAnchor.constraint(equalTo: deductibleTotalLabel.bottomAnchor).isActive = true
        invoiceBalanceTotalLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

        containerView.addSubview(invoiceBalanceTotalLabelInfo)
        invoiceBalanceTotalLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        invoiceBalanceTotalLabelInfo.bottomAnchor.constraint(equalTo: invoiceBalanceTotalLabel.bottomAnchor).isActive = true
        invoiceBalanceTotalLabelInfo.topAnchor.constraint(equalTo: invoiceBalanceTotalLabel.topAnchor).isActive = true

        containerView.addSubview(rcvTotalLabel)
        rcvTotalLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        rcvTotalLabel.topAnchor.constraint(equalTo: invoiceBalanceTotalLabel.bottomAnchor).isActive = true
        rcvTotalLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

        containerView.addSubview(rcvTotalLabelInfo)
        rcvTotalLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        rcvTotalLabelInfo.bottomAnchor.constraint(equalTo: rcvTotalLabel.bottomAnchor).isActive = true
        rcvTotalLabelInfo.topAnchor.constraint(equalTo: rcvTotalLabel.topAnchor).isActive = true


        //outOfPocketLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true
        containerView.addSubview(outOfPocketLabel)
        outOfPocketLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        outOfPocketLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        outOfPocketLabel.topAnchor.constraint(equalTo: rcvTotalLabel.bottomAnchor).isActive = true
        outOfPocketLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true

        containerView.addSubview(outOfPocketLabelInfo)
        outOfPocketLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        outOfPocketLabelInfo.bottomAnchor.constraint(equalTo: outOfPocketLabel.bottomAnchor).isActive = true
        outOfPocketLabelInfo.topAnchor.constraint(equalTo: outOfPocketLabel.topAnchor).isActive = true
        
        containerView.addSubview(oopFlagMessage)
        oopFlagMessage.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        oopFlagMessage.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        oopFlagMessage.topAnchor.constraint(equalTo: outOfPocketLabel.bottomAnchor).isActive = true
        oopFlagMessage.heightAnchor.constraint(equalToConstant: 40).isActive = true

        containerView.addSubview(creditLabel)
        creditLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        creditLabel.topAnchor.constraint(equalTo: oopFlagMessage.bottomAnchor).isActive = true
        creditLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

        containerView.addSubview(creditLabelInfo)
        creditLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        creditLabelInfo.bottomAnchor.constraint(equalTo: creditLabel.bottomAnchor).isActive = true
        creditLabelInfo.topAnchor.constraint(equalTo: creditLabel.topAnchor).isActive = true

        containerView.addSubview(line)
        line.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        line.topAnchor.constraint(equalTo: creditLabel.bottomAnchor, constant: 10).isActive = true
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        line.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true

        containerView.addSubview(noteLabel)
        noteLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        noteLabel.topAnchor.constraint(equalTo: line.bottomAnchor).isActive = true
        noteLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

        //containerView.addSubview(notesCardView)
//        notesCardView.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 5).isActive = true
//        notesCardView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
//        notesCardView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true

        containerView.addSubview(noteLabelInfo)
        noteLabelInfo.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 24).isActive = true
        noteLabelInfo.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        noteLabelInfo.topAnchor.constraint(equalTo: noteLabel.bottomAnchor).isActive = true
        //noteLabelInfo.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true

        containerView.bottomAnchor.constraint(equalTo: noteLabelInfo.bottomAnchor).isActive = true
        //notesCardView.bottomAnchor.constraint(equalTo: noteLabelInfo.bottomAnchor, constant: 5).isActive = true



        tableView.tableHeaderView = containerView



    }
    
    // send to office controller
    @objc private func handleSummaryPopUp(sender:UIButton) {
        print("File summary")
        // show summaryController
        let summaryController = SummaryController()
        summaryController.file = file
        summaryController.teamMember = teamMember
        // this creates the red top nav portion that holds the file name, done button
        let navController = UINavigationController(rootViewController: summaryController)
        // add animation to the button
        self.animateView(sender)
        present(navController, animated: true, completion: nil)
        
    }
    
    // animation for the "Show Summary" button
    fileprivate func animateView(_ viewToAnimate: UIView) {
        UIView.animate(withDuration: 0.30, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 0.6, options: .curveEaseIn, animations: {
            viewToAnimate.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { (_) in
            UIView.animate(withDuration: 0.30, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 2, options: .curveEaseIn, animations: {
                viewToAnimate.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        }
    }
    
    // create UILabel subclass for custom text drawing - usually for my headers
    class IndentedLabel: UILabel {
        override func drawText(in rect: CGRect) {
            let insets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            let customRect = rect.inset(by: insets)
            super.drawText(in: customRect)
        }
    }
    
    @objc func handleDone() {
        dismiss(animated: true, completion: nil)
    }
}

