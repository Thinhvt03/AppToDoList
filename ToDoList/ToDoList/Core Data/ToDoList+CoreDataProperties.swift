//
//  ToDoList+CoreDataProperties.swift
//  ToDoList
//
//  Created by Hoàng Loan on 01/03/2023.
//
//

import Foundation
import CoreData
import UIKit


extension ToDoList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoList> {
        return NSFetchRequest<ToDoList>(entityName: "ToDoList")
    }

    @NSManaged public var isDone: Bool
    @NSManaged public var todoname: String?
    @NSManaged public var index: Int32
    @NSManaged public var titleColor: String?

}

extension ToDoList : Identifiable {
     
}
