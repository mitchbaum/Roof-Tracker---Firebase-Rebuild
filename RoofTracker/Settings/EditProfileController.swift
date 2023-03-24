//
//  EditProfile.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 6/29/22.
//

import UIKit
import CoreData
import FirebaseAuth
import Firebase
import FirebaseDatabase
import JGProgressHUD
import FirebaseStorage

protocol editProfileControllerDelegate {
    func refreshSettingsView()
}

class EditProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var delegate: editProfileControllerDelegate?
    let db = Firestore.firestore()
    var filesCollectionRef: CollectionReference!
    

    


    override func viewDidLoad() {
        print("here")
        super.viewDidLoad()
        // set up label position in view controller
        setupUI()
        fetchUserData()
        
        // create title for this view controller
        navigationItem.title = "Edit Profile"
    
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
    
    // fetch crew member data frome Firebase
    func fetchUserData() {
        print("fetching data")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Users").document(uid).getDocument { (snapshot, error) in
            if let data = snapshot?.data() {
                guard let name = data["name"] as? String else { return }
                guard let email = data["email"] as? String else { return }
                
                // download the user profile picture image from Firestore
                // user this code below whenever trying to download an image from firebase
                if let profilePic = data["profile pic url"] as? String {
                    let url = NSURL(string: profilePic)
                    URLSession.shared.dataTask(with: url! as URL, completionHandler: { (data, response, error) in
                        if error != nil {
                            print(error ?? "")
                            return
                        }
                        // run image setter on main queue
                        DispatchQueue.main.async {
                            self.userImageView.image = UIImage(data: data!)
                        }
                    }).resume()
                    self.setupCircularStyle()
                }
                
                
                self.nameTextField.text = name
                self.emailTextField.text = email

                
            }
        }
    }
    
    
    
    // save function
    @objc private func handleSave() {
        print("saving account...")
        // check the uid is a string
        let email = Auth.auth().currentUser?.email
        let currentUser = Auth.auth().currentUser
        // check that theres actually an email entered in the textfield
        if nameTextField.text != nil && emailTextField.text != nil {
            let cleanedEmail = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            if Utilities.isValidEmail(cleanedEmail) == false {
                return showError(title: "Invalid Email", message: "Double check your email entry.")
            } else {
                guard let uid = Auth.auth().currentUser?.uid else { return }
                db.collection("Users").document(uid).getDocument { (snapshot, error) in
                    if (snapshot?.data()) != nil {
                        print("user data loaded")
                        if let stockImage = UIImage(named: "username_icon") {
                            let stockData = stockImage.pngData()
                            let userInputData = self.userImageView.image?.pngData()
                            if stockData != userInputData {
                                print("profile picture is different than stock photo")
                                let storageRef = Storage.storage().reference().child("user profile photos/\(uid).png")
                                
                                if let uploadData = self.userImageView.image!.jpegData(compressionQuality: 0.8) {
                                    print("getting image jpeg data at lowest compression")
                                    storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                                        if error != nil {
                                            print(error ?? "")
                                            return
                                        }
                                        print(metadata ?? "")
                                    
                                        storageRef.downloadURL { (url, error) in
                                            guard let url = url, error == nil else {
                                                self.showError(title: "ERROR", message: error.debugDescription)
                                                return
                                            }
                                            let urlString = url.absoluteString
                                            print("Download URL: \(urlString)")
                                            self.db.collection("Users").document(uid).updateData(["profile pic url" : urlString])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                db.collection("Users").document(uid).updateData(["name" : nameTextField.text!])
                if emailTextField.text != email {
                    currentUser?.updateEmail(to: emailTextField.text!, completion: { [self] (err) in
                        if let err = err {
                            print(err)
                        } else {
                            self.db.collection("Users").document(uid).updateData(["email" : emailTextField.text!])
                        }
                    })
                }
            }
        }
        dismiss(animated: true) {
                        self.delegate?.refreshSettingsView()
                    }
        
    }
    
    
    
    
    // create image picker option profile picture
    // lazy var enables self to be something other than nil, so that handleSelectPhoto actually works
    lazy var userImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "username_icon"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.borderWidth = 2
        // to make user image interactive so user can choose a photo
        imageView.isUserInteractionEnabled = true
        // similar to button handler, need user to be able to gesture to open up images
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectPhoto)))
        return imageView
    }()
    
    // this function styles the images, a shortcut to avoid redundancy and copying and pasting code
    private func setupCircularStyle() {
        // make image circular
        userImageView.layer.cornerRadius = 50
        // this makes it so that image actually gets clipped off outside of the circle
        userImageView.clipsToBounds = true
        // add circular border outline around image
        //fileImageView.layer.borderColor = UIColor.black.cgColor //border color expects a cgcolor (coregraphics color)
        userImageView.layer.borderWidth = 0
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
            print("changed photo")
            userImageView.image = editedImage
            
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            print("did not change photo")
            // set image if it has not been edited
            userImageView.image = originalImage
        }
        // call function that styles the image
        setupCircularStyle()
        // dismiss entire view image controller
        dismiss(animated: true, completion: nil)
        
    }
    
    // create tap to change photo label
    let tapToChangeLabel: UILabel = {
        let label = UILabel()
        label.text = "Change profile photo"
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = .lightGray
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    // create file name label
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "FULL NAME"
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
    
    // create file name label
    let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "EMAIL"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create text field for name entry
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter email",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // create tap to change photo label
    let changeEmailLabel: UILabel = {
        let label = UILabel()
        label.text = "This operation is sensitive. Please re-login to complete email modification."
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = .lightGray
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    // add scroll to view controller
    let scrollView : UIScrollView = {
        let view = UIScrollView()
        //view.frame = self.view.bounds
        //view.contentInsetAdjustmentBehavior = .never
        view.translatesAutoresizingMaskIntoConstraints = false
        //view.contentSize = contentViewSize
        view.backgroundColor = .white
        return view
    }()
    
    let containerView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        //view.frame.size = contentViewSize
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
        view.addSubview(userImageView)
        // gives padding of image from top
        userImageView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        userImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        userImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        // add and position name label
        view.addSubview(tapToChangeLabel)
        tapToChangeLabel.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 5).isActive = true
        tapToChangeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        
        // add and position name label
        view.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: tapToChangeLabel.bottomAnchor, constant: 20).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        view.addSubview(nameTextField)
        nameTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        nameTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        nameTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // add and position name label
        view.addSubview(emailLabel)
        emailLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20).isActive = true
        emailLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        view.addSubview(emailTextField)
        emailTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        emailTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        emailTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor).isActive = true
        emailTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(changeEmailLabel)
        changeEmailLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 5).isActive = true
        changeEmailLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        changeEmailLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        

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
