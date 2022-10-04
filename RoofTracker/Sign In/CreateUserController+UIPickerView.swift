//
//  CreateUserController+UIPickerView.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 9/22/22.
//

import UIKit

extension CreateUserController {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //return schoolsTestEnvironment.count
        return companies.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //return schoolsTestEnvironment[row]
        return companies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        schoolSelectorTextField.text = schoolsTestEnvironment[row]
//        schoolSelectorTextField.resignFirstResponder()
        if companies[row] != companies[0] {
            companyTextField.text = companies[row]
        }
        companyTextField.resignFirstResponder()
    }
}

