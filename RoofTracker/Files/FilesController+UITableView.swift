//
//  filesController+UITableView.swift
//  TrainingCourse
//
//  Created by Mitch Baumgartner on 3/2/21.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
// this file will hold all my tableView delegate functions
extension FilesController {
    
    

    
    // when user taps on row bring them into another view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // whenever user taps on a file cell, push over the information to the employee view controller
        //let file = self.files[indexPath.row]
        
        let file: FB_File
        if (searchController.isActive) {
            file = self.filteredFiles[indexPath.row]
        } else {
            file = self.rowsToDisplay[indexPath.row]
        }
        
        let itemsController = ItemsController()
        itemsController.file = file
        
        
        // push into new viewcontroller
        navigationController?.pushViewController(itemsController, animated: true)
    }
    
    // delete file from tableView and coredata
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (_, indexPath) in
            // get file you are swiping on to get delete action
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let deleteAction = UIAlertAction(title: "Delete File", style: .destructive) { (action) in
                if (self.searchController.isActive) {
                    print("active")
                    let fileId = self.filteredFiles[indexPath.row].id
                    self.filteredFiles.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.db.collection("Users").document(uid).collection("Files").document(fileId!).delete()
                    let storageRef = Storage.storage().reference().child("\(uid)/\(fileId!).png")
                    storageRef.delete { error in
                      if let error = error {
                        // Uh-oh, an error occurred!
                        print(error)
                      } else {
                        // File deleted successfully
                          print("deleted file from storage")
                      }
                    }
                    
                    
                    self.fetchFiles()
                } else {
                    print("not active")
                    let fileId = self.rowsToDisplay[indexPath.row].id
                    self.rowsToDisplay.remove(at: indexPath.row)
                    self.files.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.db.collection("Users").document(uid).collection("Files").document(fileId!).delete()
                    let storageRef = Storage.storage().reference().child("\(uid)/\(fileId!).png")
                    storageRef.delete { error in
                      if let error = error {
                        // Uh-oh, an error occurred!
                        print(error)
                      } else {
                        // File deleted successfully
                          print("deleted file from storage")
                      }
                    }

                }
            }
            // alert
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            optionMenu.addAction(deleteAction)
            optionMenu.addAction(cancelAction)
            self.present(optionMenu, animated: true, completion: nil)
           
            
        }
        // change color of delete button
        deleteAction.backgroundColor = UIColor.lightRed
        // perform edit action
        let editAction = UITableViewRowAction(style: .normal , title: "Edit", handler: editHandlerFunction)
        // change color of edit button
        editAction.backgroundColor = UIColor.darkBlue

        
        // this puts the action buttons in the row the user swipes so user can actually see the buttons to delete or edit
        return [deleteAction, editAction]
    }
    
    // edit cell function 
    private func editHandlerFunction(action: UITableViewRowAction, indexPath: IndexPath) {
        print("Editing file in seperate function")
        // pop up modal that displays information about the selected file
        let editFileController = CreateFileController()
        
        editFileController.delegate = self
        // find the file you are swiping and put the file in the text area to edit
        if (searchController.isActive) {
            editFileController.file = filteredFiles[indexPath.row]
        } else {
            editFileController.file = rowsToDisplay[indexPath.row]
        }
        
        let navController = CustomNavigationController(rootViewController: editFileController)
        present(navController, animated: true, completion: nil)
    }
    
    // create footer that displays when there are no files in the table
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        if searchController.isActive {
            let fileType = searchController.searchBar.scopeButtonTitles![searchController.searchBar.selectedScopeButtonIndex]
            if fileType == "Open" {
                label.text = "No open files"
            } else if fileType == "Closed" {
                label.text = "No closed files"
            }
        } else {
            let fileType = openClosedSegmentedControl.titleForSegment(at: openClosedSegmentedControl.selectedSegmentIndex)
            if isSignedIn == false {
                label.text = ""
            } else if fileType == "Open" {
                label.text = "No open files"
            } else if fileType == "Closed" {
                label.text = "No closed files"
            } else {
                label.text = "No files"
            }
        }
        
        label.textColor = .white
        label.textAlignment = .center
        
        return label
    }
    // create footer that is hidden when no rows are present
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if searchController.isActive {
            return filteredFiles.count == 0 ? 150 : 0
        } else {
            return rowsToDisplay.count == 0 ? 150 : 0
        }
        
    }
    
    
    // create some cells for the rows
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // this will return a UITableViewCell
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! FileCell
        cell.selectionStyle = .none
        
        
        //when you call the file on the cell, you trigger the didSet property in fileCell.swift file for var file: file?
        let file: FB_File
        if (searchController.isActive) {
            file = filteredFiles[indexPath.row]
        } else {
            file = rowsToDisplay[indexPath.row]
        }
        cell.file = file
        
        
        
        
        
//        // change cell background color
//
//        // the cell takes a color with variable from UIColor+theme.swift file, in this case the function UIColor with the variable "someColor" found in that file
//        //cell.backgroundColor = UIColor.tealColor
//        // add some text to each cell and text color
//        // access file for each row by using files model
//        let file = files[indexPath.row]
//        // make date show up pretty in cell by unwrapping name and founded property
//
//
//        cell.textLabel?.textColor = .white
//        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//
        // place image in cell, each cell already has a image property for, once you call for it it will show up
//        cell.imageView?.image = #imageLiteral(resourceName: "select_photo_empty");
//        if let imageData = file.imageData {
//            cell.imageView?.image = UIImage(data: imageData);
//        }
        return cell
}
//    // height of each cell
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 95
//    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    // add some rows to the tableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (searchController.isActive) {
            return filteredFiles.count
        }
        
        
        // returns number of rows as number of files
        return rowsToDisplay.count
    }
    
    
}
