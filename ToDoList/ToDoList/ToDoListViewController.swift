//
//  ViewController.swift
//  ToDoList
//
//  Created by Hoàng Loan on 27/02/2023.
//

import UIKit
import CoreData

class ToDoListViewController: UIViewController {

    enum Action {
        case none, adding, editing
    }
    
    @IBOutlet weak var tableView: UITableView!
   
// MARK: - Properties action
    
    let reuseIdentifier = "ToDoCell"
    var titleButton = "Edit"
    var editingIndex: Int = 1
    
    var action: Action = .none {
        didSet {
            guard let todos = fetchResultsController.fetchedObjects else {return}
            let addIndex = IndexPath(row: todos.count, section: 0)
            let lastAction = oldValue
            
            switch (lastAction, action) {
            case (.none, .editing):
                guard let todos = fetchResultsController.fetchedObjects else {return}
                let lastIndex = IndexPath(row: todos.count, section: 0)
                tableView.deleteRows(at: [lastIndex], with: .automatic)
            case (.none, .adding):
                
                let cell = tableView.cellForRow(at: addIndex) as! ToDoCell
                cell.textView.text = nil
                cell.style = .todo
            case (_, .none):
                
                if .editing == lastAction {
                    tableView.insertRows(at: [addIndex], with: .automatic)
                }
                let cell = tableView.cellForRow(at: addIndex) as! ToDoCell
                cell.textView.text = nil
                cell.style = .add
                cell.index = todos.count
                
                tableView.beginUpdates()
                tableView.endUpdates()
                
                view.endEditing(true)
                
            case (.adding, .editing):
                guard let todos = fetchResultsController.fetchedObjects else {return}
                let lastIndex = IndexPath(row: todos.count, section: 0)
                tableView.deleteRows(at: [lastIndex], with: .automatic)
            default:
                
                print("no handle")
                
            }
        }
    }
    
    var checked: Bool = false {
        didSet {
            titleButton = checked ? "Done" : "Edit"
        }
    }
    
// MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupData()
        setupEditButton()
        setupDeleteButton()
        startAvoidingKeyboard()
    }
    
// MARK: - Methods
    
    // Setup TableView
   private func setupTableView() {
        tableView.dataSource = self
        tableView.register(ToDoCell.self, forCellReuseIdentifier: reuseIdentifier)
       
        let tapTableViewGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewDidTap))
        tableView.addGestureRecognizer(tapTableViewGesture)
        tapTableViewGesture.delegate = self
    }
    
    // Setup Data
    private func setupData() {
        DataHandler.initFetchResultsController()
        fetchResultsController.delegate = self
    }
      
    // Edit Button
    private func setupEditButton() {
        let editButton = UIBarButtonItem(title: titleButton, style: .plain, target: self, action: nil)
        
        guard let todos = fetchResultsController.fetchedObjects else {return}
        if todos.isEmpty && checked == false {
                editButton.tintColor = .gray
        } else {
            editButton.action = #selector(editButtonDidTap)
        }
        
        navigationItem.rightBarButtonItem = editButton
    }
    
    // Delete Button
    private func setupDeleteButton() {
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: nil)
        
        guard let todos = fetchResultsController.fetchedObjects else {return}
        if todos.isEmpty {
            deleteButton.action = nil
            deleteButton.tintColor = .gray
        } else{
            deleteButton.action = #selector(deleteButtonDidTap)
        }
        
        navigationItem.leftBarButtonItem = deleteButton
    }
    
    // action tap in tableView
    @objc private func tableViewDidTap() {
        let index = IndexPath(row: editingIndex, section: 0)
        let cell = tableView.cellForRow(at: index) as! ToDoCell
        
        if action == .adding {
            if let text = cell.textView.text, !text.isEmpty {
                DataHandler.insertNameOfTask(todoName: text, index: Int32(cell.index) )
            }
        } else if action == .editing  {
            let index = IndexPath(row: editingIndex, section: 0)
            let todo = fetchResultsController.object(at: index)
            todo.todoname = cell.textView.text
            
            do {
                try AppDelegate.managedObjectContext.save()
            } catch {
                print("Error Occured: \(error.localizedDescription)")
            }
        }
        
        action = .none
        checked = false
        setupEditButton()
        print(checked)
        
        
    }
    
    // action tap in Edit button
    @objc private func editButtonDidTap() {
        
        if action == .none {
            tableView.isEditing.toggle()
            checked.toggle()
            setupEditButton()
        } else {
            tableViewDidTap()
          }
        do {
            try AppDelegate.managedObjectContext.save()
        } catch {
            print("Error Occured: \(error.localizedDescription)")
        }
        
        action = .none
    }
    
    // action tap in Delete button
    @objc private func deleteButtonDidTap() {
        let alert = UIAlertController(title: nil, message: "Do you to delete all task?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {[weak self]_ in
            guard let strongSelf = self else {return}
                DataHandler.deleteFetch()
                strongSelf.tableView.reloadData()
                
                strongSelf.setupEditButton()
                strongSelf.setupDeleteButton()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
}

// MARK: - TableView DataSource

extension ToDoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let todos = fetchResultsController.fetchedObjects else {return 0}
        switch action {
        case .editing:
            return todos.count
        default:
            return todos.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ToDoCell
        cell.delegate = self
        cell.index = indexPath.row
        let todos = fetchResultsController.fetchedObjects
        
        if indexPath.row < todos!.count {
            let todo = fetchResultsController.object(at: indexPath)
            cell.textView.text = todo.todoname
            cell.isDone = todo.isDone
            cell.backgroundColor = todo.color
        } else {
            cell.textView.text = nil
            cell.style = action == .none ? .add : .todo
        }
        return cell
    }
    
    // set location to be edited
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let todos = fetchResultsController.fetchedObjects!
        if indexPath.row == todos.count {
            return false
        } else {
            return true
        }
    }
}

//MARK: - UIGestureRecognizerDelegate

extension ToDoListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if action == .none {
            return false
        }
       return true
    }
}

// MARK: - ToDoCell Delegate

extension ToDoListViewController: ToDoCellDelegate {
    func addCellDidTap(_ cell: ToDoCell) {
        action = .adding
        cell.textView.becomeFirstResponder()
    }
    
    func todoCellBeginEditing(_ cell: ToDoCell) {
        editingIndex = cell.index
        checked = true
        setupEditButton()
        guard let todos = fetchResultsController.fetchedObjects else {return}
        action = cell.index == todos.count ? .adding : .editing
    }
    
    func todoCellDidChangeContent(_ cell: ToDoCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func todoCellEndEditing(_ cell: ToDoCell) {
        let todos = fetchResultsController.fetchedObjects!
        
        if cell.index < todos.count {
            // Edit
            let index = IndexPath(row: editingIndex, section: 0)
            let todo = fetchResultsController.object(at: index)
            todo.todoname = cell.textView.text
            do {
                try AppDelegate.managedObjectContext.save()
            } catch {
                print("Error Occured: \(error.localizedDescription)")
            }
            checked = false
            action = .none
            
        } else if let text = cell.textView.text, !text.isEmpty {
                // Add
            DataHandler.insertNameOfTask(todoName: text, index: Int32(editingIndex) )
                
                action = .none
                action = .adding
                cell.textView.becomeFirstResponder()
                
            } else {
                action = .none
                checked = false
            }
        
        setupEditButton()
        setupDeleteButton()
    
    }
    
    func checkmarkButtonDidTap(_ cell: ToDoCell) {
        if !cell.textView.text.isEmpty {
            let addIndex = IndexPath(row: cell.index, section: 0)
            let todoAtRow = fetchResultsController.object(at: addIndex)
            todoAtRow.isDone = cell.isDone
        } else {
            checked.toggle()
            setupEditButton()
        }
            do {
                try AppDelegate.managedObjectContext.save()
            } catch {
                print("Error Occured: \(error.localizedDescription)")
            }
        action = .none
    }
    
    func todoCellDidSwipeRight(_ cell: ToDoCell) {
        
        let index = IndexPath(row: cell.index, section: 0)
        let todos = fetchResultsController.object(at: index)
        let hexColor = ["FFCCFF", "FFFFFF", "FFFF99", "99FFFF", "CC99FF","9999CC", "FFCC99","99FFFF"].randomElement()
            cell.backgroundColor = UIColor(hex: hexColor!)
        todos.color = cell.backgroundColor
        
        do {
            try AppDelegate.managedObjectContext.save()
        } catch {
            print("Error Occured: \(error.localizedDescription)")
        }
    }
}

// MARK: - Fetch Results Controller

extension ToDoListViewController: NSFetchedResultsControllerDelegate {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
             guard let context = AppDelegate.managedObjectContext else {return}
             let deleteTodo = fetchResultsController.object(at: indexPath)
             context.delete(deleteTodo)
             do {
                 try context.save()
             } catch {
                 print("Error Occured: \(error.localizedDescription)")
             }
            setupEditButton()
            setupDeleteButton()
            action = .none
         }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let count = fetchResultsController.fetchedObjects?.count ?? 0
        var array: [Int] = []
                for i in 0..<count {
                    array.append(i)
                }
                
                let newElement = array.remove(at: sourceIndexPath.row)
                array.insert(newElement, at: destinationIndexPath.row)
                
                for i in 0..<count {
                    let task = fetchResultsController.object(at: IndexPath(row: i, section: 0))
                    
                    let newPosition = array.firstIndex(of: i)!
                    task.index = Int32(newPosition)
                }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            break
        case .move:
            print("move")
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            break
        case .update:
            print("update")
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            break
        @unknown default:
            print("no handler")
        }
    }
}
