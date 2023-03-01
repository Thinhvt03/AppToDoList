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
        let editButton = UIBarButtonItem(title: titleButton, style: .plain, target: self, action: #selector(editButtonDidTap))
        navigationItem.rightBarButtonItem = editButton
    }
    
    // Delete Button
    private func setupDeleteButton() {
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteButtonDidTap))
        navigationItem.leftBarButtonItem = deleteButton
    }
    
    @objc private func tableViewDidTap() {
        if action == .adding {
            let todos = fetchResultsController.fetchedObjects!
            let index = IndexPath(row: todos.count, section: 0)
            let cell = tableView.cellForRow(at: index) as! ToDoCell
            if let text = cell.textView.text, !text.isEmpty {
                DataHandler.insertNameOfTask(todoName: text )
            }
        }
        do {
            try AppDelegate.managedObjectContext.save()
        } catch {
            print("Error Occured: \(error.localizedDescription)")
        }
        action = .none
    }
    
    @objc private func editButtonDidTap() {
        tableView.isEditing.toggle()
        checked.toggle()
        setupEditButton()
    }
    
    @objc private func deleteButtonDidTap() {
        let alert = UIAlertController(title: nil, message: "Do you to delete all task?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {[weak self]_ in
            guard let strongSelf = self else {return}
                DataHandler.deleteFetch()
                strongSelf.tableView.reloadData()
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
            cell.todo = todo
            cell.textView.text = todo.todoname
            cell.isDone = todo.isDone
        } else {
            cell.textView.text = nil
            cell.style = action == .none ? .add : .todo
        }
        return cell
    }
}

//MARK: - UIGestureRecognizerDelegate

extension ToDoListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !checked
    }
}

// MARK: - ToDoCell Delegate

extension ToDoListViewController: ToDoCellDelegate {
    func addCellDidTap(_ cell: ToDoCell) {
        action = .adding
        cell.textView.becomeFirstResponder()
    }
    
    func todoCellBeginEditing(_ cell: ToDoCell) {
        guard let todos = fetchResultsController.fetchedObjects else {return}
        
        action = cell.index == todos.count ? .adding : .editing
    }
    
    func todoCellDidChangeContent(_ cell: ToDoCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func todoCellEndEditing(_ cell: ToDoCell) {
        let todos = fetchResultsController.fetchedObjects!
        print("endediting: \(String(describing: cell.index))" )
        if cell.index < todos.count {
            // Edit
            let index = IndexPath(row: cell.index, section: 0)
            let todo = fetchResultsController.object(at: index)
            todo.todoname = cell.textView.text
           
        } else if let text = cell.textView.text, !text.isEmpty {
            // Add
            DataHandler.insertNameOfTask(todoName: text )
        }
        do {
            try AppDelegate.managedObjectContext.save()
        } catch {
            print("Error Occured: \(error.localizedDescription)")
        }
        action = .none
    }
    
    func checkmarkButtonDidTap(_ cell: ToDoCell) {
        let addIndex = IndexPath(row: cell.index, section: 0)
        let todoAtRow = fetchResultsController.object(at: addIndex)
        todoAtRow.isDone = cell.isDone
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
         }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var todos = fetchResultsController.fetchedObjects!
        let todo = todos.remove(at: sourceIndexPath.row)
        todos.insert(todo, at: destinationIndexPath.row)
        do {
            try AppDelegate.managedObjectContext.save()
        } catch {
            print("Error Occured: \(error.localizedDescription)")
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
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
            break
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            break
        @unknown default:
            print("no handler")
        }
    }
}
