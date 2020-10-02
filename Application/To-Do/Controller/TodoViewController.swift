//
//  TodoViewController.swift
//  To-Do
//
//  Created by Aaryan Kothari on 29/09/20.
//  Copyright © 2020 Aaryan Kothari. All rights reserved.
//

import UIKit

enum SortTypesAvailable: CaseIterable {
    case sortByNameAsc
    case sortByNameDesc
    case sortByDateAsc
    case sortByDateDesc
    
    func getTitleForSortType() -> String {
        var titleString = ""
        switch self {
        case .sortByNameAsc:
            titleString = "Sort By Name (A-Z)"
        case .sortByNameDesc:
            titleString = "Sort By Name (Z-A)"
        case .sortByDateAsc:
            titleString = "Sort By Date (Earliest first)"
        case .sortByDateDesc:
            titleString = "Sort By Date (Latest first)"
        }
        return titleString
    }
    
    func getSortClosure() -> ((Task, Task) -> Bool) {
        var sortClosure: (Task, Task) -> Bool
        switch self {
        case .sortByNameAsc:
            sortClosure = { (task1, task2) in
                task1.title < task2.title
            }
        case .sortByNameDesc:
            sortClosure = { (task1, task2) in
                task1.title > task2.title
            }
        case .sortByDateAsc:
            sortClosure = { (task1, task2) in
                task1.dueDate < task2.dueDate
            }
        case .sortByDateDesc:
            sortClosure = { (task1, task2) in
                task1.dueDate > task2.dueDate
            }
        }
        return sortClosure
    }
}

class TodoViewController: UITableViewController {
    
    /// `Tableview` to display list of tasks
    @IBOutlet weak var todoTableView: UITableView!
    
    /// `SearchController` to include search bar
    var searchController: UISearchController!
    
    /// `ResultsController` to display results of specific search
    var resultsTableController: ResultsTableController!
    
    /// `DataSource` for todoTableview
    var todoList : [Task] = []
    var lastIndexTapped : Int = 0
    
    /// `Reuse Identifier` for TodoTableViewCell
    let todoCellReuseIdentifier = "todocell"
    
    /// `Segue Identifier` to go to TaskDetailsViewController
    let taskDetailsIdentifier = "gototask"
    
    var currentSelectedSortType: SortTypesAvailable = .sortByNameAsc
    
    //MARK: View lifecycle methods
    override func viewDidLoad() {
        setupSearchController()
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationItem.searchController = searchController
    }
    
    //MARK: IBActions
    /// perform segue to `TaskDetailsViewController` if `+` tapped
    @IBAction func addTasksTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: taskDetailsIdentifier, sender: Any?.self)
    }
    
    @IBAction func sortButtonTapped(_ sender: UIBarButtonItem) {
        showSortAlertController()
    }
    
    
    ///Star task
    /// function called when `Star Task` tapped
    func starTask(at index : Int){
        //TODO: write star login
        todoList[index].isFavourite = todoList[index].isFavourite ? false : true
        tableView.reloadData()
    }
    
    ///Delete task
    /// function called when `Delete Task` tapped
    func deleteTask(at index : Int){
        todoList.remove(at: index) /// removes task at index
        tableView.reloadData() /// Reload tableview with remaining data
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let taskDetailVC = segue.destination as? TaskDetailsViewController{
            taskDetailVC.delegate = self
            taskDetailVC.task = sender as? Task
        }
    }
    
    /// search controller setup
    fileprivate func setupSearchController() {
        resultsTableController =
            self.storyboard?.instantiateViewController(withIdentifier: "ResultsTableController") as? ResultsTableController
        resultsTableController.tableView.delegate = self
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
    }
    
    //MARK:  ------ Tableview Datasource methods ------
    // Reference: https://developer.apple.com/documentation/uikit/uitableviewdatasource
    
    /// function to determine `Number of rows` in tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoList.count
    }
    
    /// function  to determine `tableview cell` at a given row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: todoCellReuseIdentifier, for: indexPath) as! TaskCell
        let task = todoList[indexPath.row]
        cell.title.text = task.title
        cell.subtitle.text = task.dueDate
        cell.starImage.isHidden = todoList[indexPath.row].isFavourite ? false : true
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastIndexTapped = indexPath.row
        let task = todoList[indexPath.row]
        performSegue(withIdentifier: taskDetailsIdentifier, sender: task)
    }
    
    
    //MARK:  ----- Tableview Delagate methods  ------
    // Reference: https://developer.apple.com/documentation/uikit/uitableviewdelegate
    
    /// `UISwipeActionsConfiguration` for delete and star  buttons
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") {  (_, _, _) in
            self.deleteTask(at: indexPath.row)
        }
        let star = UIContextualAction(style: .normal, title: todoList[indexPath.row].isFavourite ? "Unstar" : "Star"){  (_, _, _) in
            self.starTask(at: indexPath.row)
        }
        star.backgroundColor = .orange
        
        let swipeActions = UISwipeActionsConfiguration(actions: [delete,star])
        
        return swipeActions
    }
    
    /// function to determine `View for Footer` in tableview.
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView() /// Returns an empty view.
    }
}

//MARK: - TaskDelegate
/// protocol for `saving` or `updating` `Tasks`
extension TodoViewController : TaskDelegate{
    func didTapSave(task: Task) {
        todoList.append(task) /// add task
        tableView.reloadData() /// Reload tableview with new data
    }
    
    func didTapUpdate(task: Task) {
        todoList[lastIndexTapped] = task /// edit task
        tableView.reloadData() /// Reload tableview with new data
    }
}

// MARK: - Search Bar Delegate

extension TodoViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        /// perform search only when there is some text
        if let text: String = searchController.searchBar.text?.lowercased(), text.count > 0, let resultsController = searchController.searchResultsController as? ResultsTableController {
            resultsController.todoList = todoList.filter({ (task) -> Bool in
                if task.title.lowercased().contains(text) || task.subTasks.lowercased().contains(text) {
                    return true
                }
                return false
            })
            resultsController.tableView.reloadData()
        } else {
            /// default case when text not available or text length is zero
            tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tableView.reloadData()
    }
}

// MARK:- Sort functionality
extension TodoViewController {
    
    func showSortAlertController() {
        let alertController = UIAlertController(title: nil, message: "Choose sort type", preferredStyle: .actionSheet)
        
        SortTypesAvailable.allCases.forEach { (sortType) in
            let action = UIAlertAction(title: sortType.getTitleForSortType(), style: .default) { (_) in
                self.currentSelectedSortType = sortType
                self.sortListAndReload()
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
    
    func sortListAndReload() {
        todoList.sort(by: currentSelectedSortType.getSortClosure())
        self.tableView.reloadData()
    }
}
