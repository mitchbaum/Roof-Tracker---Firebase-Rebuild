//
//  LineItemTableViewCell.swift
//  PaymentTracker
//
//  Created by Mitch Baumgartner on 3/14/21.
//

import UIKit

class LineItemTableViewCell: UITableViewCell {

    
    
    @IBOutlet var myLineItemLabel: UILabel!
    @IBOutlet var myPriceLabel: UILabel!
    @IBOutlet var myLineNumberLabel: UILabel!
    @IBOutlet var myNotesTextView: UITextView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}
