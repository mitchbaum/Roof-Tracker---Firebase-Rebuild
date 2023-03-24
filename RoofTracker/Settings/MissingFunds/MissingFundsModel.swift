//
//  MissingFundsModel.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/22/23.
//

import Foundation
struct MissingFund: Equatable {
    var id: String?
    var name: String?
    var missingFunds: Double?
    var missingFundsSwitch: Bool?
    var modified: Date?
    
}
