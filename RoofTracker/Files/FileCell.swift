//
//  fileCell.swift
//  TrainingCourse
//
//  Created by Mitch Baumgartner on 3/2/21.
//
// this file customizes the cells in filesController
import UIKit
class FileCell: UITableViewCell {
    
    var file: FB_File? { // start off file with nil with ?
        didSet {
            // extract file name out of file
            messageLabel.text = " "
            postMessageLabel.text = ""
            // place image in cell, each cell already has a image property for, once you call for it it will show up
//            cell.imageView?.image = #imageLiteral(resourceName: "select_photo_empty");
            if let fileImage = file?.imageData {
                if file?.imageData == "" {
                    fileImageView.image = UIImage(named: "file_photo_empty")
                } else {
                    // this places each file image into the cache to retrieve when user goes back to home to use less memory
                    fileImageView.loadImageUsingCacheWithUrlString(urlString: fileImage)
                }
            }
            // make date show up pretty in cell by unwrapping name and founded property
            if let name = file?.name, let coc = Double(file?.coc ?? ""), let deductible = Double(file?.deductible ?? "") {
                let currencyFormatter = NumberFormatter()
                currencyFormatter.usesGroupingSeparator = true
                currencyFormatter.numberStyle = .currency
                currencyFormatter.locale = Locale.current
                
//                // MMM dd, yyyy
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "MMM dd, yyyy"
//                let foundedDateString = dateFormatter.string(from: founded)
                let checkACVTotal = Double(file?.insCheckACVTotal ?? "")
                if checkACVTotal == nil {
                    let insToHomeOwner = coc - deductible
                    let shortDeductible = currencyFormatter.string(from: NSNumber(value: insToHomeOwner))
                    let fileString = "\(name)"
                    let message = shortDeductible
                    
                    nameLabel.text = fileString
                    messageLabel.text = message
                    postMessageLabel.text = "INS. STILL OWES HO"
                } else if checkACVTotal != nil {
                    let fileString = "\(name)"
                    let moneyToHO = coc + checkACVTotal! - deductible
                    let moneyToHOFormat = currencyFormatter.string(from: NSNumber(value: moneyToHO))
                    let message = moneyToHOFormat
                    //nameLabel.text = file?.name
                    nameLabel.text = fileString
                    messageLabel.text = message
                    postMessageLabel.text = "INS. STILL OWES HO"
                }
            } else {
                if file?.name == "" {
                    nameLabel.text = " "
                } else {
                    nameLabel.text = file?.name
                }
                
            }
            if let timeStamp = file?.timeStamp {
                // display timestamp in cell (yes this is a work around LOL)
                let timeStampStr = "\(timeStamp)"
                let split = timeStampStr.components(separatedBy: " at")
                timestampLabel.text = split[0]
            }
            
            if let closed = file?.type {
                if closed == "Closed" {
                    closedLabel.text = "Closed"
                } else {
                    closedLabel.text = ""
                }
            }

            if let missingFunds =  file?.missingFundsSwitch {
                if missingFunds == true {
//                    missingFundsLabel.layer.backgroundColor = UIColor.lightRed.cgColor
//                    missingFundsLabel.contentEdgeInsets = UIEdgeInsets(top: 3, left: 10, bottom: 3, right: 10)
//                    missingFundsLabel.setTitle("In Pursuit of Missing Funds", for: .normal)
//                    missingFundsLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
                    
                    closedLabel.text = "Pursuing Missing Funds"
                    closedLabel.textColor = UIColor.lightRed
                    //closedLabel.layer.backgroundColor = UIColor.lightBlue.cgColor
                    
                    
                } else {
//                    missingFundsLabel.setTitle("", for: .normal)
//                    missingFundsLabel.layer.backgroundColor = UIColor.white.cgColor
//                    missingFundsLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
                    
                    closedLabel.textColor = UIColor.darkGray
                    
                    
                }
            }
            

        }
    }
    
    let alertView: UIView = {
            let view = UIView()
            view.backgroundColor = .lightBlue
            view.layer.masksToBounds = true
            view.layer.cornerRadius = 5
            view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            //  [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]  [bottom left, bottom right, top left, top right]
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
    
    // ypu cannot declare another image view using "imageView"
    let fileImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "file_photo_empty"))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // circular picture
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        //imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 0
        return imageView
    }()
    
    // create custom label for file name
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        //label.backgroundColor = .cyan
        return label
    }()
    
    // create custom label for file message
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textColor = .lightRed
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = .yellow
        return label
    }()
    
    let postMessageLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        // enable autolayout
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = .purple
        return label
    }()
    
    // create custom label for timeStamp label
    let timestampLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        //label.font = UIFont.boldSystemFont(ofSize: 10)
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = .orange
        return label
    }()
    
    let missingFundsLabel: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // create custom label for closed label
    let closedLabel: UILabel = {
        let label = UILabel()
        label.text = "Closed"
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
        addSubview(fileImageView)
        fileImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        fileImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        fileImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        fileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        // placement of file name in cell
        addSubview(nameLabel)
        nameLabel.leftAnchor.constraint(equalTo: fileImageView.rightAnchor, constant: 11).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
       
    
        // placement of file message in cell
        addSubview(messageLabel)
        messageLabel.leftAnchor.constraint(equalTo: fileImageView.rightAnchor, constant: 11).isActive = true
        messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10).isActive = true
        //messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        addSubview(postMessageLabel)
        postMessageLabel.leftAnchor.constraint(equalTo: messageLabel.rightAnchor, constant: 5).isActive = true
        postMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 18).isActive = true
        //postMessageLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

//            addSubview(missingFundsLabel)
//            missingFundsLabel.leftAnchor.constraint(equalTo: fileImageView.rightAnchor, constant: 11).isActive = true
//            missingFundsLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 5).isActive = true
            
            addSubview(timestampLabel)
            timestampLabel.leftAnchor.constraint(equalTo: fileImageView.rightAnchor, constant: 11).isActive = true
            timestampLabel.topAnchor.constraint(equalTo: postMessageLabel.bottomAnchor, constant: 10).isActive = true
            timestampLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
            
            // placement of timestamp label in cell
            addSubview(closedLabel)
            closedLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
            closedLabel.topAnchor.constraint(equalTo: postMessageLabel.bottomAnchor, constant: 10).isActive = true
            closedLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

