//
//  CreateLineItemController.swift
//  PaymentTracker
//
//  Created by Mitch Baumgartner on 3/7/21.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase
import JGProgressHUD
import FirebaseStorage


protocol createLineItemControllerDelegate {
    func didAddItem()
    func didEditItem(item: FB_ItemInformation)
}

// this controller creates a view controller for creating an employee when user taps plus button
class CreateLineItemController: UIViewController {
    var filesCollectionRef: CollectionReference!
    let db = Firestore.firestore()
    // establish delegate
    var delegate: createLineItemControllerDelegate?
    
    var file: FB_File? // File? (optional) means it can start as nil
    
    var fileItem: FileItem?
    var thisItemId = ""

    var itemInformation: FB_ItemInformation? {
        didSet {
            lineItemTextField.text = itemInformation?.name
            thisItemId = (itemInformation?.id)!
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .decimal
            currencyFormatter.currencySymbol = ""
            
            itemPriceTextField.text = itemInformation?.linePrice
            if itemInformation?.linePrice != "" {
                let price = Double(itemInformation?.linePrice ?? "")
                let priceFormat = currencyFormatter.string(from: NSNumber(value: price ?? 0.0))
                itemPriceTextField.text = priceFormat
            }
            
            itemLineNumberTextField.text = itemInformation?.lineNumber
            
            if itemInformation?.lineNote == "None" {
                notesTextField.text = ""
            } else {
                notesTextField.text = itemInformation?.lineNote
            }
            
            print(itemInformation?.type)
            if itemInformation?.type == "ACV owed to HO" {
                lineItemTypeSegmentedControl.selectedSegmentIndex = 0
            } else if itemInformation?.type == "RCV work to do" {
                lineItemTypeSegmentedControl.selectedSegmentIndex = 1
            } else {
                lineItemTypeSegmentedControl.selectedSegmentIndex = 2
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // title
        navigationItem.title = "Add Line Item"
        // add cancel button to dismiss view
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        view.backgroundColor = .darkBlue
        navigationController?.transparentNavigationBar()
        navigationController?.setTintColor(.white)
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        setupUI()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(handleSave))
        
        // dismiss keyboard when user taps outside of keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        let swipeDown = UIPanGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
    
        
    }
    
    
    @objc private func handleSave() {
        if itemInformation == nil {
            createLineItem()
        } else {
            saveLineItemChanges()
        }
    }
        
    private func saveLineItemChanges() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        guard let lineItem = lineItemTextField.text else { return }
        guard let price = itemPriceTextField.text else { return }
        if lineItem.isEmpty && price.isEmpty {
            return showError(title: "Invalid Entry", message: "You have not entered a line item description or price.")
        } else if lineItem.isEmpty {
            return showError(title: "Invalid Entry", message: "You have not entered a line item description.")
        } else if price.isEmpty {
            return showError(title: "Invalid Entry", message: "You have not entered a price.")
        }
        if lineItem != "" {
            db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["itemName" : lineItem])
        } else {
            db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["itemName" : ""])
        }

        if price != "" {
            let priceDouble = price.toDoubleWithAutoLocale()
            // if user enters invalid entry for a price value (commas and decimals) error message
            if priceDouble == nil {
                return showError(title: "Invalid Price Entry", message: "Double check your price entry.")
            }
            db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["linePrice" : "\(priceDouble ?? 0.0)"])
        } else {
            db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["linePrice" : price])
        }

        guard let lineNumber = itemLineNumberTextField.text else { return }
        db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["lineNumber" : lineNumber])

        guard let notes = notesTextField.text else { return }
        if notes == "" {
            db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["lineNote" : "None"])
        } else {
            db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["lineNote" : notes])
        }



        // how to make create type know which filter to set the type to
        guard let itemType = lineItemTypeSegmentedControl.titleForSegment(at: lineItemTypeSegmentedControl.selectedSegmentIndex) else { return }
        db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["itemType" : itemType])

        // reset time stamp
        let timeStamp = "\(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long))"
        db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).updateData(["timeStamp" : timeStamp])
        
        dismiss(animated: true, completion: {
            self.delegate?.didEditItem(item: self.itemInformation!)
        })

    }
    
    

    @objc private func createLineItem() {
        print("saving line item..")

        // use nonoptional of name, unwraps the employeeName
        guard let itemName = lineItemTextField.text else { return }
        // use nonoptional of company, unwraps the company
        guard let file = self.file else { return }
        guard let itemPrice = itemPriceTextField.text else { return showError(title: "Invalid Price", message: "Double check your price entry.") }
        guard let lineNumber = itemLineNumberTextField.text else { return }
        guard let lineNote = notesTextField.text else { return }

        // this date resolves error, doesnt actually do anything
        let checkText = "08/23/2000"
        // date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        // check to make sure user enters correct format of birthday or correct date
        guard let checkDate = dateFormatter.date(from: checkText) else { return }
        
        

        let checkAmount = ""


        if itemName.isEmpty && itemPrice.isEmpty {
            return showError(title: "Invalid Entry", message: "You have not entered a line item description or price.")
        } else if itemName.isEmpty {
            return showError(title: "Invalid Entry", message: "You have not entered a line item description.")
        } else if itemPrice.isEmpty {
            return showError(title: "Invalid Entry", message: "You have not entered a price.")
        }
        // this guard verifies that the user enterd a valid number in the line item text field
        guard Double(itemPriceTextField.text!) != nil else { return showError(title: "Invalid Price", message: "Invalid price entry.")}



        // how to make create employee know which filter to set the employee to
        guard let itemType = lineItemTypeSegmentedControl.titleForSegment(at: lineItemTypeSegmentedControl.selectedSegmentIndex) else { return }


        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // reset time stamp
        let timeStamp = "\(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long))"
        db.collection("Users").document(uid).collection("Files").document((file.id)!).updateData(["timeStamp" : timeStamp])
        
        let lineItemId = db.collection("Users").document(uid).collection("Files").document(file.id!).collection("FileInformation").document().documentID
        db.collection("Users").document(uid).collection("Files").document(file.id!).collection("FileInformation").document(lineItemId).setData([
                                                                                            "id" : lineItemId,
                                                                                                                                                            "fileId" : file.id!,
                                                                                            "itemName" : itemName,
                                                                                            "itemType" : itemType,
                                                                                            "checkDate" : "",
                                                                                            "checkAmount" : checkAmount,
                                                                                            "lineNumber" : lineNumber,
                                                                                            "linePrice" : itemPrice,
                                                                                            "lineNote" : lineNote,
                                                                                            ])
        
        dismiss(animated: true) {
                        self.delegate?.didAddItem()
                    }
        

    }

    // create work item name label
    let lineItemLabel: UILabel = {
        let label = UILabel()
        label.text = "ITEM"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    // create text field for item entry
    let lineItemTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Line item description",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // create work item price label
    let itemPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "PRICE"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create COC total label
    let amount$: UILabel = {
        let label = UILabel()
        label.text = "$"
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    
    
    // create text field for price entry
    let itemPriceTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Line item price",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.setLeftPaddingPoints(17)
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        textField.keyboardType = UIKeyboardType.decimalPad
        textField.addNumericAccessory(addPlusMinus: true)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        
        return textField
    }()
    
    // create work item line number label
    let itemLineNumberLabel: UILabel = {
        let label = UILabel()
        label.text = "LINE NUMBER"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    // create text field for price entry
    let itemLineNumberTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Insurance line item number",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        //textField.keyboardType = UIKeyboardType.numberPad
        return textField
    }()
    
    // create label for notes
    let notesLabel: UILabel = {
        let label = UILabel()
        label.text = "NOTES"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    // create text field for notes
    let notesTextField: UITextView = {
        let textField = UITextView()
        textField.font = .systemFont(ofSize: 16)
        textField.backgroundColor = UIColor.white
        textField.textColor = .darkGray
        textField.layer.borderWidth = 1.0;
        textField.layer.borderColor = UIColor.lightRed.cgColor
        textField.layer.cornerRadius = 10;
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        //textField.keyboardType = UIKeyboardType.numberPad
        return textField
    }()
    // employee type segmented viewing filter
    let lineItemTypeSegmentedControl: UISegmentedControl = {
        let types = ["ACV owed to HO","RCV work to do", "Cash work to do"]
        let sc = UISegmentedControl(items: types)
        sc.overrideUserInterfaceStyle = .light
        sc.selectedSegmentTintColor = UIColor.lightRed
        sc.backgroundColor = UIColor.white
        // default as first item
        sc.selectedSegmentIndex = 0
        //sc.overrideUserInterfaceStyle = .light
        sc.translatesAutoresizingMaskIntoConstraints = false
        // highlighted filter color
        //sc.selectedSegmentTintColor = UIColor.lightRed
        // Scope: Normal text color
        sc.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
        // Scope: Selected text color
        sc.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        return sc
    }()
    private func setupUI() {
        // add and position background color in relationship to the view elements on the view controller
        let silverBackgroundView = UIView()
        silverBackgroundView.backgroundColor = UIColor.white
        silverBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(silverBackgroundView)
        silverBackgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        silverBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        silverBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        silverBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // add and position item name label
        view.addSubview(lineItemLabel)
        lineItemLabel.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        lineItemLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

        
        // add and position item name textfield element to the right of the nameLabel
        view.addSubview(lineItemTextField)
        lineItemTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        lineItemTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        lineItemTextField.topAnchor.constraint(equalTo: lineItemLabel.bottomAnchor).isActive = true
        lineItemTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // add and position item price label
        view.addSubview(itemPriceLabel)
        itemPriceLabel.topAnchor.constraint(equalTo: lineItemTextField.bottomAnchor, constant: 20).isActive = true
        itemPriceLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        view.addSubview(amount$)
        amount$.topAnchor.constraint(equalTo: itemPriceLabel.bottomAnchor).isActive = true
        amount$.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        amount$.heightAnchor.constraint(equalToConstant: 40).isActive = true
        amount$.widthAnchor.constraint(equalToConstant: 15).isActive = true
        
        // add and position item price textfield element to the right of the itemPriceLabel
        view.addSubview(itemPriceTextField)
        itemPriceTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        itemPriceTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        itemPriceTextField.topAnchor.constraint(equalTo: itemPriceLabel.bottomAnchor).isActive = true
        itemPriceTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // add and position item line number label
        view.addSubview(itemLineNumberLabel)
        itemLineNumberLabel.topAnchor.constraint(equalTo: itemPriceTextField.bottomAnchor, constant: 20).isActive = true
        itemLineNumberLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        // add and position item price textfield element to the right of the itemPriceLabel
        view.addSubview(itemLineNumberTextField)
        itemLineNumberTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        itemLineNumberTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        itemLineNumberTextField.topAnchor.constraint(equalTo: itemLineNumberLabel.bottomAnchor).isActive = true
        itemLineNumberTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        // add and position item line number label
        view.addSubview(notesLabel)
        notesLabel.topAnchor.constraint(equalTo: itemLineNumberTextField.bottomAnchor, constant: 20).isActive = true
        notesLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        // add and position item price textfield element to the right of the itemPriceLabel
        view.addSubview(notesTextField)
        notesTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        notesTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        notesTextField.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 10).isActive = true
        notesTextField.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        
        // add segmented control view
        view.addSubview(lineItemTypeSegmentedControl)
        lineItemTypeSegmentedControl.topAnchor.constraint(equalTo: notesTextField.bottomAnchor, constant: 20).isActive = true
        lineItemTypeSegmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        lineItemTypeSegmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        
        lineItemTypeSegmentedControl.heightAnchor.constraint(equalToConstant: 34).isActive = true
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // create alert that will present an error, this can be used anywhere in the code to remove redundant lines of code
    private func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        return
    }
    
}
