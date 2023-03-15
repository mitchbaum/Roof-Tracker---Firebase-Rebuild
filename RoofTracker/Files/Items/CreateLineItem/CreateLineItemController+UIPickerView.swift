//
//  CreateLineItem+UIPickerView.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/14/23.
//

import UIKit
extension CreateLineItemController {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //return schoolsTestEnvironment.count
        return types.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //return schoolsTestEnvironment[row]
        return types[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        schoolSelectorTextField.text = schoolsTestEnvironment[row]
//        schoolSelectorTextField.resignFirstResponder()
        if types[row] != types[0] {
            typeTextField.text = types[row]
        }
        typeTextField.resignFirstResponder()
    }
}
