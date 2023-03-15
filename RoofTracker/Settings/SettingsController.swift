//
//  SettingsController.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 5/20/22.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseStorage
import JGProgressHUD

class SettingsController: UIViewController, editProfileControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let db = Firestore.firestore()
    
    var sortValue = "Name"
    
    var userEmail = ""
    
    let years = ["2022", "2021", "2020"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationItem.title = "Settings"
        //navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor.darkBlue
        navigationController?.transparentNavigationBar()
        navigationController?.setTintColor(.white)
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        
        
        // add cancel button to dismiss view
        let save = UIBarButtonItem(title: NSString(string: "Done") as String, style: .plain, target: self, action: #selector(handleSave))
        
        navigationItem.rightBarButtonItems = [save]
        
        yearTextField.inputView = yearPicker
        yearPicker.delegate = self
        yearPicker.dataSource = self
        
        setupUI()
        fetchProfileData()

    }

    
    func refreshSettingsView() {
        fetchProfileData()
    }
    
    
    func fetchProfileData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Users").document(uid).getDocument(completion: { snapshot, error in
            if let err = error {
                debugPrint("Error fetching profile: \(err)")
            } else {
                if let data = snapshot?.data() {
                    let name = data["name"] as? String
                    let email = data["email"] as? String
                    let access = data["access"] as? String
                    let companyId = data["companyId"] as? String
                    
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
                    
                    
                    self.nameLabel.text = name
                    self.emailLabel.text = email
                    self.userEmail = email!
                    
                    if companyId != "" {
                        self.accessLabel.text = access
                        return self.fetchCompany(companyId: companyId!)
                    } else {
                        self.accessLabel.text = "Independent"
                    }

                }
            }
        })
        
    }
    
    func fetchCompany(companyId: String) {
        db.collection("Companies").document(companyId).getDocument(completion: { snapshot, error in
            if let err = error {
                debugPrint("Error fetching profile: \(err)")
            } else {
                if let data = snapshot?.data() {
                    let name = data["name"] as? String
                    self.companyLabel.text = name
                }
            }
        })
        
        
    }
    
    @objc private func handleSave() {
        print("done with settings")
        // update changes to data in Firebase
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        self.db.collection("Users").document(uid).updateData(["year" : self.yearTextField.text ?? ""])
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleForgotPassword(sender: UIButton) {
        print("Forgot password button pressed")
        Utilities.animateView(sender)
        let signOutAction = UIAlertAction(title: "Send Password Reset Email", style: .default) { (action) in
            do {
                self.hud.textLabel.text = "Sending..."
                self.hud.show(in: self.view, animated: true)
                Auth.auth().sendPasswordReset(withEmail: self.userEmail) { (error) in
                    if let error = error {
                        // dismiss loading hud if there's an error
                        self.hud.dismiss(animated: true)
                        return self.showError(title: "Unable to Send Password Reset Email", message: "\(error.localizedDescription) Please contact support.")
                    } else {
                        self.hud.dismiss(animated: true)
                        print("done")
                        let alert = UIAlertController(title: "Sent", message: "A password reset email has been sent to \(self.userEmail).", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                            self.dismiss(animated: true, completion: nil)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        // alert
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        optionMenu.addAction(signOutAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
        
        let forgotPasswordController = ForgotPasswordController()
        let navController = CustomNavigationController(rootViewController: forgotPasswordController)
        // push into new viewcontroller
        present(navController, animated: true, completion: nil)
    }
    
    @objc func handleSignOut(sender: UIButton) {
        print("org signing out")
        Utilities.animateView(sender)
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { (action) in
            do {
                try Auth.auth().signOut()
                self.dismiss(animated: true, completion: nil)
                //self.presentingViewController?.viewWillAppear(true)
                print("org signed out")
            } catch let err {
                print("Failed to sign out with error ", err)
                self.showError(title: "Sign Out Error", message: "Please try again.")
            }
        }
        // alert
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        optionMenu.addAction(signOutAction)
        optionMenu.addAction(cancelAction)
        addActionSheetForiPad(actionSheet: optionMenu)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @objc func handleEditProfile(sender: UIButton) {
        print("editing profile")
        let editProfileController = EditProfileController()
        editProfileController.delegate = self
        let navController = CustomNavigationController(rootViewController: editProfileController)
        self.present(navController, animated: true, completion: nil)
        
    }
    
    lazy var userImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "username_icon_white"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.cornerRadius = 30 // this value needs to be half the size of the height to make the image circular
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.backgroundColor = UIColor(red: 41/255, green: 51/255, blue: 72/255, alpha: 1)

        return imageView
    }()
    
    // this function styles the images, a shortcut to avoid redundancy and copying and pasting code
    private func setupCircularStyle() {
        // make image circular
        userImageView.layer.cornerRadius = 30
        // this makes it so that image actually gets clipped off outside of the circle
        userImageView.clipsToBounds = true
        userImageView.contentMode = .scaleAspectFill
        // add circular border outline around image
        //fileImageView.layer.borderColor = UIColor.black.cgColor //border color expects a cgcolor (coregraphics color)
        userImageView.layer.borderWidth = 0
    }
    
    
    // create button for log in
    let editIcon: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red: 41/255, green: 51/255, blue: 72/255, alpha: 1)
        //button.backgroundColor = .white
        button.layer.cornerRadius = 15
//        button.layer.borderColor = UIColor.lightRed.cgColor
//        button.layer.borderWidth = 0.5
        button.setTitle("✎", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleEditProfile(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // create email label
    let accessLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .lightRed
        label.layer.borderColor = UIColor.lightRed.cgColor
        label.layer.borderWidth = 1.0
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 20)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    let emailLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .white
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let companyLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .lightGray
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let signOutLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign Out"
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    // create button for log in
    let signoutButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.lightRed
//        button.layer.borderColor = UIColor.beerOrange.cgColor
//        button.layer.borderWidth = 2
        button.setTitle("➦", for: .normal)
        button.layer.cornerRadius = 10
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleSignOut(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 40.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let resetPasswordLabel: UILabel = {
        let label = UILabel()
        label.text = "Reset Password"
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create button for log in
    let resetPasswordButton: UIButton = {
        let button = UIButton()
        //button.backgroundColor = UIColor.lightBlue
        button.layer.borderColor = UIColor.lightRed.cgColor
        button.layer.borderWidth = 1.5
        button.layer.cornerRadius = 10
        button.setTitle("↺", for: .normal)
        button.setTitleColor(.lightRed, for: .normal)
        button.addTarget(self, action: #selector(handleForgotPassword(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 40.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    // create year label
    let yearLabel: UILabel = {
        let label = UILabel()
        label.text = "SET YEAR"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let yearIcon: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "down_arrow"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
    // create text field for year entry
    let yearTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Select year",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // create year picker view
    let yearPicker: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()

    

    private func setupUI() {
        let topWhiteBackgroundView = UIView()
        topWhiteBackgroundView.backgroundColor = UIColor.white
        topWhiteBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topWhiteBackgroundView)
    
        topWhiteBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        topWhiteBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        
        
        view.addSubview(userImageView)
        userImageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        userImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        userImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        view.addSubview(editIcon)
        editIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        editIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25).isActive = true
        
        
        view.addSubview(accessLabel)
        accessLabel.leftAnchor.constraint(equalTo: userImageView.rightAnchor, constant: 20).isActive = true
        accessLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30).isActive = true
        accessLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
        accessLabel.widthAnchor.constraint(equalToConstant: 110).isActive = true
        
        view.addSubview(nameLabel)
        nameLabel.leftAnchor.constraint(equalTo: userImageView.rightAnchor, constant: 20).isActive = true
        nameLabel.topAnchor.constraint(equalTo: accessLabel.bottomAnchor, constant: 10).isActive = true
    
        userImageView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        
        view.addSubview(emailLabel)
        emailLabel.leftAnchor.constraint(equalTo: userImageView.rightAnchor, constant: 20).isActive = true
        emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true
        
        view.addSubview(companyLabel)
        companyLabel.leftAnchor.constraint(equalTo: userImageView.rightAnchor, constant: 20).isActive = true
        companyLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 5).isActive = true
        
        topWhiteBackgroundView.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 30).isActive = true
        
        
        view.addSubview(signoutButton)
        signoutButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        signoutButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        signoutButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: -71).isActive = true
        signoutButton.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 60).isActive = true
        
        view.addSubview(signOutLabel)
        signOutLabel.centerXAnchor.constraint(equalTo: signoutButton.centerXAnchor).isActive = true
        signOutLabel.topAnchor.constraint(equalTo: signoutButton.bottomAnchor, constant: 6).isActive = true
        
        view.addSubview(resetPasswordButton)
        resetPasswordButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        resetPasswordButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        resetPasswordButton.leftAnchor.constraint(equalTo: signoutButton.rightAnchor, constant: 42).isActive = true
        resetPasswordButton.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 60).isActive = true
        
        view.addSubview(resetPasswordLabel)
        resetPasswordLabel.centerXAnchor.constraint(equalTo: resetPasswordButton.centerXAnchor).isActive = true
        resetPasswordLabel.topAnchor.constraint(equalTo: resetPasswordButton.bottomAnchor, constant: 6).isActive = true
        
        topWhiteBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // uncomment when you want to add things here --START
        
//        let bottomWhiteBackgroundView = UIView()
//        bottomWhiteBackgroundView.backgroundColor = UIColor.white
//        bottomWhiteBackgroundView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(bottomWhiteBackgroundView)
//
//        bottomWhiteBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
//        bottomWhiteBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
//
//        bottomWhiteBackgroundView.topAnchor.constraint(equalTo: topWhiteBackgroundView.bottomAnchor, constant: 6).isActive = true
//        bottomWhiteBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//
//        view.addSubview(yearLabel)
//        yearLabel.topAnchor.constraint(equalTo: bottomWhiteBackgroundView.topAnchor, constant: 20).isActive = true
//        yearLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
//
//        view.addSubview(yearTextField)
//        yearTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
//        yearTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
//        yearTextField.topAnchor.constraint(equalTo: yearLabel.bottomAnchor).isActive = true
//        yearTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
//
//        view.addSubview(yearIcon)
//        yearIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -34).isActive = true
//        yearIcon.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 12).isActive = true
//        yearIcon.heightAnchor.constraint(equalToConstant: 15).isActive = true
//        yearIcon.widthAnchor.constraint(equalToConstant: 15).isActive = true
        
        // uncomment when you want to add things here --END

        
        
        
        
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
    // add loading HUD status for when fetching data from server
    let hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .dark)
        hud.interactionType = .blockAllTouches
        return hud
    }()

}
