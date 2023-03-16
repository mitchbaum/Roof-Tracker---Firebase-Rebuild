//
//  FileModel.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 5/21/22.
//

import UIKit


struct FB_File: Equatable {
    var name: String?
    var coc: String?
    var deductible: String?
    var cocSwitch: Bool?
    var imageData: String?
    var invoice: String?
    var timeStamp: String?
    var modified: Date?
    var type: String?
    var insCheckACVTotal: String?
    var id: String?
    var acvItemTotal: String?
    var cashItemTotal: String?
    var insCheckTotal: String?
    var pymtCheckTotal: String?
    var rcvItemTotal: String?
    var creditItemTotal: String?
    var note: String?
    
}
