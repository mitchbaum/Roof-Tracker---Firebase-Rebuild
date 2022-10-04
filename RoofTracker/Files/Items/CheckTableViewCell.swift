//
//  CheckTableViewCell.swift
//  PaymentTracker
//
//  Created by Mitch Baumgartner on 3/14/21.
//

import UIKit

class CheckTableViewCell: UITableViewCell {

    
    @IBOutlet var myCheckNumberLabel: UILabel!
    @IBOutlet var myCheckAmountLabel: UILabel!
    @IBOutlet var myCheckDateLabel: UILabel!
    @IBOutlet var myPaidLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
