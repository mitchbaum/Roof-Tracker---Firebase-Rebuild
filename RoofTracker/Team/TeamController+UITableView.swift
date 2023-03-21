//
//  TeamController+UITableView.swift
//  RoofTracker
//
//  Created by Mitch Baumgartner on 3/19/23.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
// this file will hold all my tableView delegate functions
extension TeamController {
    
    

    
    // when user taps on row bring them into another view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let teamMember: TeamMember
        teamMember = self.teamMembers[indexPath.row]
        
        
        let teamMemberController = TeamMemberController()
        teamMemberController.teamMember = teamMember
        
        
        // push into new viewcontroller
        navigationController?.pushViewController(teamMemberController, animated: true)
    }
    
    
    
    
    
    // create footer that displays when there are no files in the table
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = "No team members found"
        
        label.textColor = .white
        label.textAlignment = .center
        
        return label
    }
    // create footer that is hidden when no rows are present
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return teamMembers.count == 0 ? 150 : 0
        
    }
    
    
    // create some cells for the rows
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // this will return a UITableViewCell
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! TeamCell
        cell.selectionStyle = .none
        
        
        //when you call the file on the cell, you trigger the didSet property in fileCell.swift file for var file: file?
        let teamMember: TeamMember
        teamMember = teamMembers[indexPath.row]
        cell.teamMember = teamMember
        
        
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
        teamMembers.count
    }
    
    
}
