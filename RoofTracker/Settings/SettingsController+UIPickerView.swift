//
//  SettingsController+UIPickerView.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 6/29/22.
//

import UIKit

extension SettingsController {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //return schoolsTestEnvironment.count
        return years.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //return schoolsTestEnvironment[row]
        return years[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        schoolSelectorTextField.text = schoolsTestEnvironment[row]
//        schoolSelectorTextField.resignFirstResponder()
        
        yearTextField.text = years[row]
        yearTextField.resignFirstResponder()
    }
}
