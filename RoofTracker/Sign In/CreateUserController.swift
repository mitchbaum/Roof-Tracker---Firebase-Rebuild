//
//  CreateUserController.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 5/20/22.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseStorage
import JGProgressHUD


class CreateUserController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var companies = [" ", "Independent (No company)"]
    
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        // create title for this view controller
        navigationItem.title = " "
        hideNavigationBar(animated: false)
        
        view.backgroundColor = .white
        navigationItem.largeTitleDisplayMode = .never
        //navigationController?.transparentNavigationBar()
        //navigationController?.setTintColor(.lightRed)

        dismissKeyboardGesture()
        fetchCompanies()
        
        companyTextField.inputView = companyPicker
        companyPicker.delegate = self
        companyPicker.dataSource = self

        
        setupUI()
    }
    
    func fetchCompanies() {
        db.collection("Companies").getDocuments { (snapshot, error) in
            if let err = error {
                debugPrint("Error fetching companies: \(err)")
            } else {
                guard let snap = snapshot else { return }
                for document in snap.documents {
                    let data = document.data()
                    
                    let name = data["name"] as? String ?? "No company found"
                    
                    self.companies.append(name)
                }
            }
            
        }
    }
    
    func buildUser() {
        // create cleaned versions of the data
        let email = emailTextField.text!
        let password = passwordTextField.text!
        let name = fullNameTextField.text!
        let company = companyTextField.text ?? companies[1]
        let code = regCodeTextField.text!
        
        if (company == companies[1]) {
            return buildIndependent(email: email, password: password, name: name)
            
        } else {
            return buildWithCompany(email: email, password: password, name: name, company: company, code: code)
        }
        
    }
    
    func buildIndependent(email: String, password: String, name: String) {
        print("building independent user")
        // create the user
        Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
            // check for errors
            if err != nil {
                //  there was an error
                self.hud.dismiss(animated: true)
                return self.showError(title: "Unable to create account", message: "Please try again.")
            } else {
                // org was authenticated successfully, now store the organization name
                self.db.collection("Users").document(result!.user.uid).setData(
                    ["uid" : result!.user.uid,
                     "password" : password,
                     "email" : email,
                     "name" : name,
                     "profile pic url" : "",
                     "organization" : "independent",
                     "access": "Superadmin",
                     "companyId" : "",
                    ])
                { (error) in
                    if error != nil {
                        // show error message
                        self.hud.dismiss(animated: true)
                        return self.showError(title: "Error saving account data", message: "User email wasn't saved.")
                    }
                }



            }

            self.hud.dismiss(animated: true)
            // transition to home screen
            return self.setNoTabsRoot()

        }
    }
    
    func buildWithCompany(email: String, password: String, name: String, company: String, code: String) {
        print("building user with company")
        let companiesRef = db.collection("Companies")
        companiesRef.whereField("name", isEqualTo: company).whereField("code", isEqualTo: code).getDocuments { (snapshot, error) in
            if let err = error {
                debugPrint("Error fetching companies: \(err)")
            } else {
                guard let snap = snapshot else { return }
                print(snap.count)
                if snap.count == 0 {
                    return self.showError(title: "Unable to create account", message: "Invalid company registration code.")
                }
                for document in snap.documents {
                    let data = document.data()
                    
                    let companyId = data["companyId"] as? String ?? "No company found"
                    
                    Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
                        // check for errors
                        if err != nil {
                            //  there was an error
                            self.hud.dismiss(animated: true)
                            return self.showError(title: "Unable to create user", message: "Please try again.")
                        } else {
                            // org was authenticated successfully, now store the organization name
                            self.db.collection("Users").document(result!.user.uid).setData(
                                ["uid" : result!.user.uid,
                                 "password" : password,
                                 "email" : email,
                                 "name" : name,
                                 "profile pic url" : "",
                                 "organization" : "company",
                                 "access": "User",
                                 "companyId" : companyId,
                                ])
                            { (error) in
                                if error != nil {
                                    // show error message
                                    self.hud.dismiss(animated: true)
                                    return self.showError(title: "Error saving account data", message: "User email wasn't saved.")
                                }
                            }



                        }

                        self.hud.dismiss(animated: true)
                        // transition to home screen
                        return self.setTabsRoot()

                    }
                }
            }
            
        }
        
    }
    
    func setTabsRoot() {
        print("in setTabsRoot")
        let tabBar = UITabBarController()
        
        let filesVC = CustomNavigationController(rootViewController: FilesController())
        let teamVC = CustomNavigationController(rootViewController: TeamController())
        
        filesVC.tabBarItem = UITabBarItem(title: "My Files", image: UIImage(systemName: "folder.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), tag: 0)
        teamVC.tabBarItem = UITabBarItem(title: "Team", image: UIImage(systemName: "person.3.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), tag: 1)
        tabBar.setViewControllers([filesVC, teamVC], animated: false)
        tabBar.tabBar.tintColor = UIColor.white
        tabBar.tabBar.backgroundColor = UIColor.darkBlue
        
        // This is to get the SceneDelegate object from your view controller
        // then call the change root view controller function to change to main tab bar
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(tabBar)
    }
    
    func setNoTabsRoot() {
        let filesController = FilesController()
        let navController = CustomNavigationController(rootViewController: filesController)
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(navController)
    }
    
    
    
    @objc func handleCreateUser(sender: UIButton) {
        print("creating new user")
        Utilities.animateView(sender)
        // validate the fields
        let error = validateFields()
        if error != nil {
            // there is something wrong with the fields, show error message
            return showError(title: "Unable to create account", message: error!)
        } else {
            buildUser()
        }
    }
    
    @objc func handleBack(sender: UIButton) {
        print("creating new user")
        Utilities.animateView(sender)
        let transition = CATransition()
         transition.duration = 0.45
         transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
         transition.type = CATransitionType.push
         transition.subtype = CATransitionSubtype.fromLeft
         self.navigationController?.view.layer.add(transition, forKey: kCATransition)
        // validate the fields
        let signInController = SignInController()
        navigationController?.pushViewController(signInController, animated: true)
        
    }

    
    // check the fields and validate that the data is correct. If everything is correct, this method returns nil, otherwise it returns an error message as a string
    func validateFields() -> String? {
        
        if fullNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please enter you name."
        }
        // check if the password is secure
        let cleanedPassword = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if Utilities.isPasswordValid(cleanedPassword) == false {
            // password isnt secure enough
            return "Please make sure your password contains at least 6 characters."
        }
        if passwordTextField.text != reenterPasswordTextField.text {
            return "Passwords do not match."
        }
        
        if companyTextField.text == "" || companyTextField.text == " " {
            return "Please select a company."
        } else if companyTextField.text != companies[1] {
            if regCodeTextField.text?.count == 0 {
                return "Please enter the company 6 digit registration code."
            } else if regCodeTextField.text?.count != 6 {
                return "Registration code must be 6 digits in length."
            }
        }
        
        
        
        // check if email is correct format
        let cleanedEmail = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if Utilities.isValidEmail(cleanedEmail) == false {
            return "Invalid email."
        }
        
        return nil
    }
    
    let backButton: UIButton = {
        let button = UIButton()
        button.setTitle("←", for: .normal)
        button.setTitleColor(.lightRed, for: .normal)
        button.addTarget(self, action: #selector(handleBack(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Fill in all fields to"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .light)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    

    
    let createAccountLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let usernameIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.black, renderingMode: .alwaysOriginal))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
    // create name label
    let fullNameLabel: UILabel = {
        let label = UILabel()
        label.text = "FULL NAME"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // create text field for name entry
    let fullNameTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter full name",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let emailIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "envelope.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.black, renderingMode: .alwaysOriginal))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
    
    // create email label
    let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "EMAIL"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // create text field for email entry
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
    
    let passowrdIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.black, renderingMode: .alwaysOriginal))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
    
    // create password label
    let passwordLabel: UILabel = {
        let label = UILabel()
        label.text = "PASSWORD"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    // create text field for password
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter password",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isSecureTextEntry.toggle()
        return textField
    }()
    
    let reenterPassowrdIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.black, renderingMode: .alwaysOriginal))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.clipsToBounds = true
        return imageView
        
    }()
    // create reenterpassword label
    let reenterPasswordLabel: UILabel = {
        let label = UILabel()
        label.text = "CONFIRM PASSWORD"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create text field for reentered password
    let reenterPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter password",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isSecureTextEntry.toggle()
        return textField
    }()
    

    
    
    let companyLabel: UILabel = {
        let label = UILabel()
        label.text = "COMPANY*"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let companyIcon: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "down_arrow"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
    
    // create text field for reentered password
    let companyTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Select a company...",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // create year picker view
    let companyPicker: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()

    
    let regCodeLabel: UILabel = {
        let label = UILabel()
        label.text = "COMPANY REGISTRATION CODE"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // create text field for reentered password
    let regCodeTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter 6 digit registration code",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = UIKeyboardType.numberPad
        return textField
    }()
    
    let regCodeIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "key.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.black, renderingMode: .alwaysOriginal))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
    
    
    // create button for create account
    let createButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.lightRed
        button.setTitle("Create Account", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleCreateUser(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let astriskLabel: UILabel = {
        let label = UILabel()
        label.text = "*This can be added later"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .darkGray
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        
        self.scrollView.addSubview(containerView)
        
        view.addSubview(backButton)
        backButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 25).isActive = true
        backButton.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        
        view.addSubview(messageLabel)
        messageLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        messageLabel.topAnchor.constraint(equalTo: backButton.safeAreaLayoutGuide.bottomAnchor, constant: 40).isActive = true
        
        view.addSubview(createAccountLabel)
        createAccountLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        createAccountLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 3).isActive = true
        
        // add and position deductible label
        view.addSubview(fullNameLabel)
        fullNameLabel.topAnchor.constraint(equalTo: createAccountLabel.bottomAnchor, constant: 40).isActive = true
        fullNameLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

        // add and position deductible textfield element to the right of the nameLabel
        view.addSubview(fullNameTextField)
        fullNameTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        fullNameTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        fullNameTextField.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor).isActive = true
        fullNameTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(usernameIcon)
        usernameIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        usernameIcon.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor, constant: 7).isActive = true
        usernameIcon.heightAnchor.constraint(equalToConstant: 23).isActive = true
        usernameIcon.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        // add and position deductible label
        view.addSubview(emailLabel)
        emailLabel.topAnchor.constraint(equalTo: fullNameTextField.bottomAnchor, constant: 20).isActive = true
        emailLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

        // add and position deductible textfield element to the right of the nameLabel
        view.addSubview(emailTextField)
        emailTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        emailTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        emailTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor).isActive = true
        emailTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(emailIcon)
        emailIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        emailIcon.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 7).isActive = true
        emailIcon.heightAnchor.constraint(equalToConstant: 23).isActive = true
        emailIcon.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        
        view.addSubview(passwordLabel)
        passwordLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20).isActive = true
        passwordLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

        // add and position coc textfield element to the right of the nameLabel
        view.addSubview(passwordTextField)
        passwordTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant:32).isActive = true
        passwordTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor).isActive = true
        passwordTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(passowrdIcon)
        passowrdIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        passowrdIcon.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 7).isActive = true
        passowrdIcon.heightAnchor.constraint(equalToConstant: 23).isActive = true
        passowrdIcon.widthAnchor.constraint(equalToConstant: 23).isActive = true


        // add and position invoice label
        view.addSubview(reenterPasswordLabel)
        reenterPasswordLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20).isActive = true
        reenterPasswordLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

        // add and position invoice textfield element to the right of the nameLabel
        view.addSubview(reenterPasswordTextField)
        reenterPasswordTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        reenterPasswordTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        reenterPasswordTextField.topAnchor.constraint(equalTo: reenterPasswordLabel.bottomAnchor).isActive = true
        reenterPasswordTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(reenterPassowrdIcon)
        reenterPassowrdIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        reenterPassowrdIcon.topAnchor.constraint(equalTo: reenterPasswordLabel.bottomAnchor, constant: 7).isActive = true
        reenterPassowrdIcon.heightAnchor.constraint(equalToConstant: 23).isActive = true
        reenterPassowrdIcon.widthAnchor.constraint(equalToConstant: 23).isActive = true

        
            
        view.addSubview(companyLabel)
        companyLabel.topAnchor.constraint(equalTo: reenterPasswordTextField.bottomAnchor, constant: 20).isActive = true
        companyLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

           
        view.addSubview(companyTextField)
        companyTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        companyTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        companyTextField.topAnchor.constraint(equalTo: companyLabel.bottomAnchor).isActive = true
        companyTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(companyIcon)
        companyIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -34).isActive = true
        companyIcon.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 12).isActive = true
        companyIcon.heightAnchor.constraint(equalToConstant: 15).isActive = true
        companyIcon.widthAnchor.constraint(equalToConstant: 15).isActive = true
        
        view.addSubview(regCodeLabel)
        regCodeLabel.topAnchor.constraint(equalTo: companyTextField.bottomAnchor, constant: 20).isActive = true
        regCodeLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true

       
        view.addSubview(regCodeTextField)
        regCodeTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        regCodeTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -32).isActive = true
        regCodeTextField.topAnchor.constraint(equalTo: regCodeLabel.bottomAnchor).isActive = true
        regCodeTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(regCodeIcon)
        regCodeIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -34).isActive = true
        regCodeIcon.topAnchor.constraint(equalTo: regCodeLabel.bottomAnchor, constant: 12).isActive = true
        regCodeIcon.heightAnchor.constraint(equalToConstant: 15).isActive = true
        regCodeIcon.widthAnchor.constraint(equalToConstant: 15).isActive = true
        

        view.addSubview(createButton)
        createButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        createButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        createButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        createButton.topAnchor.constraint(equalTo: regCodeTextField.bottomAnchor, constant: 40).isActive = true
        //createButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20.0).isActive = true
            
        view.addSubview(astriskLabel)
        astriskLabel.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 20).isActive = true
        astriskLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
            
    
    }
    
    private func companyRegUI() {
        
    }
    
    
    let hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .dark)
        hud.interactionType = .blockAllTouches
        return hud
    }()
    
    // create alert that will present an error, this can be used anywhere in the code to remove redundant lines of code
    private func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        return
    }
    
    private func dismissKeyboardGesture() {
        // dismiss keyboard when user taps outside of keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        let swipeDown = UIPanGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeDown)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}

