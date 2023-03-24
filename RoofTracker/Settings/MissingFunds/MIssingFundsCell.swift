//
//  MIssingFundCell.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/23/23.
//
import UIKit
class MissingFundsCell: UITableViewCell {
    
    var missingFund: MissingFund? { // start off file with nil with ?
        didSet {

            if missingFund?.name == "" {
                nameLabel.text = " "
            } else {
                nameLabel.text = missingFund?.name
            }
            
            
            if missingFund?.missingFunds != nil {
                let currencyFormatter = NumberFormatter()
                currencyFormatter.usesGroupingSeparator = true
                currencyFormatter.numberStyle = .currency
                currencyFormatter.locale = Locale.current
                let missingFunds = currencyFormatter.string(from: NSNumber(value: missingFund?.missingFunds ?? 3466.70))
                messageLabel.text = missingFunds
            }
            if let missingFunds =  missingFund?.missingFundsSwitch {
                if missingFunds == true {
                    pursuingFundsFlag.text = "Pursuing Missing Funds"
                    pursuingFundsFlag.textColor = UIColor.lightRed
                    
                } else {
                    pursuingFundsFlag.text = ""
                }
            }
            
            
            

        }
    }
    
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
    
    // create custom label for closed label
    let pursuingFundsFlag: UILabel = {
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
        
        
        // placement of file name in cell
        addSubview(nameLabel)
        nameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 11).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
       
    
        // placement of file message in cell
        addSubview(messageLabel)
        messageLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 11).isActive = true
        messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true

        addSubview(postMessageLabel)
        postMessageLabel.leftAnchor.constraint(equalTo: messageLabel.rightAnchor, constant: 5).isActive = true
        postMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true

        // placement of timestamp label in cell
        addSubview(pursuingFundsFlag)
        pursuingFundsFlag.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        pursuingFundsFlag.topAnchor.constraint(equalTo: postMessageLabel.bottomAnchor, constant: 5).isActive = true
        pursuingFundsFlag.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
