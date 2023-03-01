//
//  ToDoList+CoreDataProperties.swift
//  ToDoList
//
//  Created by Hoàng Loan on 27/02/2023.
//
//

import Foundation
import CoreData


extension ToDoList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoList> {
        return NSFetchRequest<ToDoList>(entityName: "ToDoList")
    }

    @NSManaged public var isDone: Bool
    @NSManaged public var todoname: String?

}

extension ToDoList : Identifiable {

}
