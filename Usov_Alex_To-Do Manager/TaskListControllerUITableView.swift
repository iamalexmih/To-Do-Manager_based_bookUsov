//
//  TaskListControllerUITableView.swift
//  Usov_Alex_To-Do Manager
//
//  Created by Алексей Попроцкий on 25.05.2022.
//

import UIKit

class TaskListControllerUITableView: UITableViewController {

    var tasksStorage: TasksStorageProtocol = TasksStorage() // для доступа к хранилищю задач
    var tasksList: [TaskPriority : [TaskModelProtokol]] = [:] {// Актуальный список задач
        didSet {
            //сортировка массива
            var savingArray: [TaskModelProtokol] = []
            
            for (keyDictionary, tasksGroup) in tasksList {
                tasksList[keyDictionary] = tasksGroup.sorted { taskFirst, taskNext in
                    let tasksStatusPosition: [TaskStatus] = [.planned, .completed]
                    let taskFirstPosition = tasksStatusPosition.firstIndex(of: taskFirst.status) ?? 0
                    let taskNextPosition = tasksStatusPosition.firstIndex(of: taskNext.status) ?? 0

                    return taskFirstPosition < taskNextPosition
                   
                }
                //данный метод не подходит так как сортировка происходит на основе Модели Task. А сортировка это Вид. А вид и модель не должны быть связанны.
                //tasksList[keyDictionary] = tasksGroup.sorted { $0.status.rawValue < $1.status.rawValue }
                savingArray += tasksGroup
            }
            tasksStorage.saveTasks(savingArray)
            
        }
    }
    
    
    var sectionsPositionForPriorityTask: [TaskPriority] = [.important, .normal] //для секции в таблице
    let cellID = "taskCellid"
    let cellidForEmptyTask = "CellForEmptyTask"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadBaseTasks()
        navigationItem.leftBarButtonItem = editButtonItem
    }

    private func loadBaseTasks() {
        sectionsPositionForPriorityTask.forEach { taskPriority in
            tasksList[taskPriority] = []
            // создаем пустой массив для каждого ключа
        }
        
        tasksStorage.loadTasks().forEach { task in
            tasksList[task.priority]?.append(task)
            //tasksList[task.priority] используя ключ (task.priority) для словаря tasksList, получаем массив, поэтому append.
        }
    }
    
    private func getLabelForStatusTask(with status: TaskStatus) -> String {
        var resultLabel: String
        
        switch status {
            case .planned:
                resultLabel = "\u{25CB}"
            case .completed:
                resultLabel = "\u{25C9}"
//            default:
//                resultLabel = ""
        }
        return resultLabel
    }
    
    // MARK: - Segue Prepare

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCreateScreen" {
            let destination = segue.destination as! TaskEdit_TableViewController
            destination.doAfterEdit = { [unowned self] title, priority, status in
                //замыкание будет вызвано после того как будет сохранена задача!
                //print("doAfterEdit")
                let newTask = OneTask(title: title, priority: priority, status: status)
                tasksList[priority]?.append(newTask) //добавить в словарь tasksList, новую задачу newTask по ключу priority.
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
        //return tasksList.count //количество секций равно количеству элементов словаре
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // из массива [.important, .normal] получаем значение по индексу секции
        let getTaskPriorityOutSection = sectionsPositionForPriorityTask[section]
        //используя полученное значение, как ключ для словаря, получаем массив задач
        guard let getCurrentTasksPriority = tasksList[getTaskPriorityOutSection] else {
            return 0
        }
        if getCurrentTasksPriority.isEmpty {
            return 1
        } else {
            return getCurrentTasksPriority.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let getTaskPriority = sectionsPositionForPriorityTask[indexPath.section]
        
        if tasksList[getTaskPriority]!.isEmpty {
            let cellForEmptyTask = UITableViewCell(style: .default, reuseIdentifier: cellidForEmptyTask)
            var config = cellForEmptyTask.defaultContentConfiguration()
            config.text = "список задач пуст"
            config.textProperties.color = UIColor(named: "taskPlanedColor")!
            cellForEmptyTask.contentConfiguration = config
            return cellForEmptyTask
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! TaskCellPrototype
        
        guard let getCurrentTask = tasksList[getTaskPriority]?[indexPath.row]
        else {
            return cell
        }
        
        cell.labelTitleTask.text = getCurrentTask.title
        cell.labelForStatusTask.text = getLabelForStatusTask(with: getCurrentTask.status)
        
        if getCurrentTask.status == .planned {
            cell.labelTitleTask.textColor = UIColor(named: "taskPlanedColor")
            cell.labelForStatusTask.textColor = UIColor(named: "taskPlanedColor")
        } else {
            cell.labelTitleTask.textColor = UIColor(named: "taskCompledColor")
            cell.labelForStatusTask.textColor = UIColor(named: "taskCompledColor")
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        let getTasksPriority = sectionsPositionForPriorityTask[section]

        switch getTasksPriority {
            case .important:
                title = "Важные"
            case .normal:
                title = "Все задачи"
        }
        return title
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let getTaskPriority = sectionsPositionForPriorityTask[indexPath.section]
        if tasksList[getTaskPriority]!.isEmpty {
            tableView.deselectRow(at: indexPath, animated: true)
          return
        }
        //проверка наличия задачи
        guard let _ = tasksList[getTaskPriority]?[indexPath.row] else { return }

        guard tasksList[getTaskPriority]![indexPath.row].status == .planned else {
            //снимаем выделение строки
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        //Отмечаем задачу как выполненную
        tasksList[getTaskPriority]![indexPath.row].status = .completed
        tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let getTaskPriority = sectionsPositionForPriorityTask[indexPath.section]
        guard let _ = tasksList[getTaskPriority]?[indexPath.row] else { return nil }
        //guard tasksList[getTaskPriority]![indexPath.row].status == .completed else { return nil }

        //действие для изм статуса на Запланирована
        let actionSwipeInstance = UIContextualAction(style: .normal, title: "Не выполнена") { _, _, _ in
            self.tasksList[getTaskPriority]![indexPath.row].status = .planned
            self.tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
        }

        //действие для перехода к экрану редактирования
        let actionEditSwipeInstance = UIContextualAction(style: .normal, title: "Изменить") { _, _, _ in
            //загрузка сцены со Сториборда
            let editScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TaskEditScreen") as! TaskEdit_TableViewController
            //передача значений редактируемой задачи
            editScreen.taskText = self.tasksList[getTaskPriority]![indexPath.row].title
            editScreen.taskPriority = self.tasksList[getTaskPriority]![indexPath.row].priority
            editScreen.taskStatus = self.tasksList[getTaskPriority]![indexPath.row].status

            editScreen.doAfterEdit = { [unowned self] title, priority, status in
                let editTask = OneTask(title: title, priority: priority, status: status)

                if getTaskPriority == editTask.priority {
                    tasksList[getTaskPriority]![indexPath.row] = editTask
                } else {
                    tasksList[getTaskPriority]!.remove(at: indexPath.row)
                    tasksList[editTask.priority]?.append(editTask)
                }

                tableView.reloadData()
            }

            self.navigationController?.pushViewController(editScreen, animated: true)
        }

        actionEditSwipeInstance.backgroundColor = .darkGray

        //создаем объект описывающий доступные действия
        let actionsConfig: UISwipeActionsConfiguration
        if tasksList[getTaskPriority]![indexPath.row].status == .completed {
            actionsConfig = UISwipeActionsConfiguration(actions: [actionSwipeInstance, actionEditSwipeInstance])
        } else {
            actionsConfig = UISwipeActionsConfiguration(actions: [actionEditSwipeInstance])
        }
        return actionsConfig
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let getTaskPriority = sectionsPositionForPriorityTask[indexPath.section]
        if tasksList[getTaskPriority]!.isEmpty {
            return false // отключить редактирование строки, если задач нет, чтоб не удалить строку с сообщение "список пуст"
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let getTaskPriority = sectionsPositionForPriorityTask[indexPath.section]
        if editingStyle == .delete {
            if indexPath.row == 0 { // если это последняя строка, то ее не удалять, чтоб сошлось количество ячеек в numberOfRowsInSection
                tasksList[getTaskPriority]?.remove(at: indexPath.row)
                tableView.reloadData()
            } else {
            tasksList[getTaskPriority]?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    

    override func tableView(_ tableView: UITableView, moveRowAt startIndexPath: IndexPath, to finishIndexPath: IndexPath) {
        //получаем секция из которой происходит перемещение
        let startPositionTaskPriority = sectionsPositionForPriorityTask[startIndexPath.section]
        //секция К которой происходит перемещение
        let finishPositionTaskPriority = sectionsPositionForPriorityTask[finishIndexPath.section]

        guard let movedTask = tasksList[startPositionTaskPriority]?[startIndexPath.row] else { return }
        // удаляем задачу из стартовой строки
        tasksList[startPositionTaskPriority]!.remove(at: startIndexPath.row)
        tasksList[finishPositionTaskPriority]!.insert(movedTask, at: finishIndexPath.row)

        if startPositionTaskPriority != finishPositionTaskPriority {
            tasksList[finishPositionTaskPriority]![finishIndexPath.row].priority = finishPositionTaskPriority
        }
        tableView.reloadData()
    }

}
