//
//  ACVItemCell.swift
//  PaymentTracker
//
//  Created by Mitch Baumgartner on 4/3/21.
//

import UIKit

class ACVItemCell: UITableViewCell {

    
    @IBOutlet var myLineItemLabel: UILabel!
    @IBOutlet var myPriceLabel: UILabel!
    @IBOutlet var myLineNumberLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
