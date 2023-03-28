//
//  OutOfDateController.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/28/23.
//
import UIKit


class OutOfDateController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    @objc func handleUpdate(sender: UIButton) {
        print("update button pressed")
        
        // add animation to the button this is taken from the Utilities.swift file in Helpers folder
        Utilities.animateView(sender)
        let urlStr = "itms-apps://itunes.apple.com/app/id1626674643"
        if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: urlStr)!, options: [:], completionHandler: nil)
                
            } else {
                UIApplication.shared.openURL(URL(string: urlStr)!)
            }
        
        
    }
    
    
    
    lazy var logInImageView: UIImageView = {
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
        label.text = "Your app is out of date!\nGo to the app store to update."
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .light)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    let updateButton: UIButton = {
        let button = UIButton()
        

        button.backgroundColor = UIColor.lightRed
//        button.layer.borderColor = UIColor.beerOrange.cgColor
//        button.layer.borderWidth = 2
        button.setTitle("Update", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleUpdate(sender:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        // enable autolayout
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(logInImageView)
        // gives padding of image from top
        logInImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40).isActive = true
        logInImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        logInImageView.heightAnchor.constraint(equalToConstant: 125).isActive = true
        logInImageView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        
        view.addSubview(messageLabel)
        messageLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        messageLabel.topAnchor.constraint(equalTo: logInImageView.bottomAnchor, constant: 15).isActive = true
        
        view.addSubview(updateButton)
        //crewButton.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 10).isActive = true
        updateButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        updateButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
        updateButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -32).isActive = true
        updateButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 60).isActive = true
        
    }
}
