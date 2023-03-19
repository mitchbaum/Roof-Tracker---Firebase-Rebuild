//
//  SignInController.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/18/23.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseStorage
import JGProgressHUD

class SignInController: UIViewController {
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
        
        setupUI()
    }
    
    @objc func handleSignIn(sender: UIButton) {
        print("User logging in")
        
        // add animation to the button this is taken from the Utilities.swift file in Helpers folder
        Utilities.animateView(sender)

        // validate the textfields
        let error = validatefields()
        if error != nil {

            return showError(title: "Invalid Entry", message: error!)
        }
        // create cleaned versions of textfields
        let email = usernameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        // signing in the user
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            // style hud
            self.hud.textLabel.text = "Signing In"
            self.hud.show(in: self.view, animated: true)
            if error != nil {
                // dismiss loading hud if there's an error
                self.hud.dismiss(animated: true)
                // couldnt sign in
                self.showError(title: "Unable to sign in", message: error!.localizedDescription)
            } else {
                // dismiss loading hud if there's no error
                self.hud.dismiss(animated: true)
                guard let uid = Auth.auth().currentUser?.uid else { return }
                self.db.collection("Users").document(uid).getDocument(completion: { snapshot, error in
                    if let err = error {
                        debugPrint("Error fetching profile: \(err)")
                    } else {
                        if let data = snapshot?.data() {
                            let companyId = data["companyId"] as? String
                            
                            if companyId != "" {
                                
                                return self.setTabsRoot()
                            } else {

                                return self.setNoTabsRoot()
                            }
                        }
                    }
                })
                
            }
        }
        
        
        
    }
    
    func setTabsRoot() {
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
    
    func validatefields() -> String? {
        // validate the textfields
        if usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please fill in all fields."
        }
        return nil
    }
    
    
    @objc func handleCreateUser(sender: UIButton) {
        print("Creating new user")
        
        // add animation to the button
        Utilities.animateView(sender)
        

        let createUserController = CreateUserController()
        // push into new viewcontroller
        navigationController?.pushViewController(createUserController, animated: true)


        
    }
    
    
    @objc func handleForgotPassword(sender: UIButton) {
        print("Forgot password button pressed")
        
        // add animation to the button
        Utilities.animateView(sender)
        
        let forgotPasswordController = ForgotPasswordController()
        let navController = CustomNavigationController(rootViewController: forgotPasswordController)
        // push into new viewcontroller
        present(navController, animated: true, completion: nil)
    }
    
    lazy var logInImageView: UIImageView = {
        //let imageView = UIImageView(image: "🏋".image(fontSize: 100, bgColor: .darkGray, imageSize: CGSize(width: 100, height: 110)))
        let imageView = UIImageView(image: #imageLiteral(resourceName: "logo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = UIColor.lightRed
//        imageView.layer.cornerRadius = imageView.frame.width / 3
//        imageView.layer.borderWidth = 1
        return imageView
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Proceed with your"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .light)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    

    
    let loginLabel: UILabel = {
        let label = UILabel()
        label.text = "Login"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let usernameIcon: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "username_icon"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "EMAIL"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    

    // create text field for username
    let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "Enter email",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.textColor = .darkGray
//        textField.layer.borderWidth = 2
//        textField.layer.borderColor = UIColor.yellow.cgColor
//        textField.layer.cornerRadius = 10
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        //textField.setLeftPaddingPoints(10)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let passowrdIcon: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "password_icon"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
        
    }()
    
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
//        textField.layer.borderWidth = 2
//        textField.layer.borderColor = UIColor.yellow.cgColor
//        textField.layer.cornerRadius = 10
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        textField.isSecureTextEntry.toggle()
        //textField.setLeftPaddingPoints(10)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    
    // create button for log in
    let signinButton: UIButton = {
        let button = UIButton()
        

        button.backgroundColor = UIColor.lightRed
//        button.layer.borderColor = UIColor.beerOrange.cgColor
//        button.layer.borderWidth = 2
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleSignIn(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // create button for creating a new user
    let createUserButton: UIButton = {
        let button = UIButton()
        

        //button.backgroundColor = UIColor.logoRed
        button.layer.borderColor = UIColor.lightRed.cgColor
        button.layer.borderWidth = 2
        button.setTitle("Create Account", for: .normal)
        button.setTitleColor(.lightRed, for: .normal)
        button.addTarget(self, action: #selector(handleCreateUser(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // create button for forgot password
    let forgotPasswordButton: UIButton = {
        let button = UIButton()
        
        //button.backgroundColor = UIColor.green
        button.setTitle("Forgot Password?", for: .normal)
        button.setTitleColor(.lightRed, for: .normal)
        //button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(handleForgotPassword(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var contentViewSize = CGSize(width: self.view.frame.width, height: self.view.frame.height + 0)
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
    
    private func setupUI() {
    
        self.view.addSubview(scrollView)
        
        self.scrollView.addSubview(containerView)
        
        view.addSubview(logInImageView)
        // gives padding of image from top
        logInImageView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 40).isActive = true
        logInImageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 18).isActive = true
        logInImageView.heightAnchor.constraint(equalToConstant: 125).isActive = true
        logInImageView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        
        view.addSubview(messageLabel)
        messageLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        messageLabel.topAnchor.constraint(equalTo: logInImageView.bottomAnchor, constant: 15).isActive = true
        
        view.addSubview(loginLabel)
        loginLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        loginLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 3).isActive = true
        
        view.addSubview(usernameLabel)
        usernameLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        usernameLabel.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 35).isActive = true


        view.addSubview(usernameTextField)
        //crewButton.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 10).isActive = true
        usernameTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        //usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //usernameTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30).isActive = true
        usernameTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        usernameTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        usernameTextField.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor).isActive = true
        
        view.addSubview(usernameIcon)
        usernameIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        usernameIcon.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 7).isActive = true
        usernameIcon.heightAnchor.constraint(equalToConstant: 23).isActive = true
        usernameIcon.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        view.addSubview(passwordLabel)
        passwordLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        passwordLabel.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 30).isActive = true
        
        //add password textfield
        view.addSubview(passwordTextField)
        passwordTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        passwordTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        passwordTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor).isActive = true
        
        view.addSubview(passowrdIcon)
        passowrdIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        passowrdIcon.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 7).isActive = true
        passowrdIcon.heightAnchor.constraint(equalToConstant: 23).isActive = true
        passowrdIcon.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        
        //add log in button
        view.addSubview(signinButton)
        //crewButton.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 10).isActive = true
        signinButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signinButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        signinButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        signinButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 60).isActive = true
        
        //add ceate org button
        view.addSubview(createUserButton)
        //crewButton.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 10).isActive = true
        createUserButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        createUserButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        createUserButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        createUserButton.topAnchor.constraint(equalTo: signinButton.bottomAnchor, constant: 15).isActive = true
        
        //add log in button
        view.addSubview(forgotPasswordButton)
        forgotPasswordButton.topAnchor.constraint(equalTo: createUserButton.bottomAnchor, constant: 15).isActive = true
        forgotPasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //forgotPasswordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15).isActive = true
        

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
