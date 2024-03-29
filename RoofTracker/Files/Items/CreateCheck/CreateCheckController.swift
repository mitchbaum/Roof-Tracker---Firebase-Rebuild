//
//  CreateEmployeeController.swift
//  TrainingCourse
//
//  Created by Mitch Baumgartner on 3/2/21.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase
import JGProgressHUD
import FirebaseStorage

protocol createCheckControllerDelegate {
    func didAddItem()
    func didEditItem(item: FB_ItemInformation)
}

// this controller creates a view controller for creating an employee when user taps plus button 
class CreateCheckController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var filesCollectionRef: CollectionReference!
    let db = Firestore.firestore()
    
    // establish delegate
    var delegate: createCheckControllerDelegate?

    var file: FB_File? // file? (optional) means it can start as nil
    
    var thisItemId = ""
    
    var types = ["", "Insurance","Personal", "Insurance PAID"]
    
    
    // go into coredata and set a variable for FileItem that way i can access the variables
    var fileItem: FileItem?
    
    var itemInformation: FB_ItemInformation? {
        didSet {
            numberTextField.text = itemInformation?.name
            
            thisItemId = (itemInformation?.id)!
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .decimal
            currencyFormatter.currencySymbol = ""
            
            amountTextField.text = itemInformation?.checkAmount
            if itemInformation?.checkAmount != "" {
                let amount = Double(itemInformation?.checkAmount ?? "")
                let amountFormat = currencyFormatter.string(from: NSNumber(value: amount ?? 0.0))
                amountTextField.text = amountFormat
            }
        
            // convert Date type to string
            // guard if date is empty return 2000-01-01 00:00:00 value
            guard let dateRaw = itemInformation?.checkDate else { return }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMdd"
            dateTextField.text = dateRaw
            
            typeTextField.text = itemInformation?.type
        
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // title
        navigationItem.title = "Add Check"
        
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
        
        typeTextField.inputView = typePicker
        typePicker.delegate = self
        typePicker.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        db.collection("Users").document(uid).getDocument(completion: { snapshot, error in
//            if let err = error {
//                debugPrint("Error fetching profile: \(err)")
//            } else {
//                if let data = snapshot?.data() {
//                    let year = data["year"] as? String
//                    
//                    
//                }
//            }
//        })
//        
    }
    
    // distinguish between save and edit
    @objc private func handleSave() {
        // creating a new check
        if itemInformation == nil {
            createCheck()
        } else {
            saveCheckChanges()
        }
    }
    private func saveCheckChanges() {
        print("saving check changes")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let number = numberTextField.text else { return }
        guard let amount = amountTextField.text else { return }
        guard let date = dateTextField.text else { return }
        guard let itemType = typeTextField.text else { return }
        if number.isEmpty && amount.isEmpty && date.isEmpty {
            return showError(title: "Invalid Check", message: "No check information added.")
        }
        if number != "" {
            db.collection("Users").document(uid).collection("Files").document( (itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["itemName" : number])
        } else {
            db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["itemName" : ""])
        }
        
        if amount != "" {
            let amountDouble = amount.toDoubleWithAutoLocale()
            // if user enters invalid entry for a amount value (commas and decimals) error message
            if amountDouble == nil {
                return showError(title: "Invalid Amount Entry", message: "Double check your amount entry.")
            }
            db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["checkAmount" : "\(amountDouble ?? 0.0)"])
        } else {
            db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["checkAmount" : amount])
        }
        
        var myStringDate = ""
        if date.isEmpty {
            // date formatter for empty date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMdd"
            let checkDate = dateFormatter.date(from: date)
            db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["checkDate" : date])
            
        } else {
        
            // date formatter
            if date.count == 8 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMddyyyy"
                guard let checkDate = dateFormatter.date(from: date)
                else {
                    let alertController = UIAlertController(title: "Invalid Date", message: "Double check the format. MMdd or MMddyyyy", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    present(alertController, animated: true, completion: nil)
                    return
                }
                myStringDate = dateFormatter.string(from: checkDate)
                db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["checkDate" : dateTextField.text ?? ""])
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMddyyyy"
                guard let checkDate = dateFormatter.date(from: date + "2022")
                else {
                    let alertController = UIAlertController(title: "Invalid Date", message: "Double check the format. MMdd or MMddyyyy", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    present(alertController, animated: true, completion: nil)
                    return
                }
                myStringDate = dateFormatter.string(from: checkDate)
                db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["checkDate" : dateTextField.text ?? ""])
            }
        }
        
        // reset time stamp
        let timeStamp = "\(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long))"
        db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).updateData(["timeStamp" : timeStamp, "modified" : FieldValue.serverTimestamp()])
        


    
        
        db.collection("Users").document(uid).collection("Files").document((itemInformation?.fileId)!).collection("FileInformation").document(thisItemId).updateData(["itemType" : itemType])
        
        
        dismiss(animated: true, completion: {
            self.delegate?.didEditItem(item: self.itemInformation!)
        })
        
        
    }
    
    
    @objc private func createCheck() {
        print("saving check with a date..")

        // use nonoptional of name, unwraps the itemName
        guard let itemName = numberTextField.text else { return }

        // use nonoptional of file, unwraps the file
        guard let file = self.file else { return }

        guard let checkAmount = amountTextField.text else { return }
        
        guard let itemType = typeTextField.text else { return }

        // turn birthdayTextField.text into a date object
        guard let checkText = dateTextField.text else { return }
        if checkText.isEmpty && checkAmount.isEmpty && itemName.isEmpty {
            return showError(title: "Invalid Check", message: "No check information added.")
        } else if typeTextField.text == "" {
            return showError(title: "Invalid Entry", message: "You have not entered a type.")
        }
        guard Double(amountTextField.text!) != nil else { return showError(title: "Invalid Check", message: "Invalid amount entry.") }

        let itemPrice = ""

        let lineNumber = ""

        let lineNote = ""


        var myStringDate = ""
        if checkText.isEmpty == false {
            // date formatter
            if checkText.count == 8 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMddyyyy"
                // check to make sure user enters correct format of birthday or correct date

                guard let checkDate = dateFormatter.date(from: checkText)
                else {
                    let alertController = UIAlertController(title: "Invalid Date", message: "Double check the format. MMdd or MMddyyyy", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    present(alertController, animated: true, completion: nil)
                    return
                }
                myStringDate = dateFormatter.string(from: checkDate)
            } else {
                let dateFormatter = DateFormatter()
                let year = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year
                dateFormatter.dateFormat = "MMdd"
                // check to make sure user enters correct format of birthday or correct date
                
                guard let checkDate = dateFormatter.date(from: checkText)
                else {
                    let alertController = UIAlertController(title: "Invalid Date", message: "Double check the format. MMdd or MMddyyyy", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    present(alertController, animated: true, completion: nil)
                    return
                }
                myStringDate = dateFormatter.string(from: checkDate) + "\(year ?? 2023)"
            }
        }

        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // reset time stamp
        let timeStamp = "\(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long))"
        db.collection("Users").document(uid).collection("Files").document((file.id)!).updateData(["timeStamp" : timeStamp, "modified" : FieldValue.serverTimestamp()])
        
        let checkId = db.collection("Users").document(uid).collection("Files").document(file.id!).collection("FileInformation").document().documentID
        db.collection("Users").document(uid).collection("Files").document(file.id!).collection("FileInformation").document(checkId).setData([
                                                                                            "id" : checkId,
                                                                                                                                                            "fileId" : file.id!,
                                                                                            "itemName" : itemName,
                                                                                            "itemType" : itemType,
                                                                                                                                                "checkDate" : myStringDate,
                                                                                            "checkAmount" : checkAmount,
                                                                                            "lineNumber" : lineNumber,
                                                                                            "linePrice" : itemPrice,
                                                                                            "lineNote" : lineNote,
                                                                                            ])

        
        dismiss(animated: true) {
                        self.delegate?.didAddItem()
                    }

    
    }
    // create check number label
    let numberLabel: UILabel = {
        let label = UILabel()
        label.text = "CHECK NUMBER"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    // create text field for check number entry
    let numberTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter check number"
        textField.attributedPlaceholder = NSAttributedString(string: "Enter check number",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly


        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // create check amount label
    let amountLabel: UILabel = {
        let label = UILabel()
        label.text = "AMOUNT"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // label.backgroundColor = .red
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
    
    
    // create text field for check amount entry
    let amountTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter check amount",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.keyboardType = UIKeyboardType.decimalPad
        textField.setLeftPaddingPoints(17)
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        textField.textColor = .darkGray
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = UIKeyboardType.decimalPad
        return textField
    }()
    
    // create date label
    let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "DATE"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    // create text field for date entry
    let dateTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "MMdd or MMddyyyy",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.keyboardType = UIKeyboardType.numberPad
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        textField.textColor = .darkGray
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let typeLabel: UILabel = {
        let label = UILabel()
        label.text = "TYPE"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let typeIcon: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "down_arrow"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
    // create text field for reentered password
    let typeTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Select type...",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // create year picker view
    let typePicker: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()
    
    
    
    // radio button for insurance check AND paid to viking
    
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
        
        
        
        // add and position check number label
        view.addSubview(numberLabel)
        numberLabel.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        numberLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

        
        // add and position name textfield element to the right of the numberLabel
        view.addSubview(numberTextField)
        numberTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        numberTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        numberTextField.topAnchor.constraint(equalTo: numberLabel.bottomAnchor).isActive = true
        numberTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        // add and position check amount label
        view.addSubview(amountLabel)
        amountLabel.topAnchor.constraint(equalTo: numberTextField.bottomAnchor, constant: 20).isActive = true
        amountLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

        view.addSubview(amount$)
        amount$.topAnchor.constraint(equalTo: amountLabel.bottomAnchor).isActive = true
        amount$.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        amount$.heightAnchor.constraint(equalToConstant: 40).isActive = true
        amount$.widthAnchor.constraint(equalToConstant: 15).isActive = true
        
        // add and position name textfield element to the right of the numberLabel
        view.addSubview(amountTextField)
        amountTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        amountTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        amountTextField.topAnchor.constraint(equalTo: amountLabel.bottomAnchor).isActive = true
        amountTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // add and position date label
        view.addSubview(dateLabel)
        dateLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 20).isActive = true
        dateLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        // add and position date textfield element to the right of the dateLabel
        view.addSubview(dateTextField)
        dateTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        dateTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        dateTextField.topAnchor.constraint(equalTo: dateLabel.bottomAnchor).isActive = true
        dateTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(typeLabel)
        typeLabel.topAnchor.constraint(equalTo: dateTextField.bottomAnchor, constant: 20).isActive = true
        typeLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

           
        view.addSubview(typeTextField)
        typeTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        typeTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        typeTextField.topAnchor.constraint(equalTo: typeLabel.bottomAnchor).isActive = true
        typeTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(typeIcon)
        typeIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -34).isActive = true
        typeIcon.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 12).isActive = true
        typeIcon.heightAnchor.constraint(equalToConstant: 15).isActive = true
        typeIcon.widthAnchor.constraint(equalToConstant: 15).isActive = true

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
    
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}
