//
//  CoreDataManager.swift
//  TrainingCourse
//
//  Created by Mitch Baumgartner on 2/28/21.
//

import CoreData

struct CoreDataManager {
    // shared is a variable of the instance of this class
    static let shared = CoreDataManager() // will live forever as long as this application is still alive. Its properties will too.
    // loading TrainingModels into the persistent store of the container
    let persistentContainer: NSPersistentContainer = {
        // initalization of our core data stack
        let container = NSPersistentContainer(name: "TrainingModels")
        container.loadPersistentStores { (storeDescription, err) in
            if let err = err {
                fatalError("loading of store failed: \(err)")
            }
        }
        return container
    }()
    
    func fetchFiles() -> [File] {
        // context is shared singleton shared persistent container, holds all our data from CoreDataManager.swift file
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<File>(entityName: "File")
        let sort = NSSortDescriptor(key: "timeStamp", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        do {
            let files = try context.fetch(fetchRequest)
            
            
            
            return files
            
        } catch let fetchErr {
            print("Failed to fetch files:", fetchErr)
            // return empty array if actually errors
            return []
        }
    }
    
    
    // tuple for all items in a file (checks, cash jobs, line items due to HO, RCV to do, check amount, check number, check date)
    func createFileItem(itemName: String?, itemType: String, checkDate: Date?, checkAmount: String?, lineNumber: String?, linePrice: String?, lineNote: String?, insCheckCounter: Double?, file: File) -> (FileItem?, Error?) {
        let context = persistentContainer.viewContext
        // create an employee in coredata
        let item = NSEntityDescription.insertNewObject(forEntityName: "FileItem", into: context) as! FileItem
        
        // when creating an item, attach it to a specific file
        item.file = file
        item.type = itemType
        
        // need to set value for key of name inside of entity attribute Employee
        item.setValue(itemName, forKey: "name")
        
        // set up employee information from coredata models
        let itemInformation = NSEntityDescription.insertNewObject(forEntityName: "ItemInformation", into: context) as! ItemInformation
        
//        employeeInformation.taxId = "456"
        // the property .birthday is coming from the coredata model
        itemInformation.checkDate = checkDate
        itemInformation.checkAmount = checkAmount
        itemInformation.lineNumber = lineNumber
        itemInformation.linePrice = linePrice
        itemInformation.lineNote = lineNote
        itemInformation.insCheckCounter = insCheckCounter ?? 0.0
//        employeeInformation.setValue("456", forKey: "taxId")
        
        item.itemInformation = itemInformation
        do {
            try context.save()
            // if save success, get employee(employee.setValue(employeeName, forKey: "name")) and return that employee, and return nil for the error
            return (item, nil)
        } catch let err {
            print("Failed to create item", err)
            return (nil, err)
        }
    }
    
}
