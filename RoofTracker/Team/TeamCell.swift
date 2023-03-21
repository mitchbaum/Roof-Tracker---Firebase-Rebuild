//
//  TeamCell.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/19/23.
//

import UIKit
class TeamCell: UITableViewCell {
    
    var teamMember: TeamMember? { // start off file with nil with ?
        didSet {
            if let profilePicImage = teamMember?.imageData {
                if teamMember?.imageData == "" {
                    userImageView.image = UIImage(named: "username_icon")
                } else {
                    // this places each file image into the cache to retrieve when user goes back to home to use less memory
                    userImageView.loadImageUsingCacheWithUrlString(urlString: profilePicImage)
                    self.setupCircularStyle()
                }
            }
            if teamMember?.name == "" {
                nameLabel.text = " "
            } else {
                nameLabel.text = teamMember?.name
            }
            emailLabel.text = teamMember?.email
            
            
            if teamMember?.missingFundsTotal != nil {
                let currencyFormatter = NumberFormatter()
                currencyFormatter.usesGroupingSeparator = true
                currencyFormatter.numberStyle = .currency
                currencyFormatter.locale = Locale.current
                let missingFunds = currencyFormatter.string(from: NSNumber(value: teamMember?.missingFundsTotal ?? 3466.70))
                messageLabel.text = missingFunds
            }
            
            accessLabel.text = teamMember?.access
            
            
            

        }
    }
    private func setupCircularStyle() {
        // make image circular
        userImageView.layer.cornerRadius = 25
        // this makes it so that image actually gets clipped off outside of the circle
        userImageView.clipsToBounds = true
        userImageView.contentMode = .scaleAspectFill
        // add circular border outline around image
        //fileImageView.layer.borderColor = UIColor.black.cgColor //border color expects a cgcolor (coregraphics color)
        userImageView.layer.borderWidth = 0
    }
    
    let userImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "username_icon_white"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // alters the squashed look to make the image appear normal in the view, fixes aspect ratio
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.cornerRadius = 25 // this value needs to be half the size of the height to make the image circular
        imageView.layer.borderColor = UIColor.black.cgColor
        //imageView.backgroundColor = UIColor(red: 41/255, green: 51/255, blue: 72/255, alpha: 1)

        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 18)
        // label.backgroundColor = .red
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    let emailLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = .darkGray
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightRed
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = .yellow
        return label
    }()
    
    let postMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "In Missing Funds Found"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = .purple
        return label
    }()
    
    let accessLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        //label.font = UIFont.boldSystemFont(ofSize: 10)
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = .blue
        return label
    }()
    
    let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.darkBlue
        addSubview(cardView)
        cardView.topAnchor.constraint(equalTo: topAnchor, constant: 2).isActive = true
        cardView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        cardView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        cardView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2).isActive = true
        
        // placement of the image in cell
        addSubview(userImageView)
        userImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        userImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        userImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        userImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        // placement of file name in cell
        addSubview(nameLabel)
        nameLabel.leftAnchor.constraint(equalTo: userImageView.rightAnchor, constant: 11).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
       
    
        // placement of file message in cell
        addSubview(emailLabel)
        emailLabel.leftAnchor.constraint(equalTo: userImageView.rightAnchor, constant: 11).isActive = true
        emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4).isActive = true
        //messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // placement of file message in cell
        addSubview(messageLabel)
        messageLabel.leftAnchor.constraint(equalTo: userImageView.rightAnchor, constant: 11).isActive = true
        messageLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 5).isActive = true
        //messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        addSubview(postMessageLabel)
        postMessageLabel.leftAnchor.constraint(equalTo: messageLabel.rightAnchor, constant: 4).isActive = true
        postMessageLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 5).isActive = true

        // placement of timestamp label in cell
        addSubview(accessLabel)
        accessLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        accessLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 5).isActive = true
        accessLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
