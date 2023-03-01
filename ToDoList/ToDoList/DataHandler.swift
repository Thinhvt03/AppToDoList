
//

import Foundation
import CoreData

var fetchResultsController: NSFetchedResultsController<ToDoList>!

class DataHandler {
    
    //Fetch Data
   static func initFetchResultsController() {
       guard let context = AppDelegate.managedObjectContext else {return}
        let fetchRequest = ToDoList.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                            managedObjectContext: context,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        do {
            try fetchResultsController.performFetch()
        } catch {
            print("Error Occured: \(error.localizedDescription)")
        }
    }
    
    // Insert Data
    static func insertNameOfTask(todoName: String, isDone: Bool = false) {
        guard let context = AppDelegate.managedObjectContext else {return}
        let insertNewObject = NSEntityDescription.insertNewObject(forEntityName: "ToDoList", into: context) as! ToDoList
        insertNewObject.todoname = todoName
        insertNewObject.isDone = isDone
    }
    
    // Delete All Data
    static func deleteFetch() {
        guard let context = AppDelegate.managedObjectContext else {return}
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ToDoList")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
            try fetchResultsController.performFetch()
        } catch {
            print("Error Occured: \(error.localizedDescription)")
        }

    }
}
