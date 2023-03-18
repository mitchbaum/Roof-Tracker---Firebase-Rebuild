//
//  CreatefileController.swift
//  TrainingCourse
//
//  Created by Mitch Baumgartner on 2/27/21.
//

// this file will create a clustom viewController that allows user to add a file to the tableView with a nice display
import UIKit
import CoreData
import FirebaseAuth
import Firebase
import FirebaseDatabase
import JGProgressHUD
import FirebaseStorage


//custom delegation
protocol CreateFileControllerDelegate {
    func didAddFile()
    func didEditFile(file: FB_File)
}

class CreateFileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // establishes link to filesController
    //var filesController: filesController?
    var delegate: CreateFileControllerDelegate?
    
    let db = Firestore.firestore()
    var filesCollectionRef: CollectionReference!
    
    var thisFileId = ""
    var isMissingFunds = false
    
    // variable keeps track of which file you are trying to edit. variable file with type File
    var file: FB_File? {
        // this will prefill the form with whatever i need when tapping the edit button
        didSet {
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .decimal
            currencyFormatter.currencySymbol = ""
            
            thisFileId = file?.id ?? ""
            
            nameTextField.text = file?.name
            
            cocTextField.text = file?.coc
            if file?.coc != "" {
                let coc = Double(file?.coc ?? "")
                let cocFormat = currencyFormatter.string(from: NSNumber(value: coc ?? 0.0))
                cocTextField.text = cocFormat
            }
            
            invoiceTextField.text = file?.invoice
            if file?.invoice != "" {
                let invoice = Double(file?.invoice ?? "")
                let invoiceFormat = currencyFormatter.string(from: NSNumber(value: invoice ?? 0.0))
                invoiceTextField.text = invoiceFormat
            }
            
            deductibleTextField.text = file?.deductible
            if file?.deductible != "" {
                let deductible = Double(file?.deductible ?? "")
                let deductibleFormat = currencyFormatter.string(from: NSNumber(value: deductible ?? 0.0))
                deductibleTextField.text = deductibleFormat
            }
            
            notesTextField.text = file?.note
            
            if file?.imageData != "" {
                fetchFileImage()
            } else {
                fileImageView.image = UIImage(named: "file_photo_empty")
            }
            
            
            if file?.type == "Open" {
                fileTypeSegmentedControl.selectedSegmentIndex = 0
            } else if file?.type == "Closed" {
                fileTypeSegmentedControl.selectedSegmentIndex = 1
            }
            if file?.cocSwitch == true {
                finalCOCSwitch.isOn = true
            } else {
                finalCOCSwitch.isOn = false
            }
            print("file?.missingFundsSwitch: ", file?.missingFundsSwitch)
            
            if file?.missingFundsSwitch == true {
                missingFundsSwitch.isOn = true
            } else {
                missingFundsSwitch.isOn = false
            }
//            // this fixes the crash if you tap edit on a cell without a date
//            guard let founded = file?.founded else { return }
//            datePicker.date = (file?.founded)!
        }
    }
    
    func fetchFileImage() {
        print("fetching file image")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Users").document(uid).collection("Files").document(self.thisFileId).getDocument { (snapshot, error) in
            if let data = snapshot?.data() {
                if let imageData = data["imageData"] as? String {
                    let url = NSURL(string: imageData)
                    URLSession.shared.dataTask(with: url! as URL, completionHandler: { (data, response, error) in
                        if error != nil {
                            print(error ?? "")
                            return
                        }
                        // run image setter on main queue
                        DispatchQueue.main.async {
                            self.fileImageView.image = UIImage(data: data!)
                        }
                    }).resume()
                }
            }
        }
        setupCircularStyle()
        
    }
    
   
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = file == nil ? "Create File" : "Edit File"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set up label position in view controller
        setupUI()
        
        // create title for this view controller
        navigationItem.title = "Create File"
    
        // add cancel button to dismiss view
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        // add save button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(handleSave))
        
        view.backgroundColor = UIColor.darkBlue
        navigationController?.backgroundColor(.darkBlue)
        navigationController?.setTintColor(.white)
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // dismiss keyboard when user taps outside of keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        let swipeDown = UIPanGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
        


    }
    
    // save function
    @objc private func handleSave() {
        if file == nil {
            FB_createFile()
        } else {
            FB_saveFileChanges()
        }
    }

    private func FB_saveFileChanges() {
        self.hud.textLabel.text = "Saving File"
        self.hud.show(in: self.view, animated: true)
        print("saving file changes in Firebase")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let coc = cocTextField.text
        // if user enters something in the coc textfield, start this if statement block
        if coc != "" {
            let cocDouble = coc?.toDoubleWithAutoLocale()
            // if user enters invalid entry for a coc value (commas and decimals) error message
            if cocDouble == nil {
                return showError(title: "Invalid COC Entry", message: "Double check your COC entry.")
            }
            //file?.coc = "\(cocDouble ?? 0.00)"
            self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["coc" : "\(cocDouble ?? 0.00)"])
            
        } else { // if user decides to remove a coc entry, the save will clear the textfield to empty
            //file?.coc = coc
            self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["coc" : coc ?? ""])
        }
        
        let invoice = invoiceTextField.text
        // if user enters something in the invoice textfield, start this if statement block
        if invoice != "" {
            let invoiceDouble = invoice?.toDoubleWithAutoLocale()
            // if user enters invalid entry for a invoice value (commas and decimals) error message
            if invoiceDouble == nil {
                return showError(title: "Invalid Invoice Entry", message: "Double check your Invoice entry.")
            }
            //file?.invoice = "\(invoiceDouble ?? 0.0)"
            self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["invoice" : "\(invoiceDouble ?? 0.0)"])
        } else { // if user decides to remove a invoice entry, the save will clear the textfield to empty
            //file?.invoice = invoice
            self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["invoice" : invoice ?? ""])
            
        }
        
        let deductible = deductibleTextField.text
        // if user enters something in the deductible textfield, start this if statement block
        if deductible != "" {
            let deductibleDouble = deductible?.toDoubleWithAutoLocale()
            // if user enters invalid entry for a deductible value (commas and decimals) error message
            if deductibleDouble == nil {
                return showError(title: "Invalid Deductible Entry", message: "Double check your Deductible entry.")
            }
//            file?.deductible = "\(deductibleDouble ?? 0.0)"
            self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["deductible" : "\(deductibleDouble ?? 0.0)"])
        } else {
            //file?.deductible = deductible
            self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["deductible" : deductible ?? ""])
        }
        
        if missingFundsSwitch.isOn != file?.missingFundsSwitch {
            self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["missingFundsSwitch" : missingFundsSwitch.isOn])
            print("setting missingFundsSwitch to \(String(missingFundsSwitch.isOn)) in db")
            if (missingFundsSwitch.isOn && file?.missingFunds == nil) {
                print("saving missing funds")
                if let coc = Double(file?.coc ?? ""), let insCheckACVTotal = Double(file?.insCheckACVTotal ?? ""), let deducible = Double(file?.deductible ?? "") {
                    let missingFunds = coc + insCheckACVTotal - deducible
                  self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["missingFunds" : missingFunds])
                    updateUserTotalMissingFunds(missingFunds: missingFunds, fileId: self.thisFileId, fileName: file?.name ?? "")
                }
                
            }
        }
        
        
        
        // reset time stamp
        let timeStamp = "\(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long))"
        self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["timeStamp" : timeStamp, "modified" : FieldValue.serverTimestamp()])
        self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["name" : nameTextField.text ?? "",       
                                                                                                            "type" : fileTypeSegmentedControl.titleForSegment(at: fileTypeSegmentedControl.selectedSegmentIndex) ?? "Open",
                                                                                                            "cocSwitch" : finalCOCSwitch.isOn,
                                                                                                            "insCheckACVTotal" : file?.insCheckACVTotal ?? "",
                                                                                                            "note" : notesTextField.text ?? ""])
        
//        file?.founded = datePicker.date
        if let stockImage = UIImage(named: "file_photo_empty") {
            let stockData = stockImage.pngData()
            let userInputData = self.fileImageView.image?.pngData()
            if stockData != userInputData {
                print("file picture is different than stock photo")
                let storageRef = Storage.storage().reference().child("\(uid)/\(thisFileId).png")
                // properly save data even when you are editing the row
                if let uploadData = self.fileImageView.image!.jpegData(compressionQuality: 0.8) {
                    print("getting image jpeg data at lowest compression")
                    storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                        if error != nil {
                            self.hud.dismiss(animated: true)
                            print("FB_saveFileChanges error")
                            print(error ?? "")
                            return
                        }
                        print(metadata ?? "")
                    
                        storageRef.downloadURL { (url, error) in
                            guard let url = url, error == nil else {
                                self.hud.dismiss(animated: true)
                                self.showError(title: "Error", message: error.debugDescription)
                                return
                            }
                            let urlString = url.absoluteString
                            print("Download URL: \(urlString)")
                            self.db.collection("Users").document(uid).collection("Files").document(self.thisFileId).updateData(["imageData" : urlString])
                            self.hud.dismiss(animated: true)
                            self.dismiss(animated: true, completion: {self.delegate?.didEditFile(file: self.file!) })
                        }
                    }
                }

            } else {
                self.hud.dismiss(animated: true)
                self.dismiss(animated: true, completion: {self.delegate?.didEditFile(file: self.file!) })
            }
        }
    }
    
    private func updateUserTotalMissingFunds(missingFunds: Double, fileId: String, fileName: String) {
        var currentUserMissingFundsTotal = 0.0
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Users").document(uid).getDocument(completion: { snapshot, error in
            if let err = error {
                debugPrint("Error fetching profile: \(err)")
            } else {
                if let data = snapshot?.data() {
                    let missingFundsTotal = data["missingFundsTotal"] as? Double ?? nil
                    let companyId = data["companyId"] as? String
                    
                    if missingFundsTotal != nil {
                        currentUserMissingFundsTotal = missingFundsTotal!
                    }
                    self.db.collection("Users").document(uid).updateData(["missingFundsTotal" : currentUserMissingFundsTotal + missingFunds])
                    
                    if companyId != "" {
                        self.db.collection("Companies").document(companyId!).collection("MissingFundsLog").document().setData(["timeStamp" : FieldValue.serverTimestamp(), "fileId" :fileId, "fileName": fileName, "missingFunds" : missingFunds, "ownerId": uid])
                        self.updateCompanyTotalMissingFunds(missingFunds: missingFunds, companyId: companyId!)
                    }
                }
            }
        })
        
    }
    
    private func updateCompanyTotalMissingFunds(missingFunds: Double, companyId: String) {
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
                    self.db.collection("Companies").document(companyId).updateData(["missingFundsTotal" : currentCompanyMissingFundsTotal + missingFunds])
                }
            }
        })
        
    }
    
    
    private func FB_createFile() {
        print("saving file in Firebase")
        let name = nameTextField.text ?? ""
        let coc = cocTextField.text ?? ""
        let invoice = invoiceTextField.text ?? ""
        let deductible = deductibleTextField.text ?? ""
        let note = notesTextField.text ?? ""
        let timeStamp = "\(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long))"
        guard let fileType = fileTypeSegmentedControl.titleForSegment(at: fileTypeSegmentedControl.selectedSegmentIndex) else {
            return
        }
        let COCSwitch = finalCOCSwitch.isOn
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let fileId = db.collection("Users").document(uid).collection("Files").document().documentID
        db.collection("Users").document(uid).collection("Files").document(fileId).setData([
                                                                                            "id" : fileId,
                                                                                            "name" : name,
                                                                                            "coc" : coc,
                                                                                            "invoice" : invoice,
                                                                                            "deductible" : deductible,
                                                                                            "timeStamp" : timeStamp,
                                                                                            "modified" : FieldValue.serverTimestamp(),
                                                                                            "type" : fileType,
                                                                                            "cocSwitch" : COCSwitch,
                                                                                            "imageData" : "",
                                                                                            "insCheckACVTotal" : "",
                                                                                            "acvItemTotal" : "",
                                                                                            "cashItemTotal" : "",
                                                                                            "insCheckTotal" : "",
                                                                                            "pymtCheckTotal" : "",
                                                                                            "rcvItemTotal" : "",
                                                                                            "note" : note])
        if let stockImage = UIImage(named: "file_photo_empty") {
            self.hud.textLabel.text = "Creating File"
            self.hud.show(in: self.view, animated: true)
            let stockData = stockImage.pngData()
            let userInputData = self.fileImageView.image?.pngData()
            if stockData != userInputData {
                print("file picture is different than stock photo")
                if let uploadData = self.fileImageView.image!.jpegData(compressionQuality: 0.8) {
                    print("Hereerererere")
                    let storageRef = Storage.storage().reference().child("\(uid)/\(fileId).png")
                    //print("is not equal")
                    storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                        if error != nil {
                            print("FB_createFile error")
                            print(error ?? "")
                            self.hud.dismiss(animated: true)
                            return
                        }
                    
                        storageRef.downloadURL { (url, error) in
                            guard let url = url, error == nil else {
                                self.hud.dismiss(animated: true)
                                self.showError(title: "Error", message: error.debugDescription)
                                return
                            }
                            let urlString = url.absoluteString
                            print("Download URL: \(urlString)")
                            self.db.collection("Users").document(uid).collection("Files").document(fileId).updateData(["imageData" : urlString])
                            self.dismiss(animated: true, completion: {
                                self.delegate?.didAddFile()
                            })
                        }
                    }
                }
            } else {
                self.hud.dismiss(animated: true)
                self.dismiss(animated: true, completion: {
                    self.delegate?.didAddFile()
                })
                
            }
        }

        
    }
    
    @objc func switchIsChanged(mySwitch: UISwitch) {
        let value = mySwitch.isOn
        if (!value) {
            removeMissingFunds(title: "Verify Missing Funds", message: "Remove missing funds flag from file?")
        } else if (value && (file?.deductible == "" || file?.coc == "")) {
            showError(title: "Verify Missing Funds", message: "No missing funds detected. Could not calculate due to missing Deductible and COC.")
            missingFundsSwitch.isOn = false
        }else if (value) {
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .currency
            currencyFormatter.locale = Locale.current
            if let coc = Double(file?.coc ?? ""), let insCheckACVTotal = Double(file?.insCheckACVTotal ?? ""), let deducible = Double(file?.deductible ?? "") {
                let missingFunds = coc + insCheckACVTotal - deducible
                let currencyFormat = currencyFormatter.string(from: NSNumber(value: missingFunds )) ?? ""
                confirmMissingFunds(title: "Verify Missing Funds", message: "Is this the correct amount missing that will be pursued to collect?\n\n Insurance Still Owes Homeowner:\n" + currencyFormat)
            }
        }
        // Do something
        print("switch value changed \(value)")
    }
    
    func confirmMissingFunds(_ action: UIAlertAction) {
        isMissingFunds = true
        missingFundsSwitch.isOn = true
        print("confirmMissingFunds isMissingFunds: " +  String(isMissingFunds))
    }
    
    func cancelMissingFunds(_ action: UIAlertAction) {
        isMissingFunds = false
        missingFundsSwitch.isOn = false
        print("cancelMissingFunds isMissingFunds: " +  String(isMissingFunds))
    }
    
    
    // create image picker option profile picture
    // lazy var enables self to be something other than nil, so that handleSelectPhoto actually works
    lazy var fileImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "file_photo_empty"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = imageView.frame.width / 3
        imageView.layer.borderWidth = 0
        // to make user image interactive so user can choose a photo
        imageView.isUserInteractionEnabled = true
        // similar to button handler, need user to be able to gesture to open up images
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectPhoto)))
        return imageView
    }()
    
    // this function styles the images, a shortcut to avoid redundancy and copying and pasting code
    private func setupCircularStyle() {
        // make image circular
        fileImageView.layer.cornerRadius = fileImageView.frame.width / 3
        // this makes it so that image actually gets clipped off outside of the circle
        fileImageView.clipsToBounds = true
        // add circular border outline around image
        //fileImageView.layer.borderColor = UIColor.darkBlue.cgColor //border color expects a cgcolor (coregraphics color)
        fileImageView.layer.borderWidth = 0
    }
    @objc private func handleSelectPhoto() {
        print("trying to select photo...")
        
        // pop up for user to choose photo from their campera roll
        let imagePickerController = UIImagePickerController()
        let barApperance = UINavigationBar.appearance()
        barApperance.tintColor = .lightRed
        imagePickerController.delegate = self
        imagePickerController.navigationBar.isTranslucent = false
        // allow editing of photo
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    // when user selects photo have a cancel option
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    // get image user selects
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print(info) // info contains image we are selecting
        // to get image out of info dictionary
        // if the image is edited, then use the edited image, otherwise use the original image
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            fileImageView.image = editedImage
            
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // set image if it has not been edited
            fileImageView.image = originalImage
        }
        // call function that styles the image
        setupCircularStyle()
        // dismiss entire view image controller
        dismiss(animated: true, completion: nil)
        
    }
    
    // create tap to change photo label
    let tapToChangeLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to change picture"
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = .lightGray
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    // create file name label
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "NAME"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create text field for name entry
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter name",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    // create COC total label
    let cocLabel: UILabel = {
        let label = UILabel()
        label.text = "COC TOTAL"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // create COC total label
    let coc$: UILabel = {
        let label = UILabel()
        label.text = "$"
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // create text field for coc entry
    let cocTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter coc",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        textField.setLeftPaddingPoints(17)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = UIKeyboardType.decimalPad
        return textField
    }()
    // create invoice total label
    let invoiceLabel: UILabel = {
        let label = UILabel()
        label.text = "INVOICE TOTAL"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create COC total label
    let invoice$: UILabel = {
        let label = UILabel()
        label.text = "$"
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // create text field for coc entry
    let invoiceTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter invoice",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        textField.setLeftPaddingPoints(17)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = UIKeyboardType.decimalPad
        return textField
    }()
    // create deductible total label
    let deductibleLabel: UILabel = {
        let label = UILabel()
        label.text = "DEDUCTIBLE TOTAL"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // create COC total label
    let deductible$: UILabel = {
        let label = UILabel()
        label.text = "$"
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // create text field for coc entry
    let deductibleTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter deductible",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        textField.setLeftPaddingPoints(17)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = UIKeyboardType.decimalPad
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
    
    // final COC Label
    let finalCOCLabel: UILabel = {
        let label = UILabel()
        label.text = "FINAL COC"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    
    // final COC Switch
    let finalCOCSwitch: UISwitch = {
        let mySwitch = UISwitch()
        mySwitch.onTintColor = UIColor.lightRed
        mySwitch.translatesAutoresizingMaskIntoConstraints = false
        return mySwitch
        
    }()
    

    let missingFundsLabel: UILabel = {
        let label = UILabel()
        label.text = "IN PURSUIT OF MISSING FUNDS"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()

    let missingFundsSwitch: UISwitch = {
        let mySwitch = UISwitch()
        mySwitch.onTintColor = UIColor.lightRed
        mySwitch.translatesAutoresizingMaskIntoConstraints = false
        mySwitch.addTarget(self, action: #selector(switchIsChanged(mySwitch:)), for: UIControl.Event.valueChanged)
        return mySwitch
        
    }()
    
    // check type segmented viewing filter
    let fileTypeSegmentedControl: UISegmentedControl = {

        let types = ["Open","Closed"]
        let sc = UISegmentedControl(items: types)
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
    
    lazy var contentViewSize = CGSize(width: self.view.frame.width, height: self.view.frame.height +   165)
    // add scroll to view controller
    lazy var scrollView : UIScrollView = {
        let view = UIScrollView(frame : .zero)
        view.frame = self.view.bounds
        view.contentInsetAdjustmentBehavior = .never
        view.contentSize = contentViewSize
        view.backgroundColor = .white
        return view
    }()
    
    lazy var containerView : UIView = {
        let view = UIView()
        view.frame.size = contentViewSize
        view.backgroundColor = .white
        return view
    }()
    
    // all code to add any layout UI elements
    private func setupUI() {
        self.view.addSubview(scrollView)
        scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        self.scrollView.addSubview(containerView)
        containerView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        containerView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        //add image picker view
        view.addSubview(fileImageView)
        // gives padding of image from top
        fileImageView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        fileImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        fileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        fileImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        // add and position name label
        view.addSubview(tapToChangeLabel)
        tapToChangeLabel.topAnchor.constraint(equalTo: fileImageView.bottomAnchor, constant: 3).isActive = true
        tapToChangeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(fileTypeSegmentedControl)
        fileTypeSegmentedControl.topAnchor.constraint(equalTo: tapToChangeLabel.bottomAnchor, constant: 20).isActive = true
        fileTypeSegmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        fileTypeSegmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        fileTypeSegmentedControl.heightAnchor.constraint(equalToConstant: 34).isActive = true
        
        // add and position name label
        view.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: fileTypeSegmentedControl.bottomAnchor, constant: 20).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        view.addSubview(nameTextField)
        nameTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        nameTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        nameTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // add and position deductible label
        view.addSubview(deductibleLabel)
        deductibleLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20).isActive = true
        deductibleLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        view.addSubview(deductible$)
        deductible$.topAnchor.constraint(equalTo: deductibleLabel.bottomAnchor).isActive = true
        deductible$.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        deductible$.heightAnchor.constraint(equalToConstant: 40).isActive = true
        deductible$.widthAnchor.constraint(equalToConstant: 15).isActive = true
        
        // add and position deductible textfield element to the right of the nameLabel
        view.addSubview(deductibleTextField)
        deductibleTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        deductibleTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        deductibleTextField.topAnchor.constraint(equalTo: deductibleLabel.bottomAnchor).isActive = true
        deductibleTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        // add and position coc label
        view.addSubview(cocLabel)
        cocLabel.topAnchor.constraint(equalTo: deductibleTextField.bottomAnchor, constant: 20).isActive = true
        cocLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        cocLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        
        view.addSubview(coc$)
        coc$.topAnchor.constraint(equalTo: cocLabel.bottomAnchor).isActive = true
        coc$.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        coc$.heightAnchor.constraint(equalToConstant: 40).isActive = true
        coc$.widthAnchor.constraint(equalToConstant: 15).isActive = true
        
        // add and position coc textfield element to the right of the nameLabel
        view.addSubview(cocTextField)
        cocTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        //cocTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        cocTextField.topAnchor.constraint(equalTo: cocLabel.bottomAnchor).isActive = true
        cocTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cocTextField.widthAnchor.constraint(equalToConstant: 150).isActive = true
        
        // add and position invoice label
        view.addSubview(invoiceLabel)
        invoiceLabel.topAnchor.constraint(equalTo: deductibleTextField.bottomAnchor, constant: 20).isActive = true
        invoiceLabel.leftAnchor.constraint(equalTo: cocLabel.rightAnchor, constant: 16).isActive = true
        
        view.addSubview(invoice$)
        invoice$.topAnchor.constraint(equalTo: invoiceLabel.bottomAnchor).isActive = true
        invoice$.leftAnchor.constraint(equalTo: cocTextField.rightAnchor, constant: 16).isActive = true
        invoice$.heightAnchor.constraint(equalToConstant: 40).isActive = true
        invoice$.widthAnchor.constraint(equalToConstant: 15).isActive = true
        
        // add and position invoice textfield element to the right of the nameLabel
        view.addSubview(invoiceTextField)
        invoiceTextField.leftAnchor.constraint(equalTo: cocTextField.rightAnchor, constant: 16).isActive = true
        invoiceTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        invoiceTextField.topAnchor.constraint(equalTo: invoiceLabel.bottomAnchor).isActive = true
        invoiceTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(notesLabel)
        notesLabel.topAnchor.constraint(equalTo: invoiceTextField.bottomAnchor, constant: 20).isActive = true
        notesLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        // add and position item price textfield element to the right of the itemPriceLabel
        view.addSubview(notesTextField)
        notesTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        notesTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        notesTextField.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 10).isActive = true
        notesTextField.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        view.addSubview(finalCOCLabel)
        finalCOCLabel.topAnchor.constraint(equalTo: notesTextField.bottomAnchor, constant: 30).isActive = true
        finalCOCLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

        view.addSubview(finalCOCSwitch)
        finalCOCSwitch.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        finalCOCSwitch.centerYAnchor.constraint(equalTo: finalCOCLabel.centerYAnchor).isActive = true
        
        if file != nil {
            view.addSubview(missingFundsLabel)
            missingFundsLabel.topAnchor.constraint(equalTo: finalCOCLabel.bottomAnchor, constant: 30).isActive = true
            missingFundsLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
            
            view.addSubview(missingFundsSwitch)
            missingFundsSwitch.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
            missingFundsSwitch.centerYAnchor.constraint(equalTo: missingFundsLabel.centerYAnchor).isActive = true
        }



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
    
    private func confirmMissingFunds(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Confirm", style: .cancel, handler: confirmMissingFunds))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: cancelMissingFunds))
        present(alertController, animated: true, completion: nil)
        return
    }
    
    private func removeMissingFunds(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Confirm", style: .cancel, handler: cancelMissingFunds))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: confirmMissingFunds))
        present(alertController, animated: true, completion: nil)
        return
    }
    
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    let hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .dark)
        hud.interactionType = .blockAllTouches
        return hud
    }()
    
    func setScrollableNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.darkBlue
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
}

