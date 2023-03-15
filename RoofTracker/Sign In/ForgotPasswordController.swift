//
//  ForgotPasswordController.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 5/20/22.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseStorage
import JGProgressHUD


class ForgotPasswordController: UIViewController {
    
    //create variable to reference the firebase data so we can read, wirte and update it
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        navigationItem.title = " "
        hideNavigationBar(animated: false)
        navigationController?.transparentNavigationBar()
        navigationController?.setTintColor(.lightRed)
        
        view.backgroundColor = UIColor.white
        navigationItem.largeTitleDisplayMode = .never
        
        // add cancel button to dismiss view
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleCancel))
        
        setupUI()
        dismissKeyboardGesture()
    }

    
    @objc func handleSendResetPassword(sender: UIButton) {
        // add animation to the button
        Utilities.animateView(sender)
        print("sending password reset email...")
    
        
        if emailTextField.text != "" {
            // style hud
            hud.textLabel.text = "Sending..."
            hud.show(in: view, animated: true)
            Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { (error) in
                if let error = error {
                    // dismiss loading hud if there's an error
                    self.hud.dismiss(animated: true)
                    return self.showError(title: "Unable to Send Password Reset Email", message: "\(error.localizedDescription) Please double check your email address.")
                } else {
                    self.hud.dismiss(animated: true)
                    print("done")
                    let alert = UIAlertController(title: "Sent", message: "A password reset email has been sent to \(self.emailTextField.text!).", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                        self.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            return self.showError(title: "No Email Address Entered", message: "Please enter a valid email address to proceed.")
        }
    }
    
    @objc func handleBack(sender: UIButton) {
        print("creating new user")
        Utilities.animateView(sender)

        dismiss(animated: true, completion: nil)
        
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
        label.text = "Proceed with your email to"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .light)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    

    
    let resetPasswordLabel: UILabel = {
        let label = UILabel()
        label.text = "Reset Password"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let emailIcon: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "email_icon"))
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
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.addLine(position: .bottom, color: .lightRed, width: 1)
        // enable autolayout, without this constraints wont load properly
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    

    // send button for email rest
    let sendButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.lightRed
        button.setTitle("Send Password Reset", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleSendResetPassword(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // all code to add any layout UI elements
    private func setupUI() {
        
        view.addSubview(backButton)
        backButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 25).isActive = true
        backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        
        view.addSubview(messageLabel)
        messageLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        messageLabel.topAnchor.constraint(equalTo: backButton.safeAreaLayoutGuide.bottomAnchor, constant: 40).isActive = true
        
        view.addSubview(resetPasswordLabel)
        resetPasswordLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        resetPasswordLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 3).isActive = true
        
        view.addSubview(emailLabel)
        emailLabel.topAnchor.constraint(equalTo: resetPasswordLabel.bottomAnchor, constant: 80).isActive = true
        emailLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        
        view.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor).isActive = true
        emailTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        emailTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        emailTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        view.addSubview(emailIcon)
        emailIcon.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        emailIcon.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 7).isActive = true
        emailIcon.heightAnchor.constraint(equalToConstant: 23).isActive = true
        emailIcon.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        
        view.addSubview(sendButton)
        sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        sendButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        sendButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        sendButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 40).isActive = true
        
    }
    
    // create alert that will present an error, this can be used anywhere in the code to remove redundant lines of code
    private func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        return
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // add loading HUD status for when fetching data from server
    let hud: JGProgressHUD = {
        let hud = JGProgressHUD(style: .dark)
        hud.interactionType = .blockAllTouches
        return hud
    }()
    
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



