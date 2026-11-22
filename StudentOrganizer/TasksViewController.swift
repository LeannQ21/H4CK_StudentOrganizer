import UIKit
import CoreData

class TasksViewController: UITableViewController {

    private var tasks: [TaskItem] = []
    private let context = CoreDataStack.shared.context

    var selectedSubject: Subject?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Tasks"
        loadTasks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
    }

    private func loadTasks() {
        let request: NSFetchRequest<TaskItem> =
            TaskItem.fetchRequest()

        if let selectedSubject = selectedSubject {
            request.predicate = NSPredicate(
                format: "subject == %@",
                selectedSubject
            )
        }

        request.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true)
        ]

        do {
            tasks = try context.fetch(request)
        } catch {
            print("Could not fetch tasks: \(error)")
            tasks = []
        }

        tableView.backgroundView = tasks.isEmpty
            ? emptyStateLabel("No tasks yet.\nTap + to add one.")
            : nil

        tableView.reloadData()
    }

    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "New Task",
            message: "Enter the task name.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Enter task name"
            textField.autocapitalizationType = .sentences
        }

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )

        alert.addAction(
            UIAlertAction(title: "Save", style: .default) {
                [weak self, weak alert] _ in

                guard let self = self,
                      let text = alert?.textFields?.first?.text else {
                    return
                }

                let taskTitle = text.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                guard !taskTitle.isEmpty else {
                    return
                }

                let newTask = TaskItem(context: self.context)
                newTask.title = taskTitle
                newTask.details = nil
                newTask.dueDate = Date()
                newTask.isDone = false
                newTask.priority = 1
                newTask.subject = self.selectedSubject

                CoreDataStack.shared.save()
                self.loadTasks()
            }
        )

        present(alert, animated: true)
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return tasks.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TaskCell",
            for: indexPath
        )

        let task = tasks[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = task.title
        content.secondaryText = task.isDone
            ? "Completed"
            : "Pending"

        cell.contentConfiguration = content
        cell.accessoryType = task.isDone
            ? .checkmark
            : .none

        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let task = tasks[indexPath.row]
        task.isDone.toggle()

        CoreDataStack.shared.save()

        tableView.reloadRows(
            at: [indexPath],
            with: .automatic
        )
    }

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        let editAction = UIContextualAction(
            style: .normal,
            title: "Edit"
        ) { [weak self] _, _, completion in

            guard let self = self else {
                completion(false)
                return
            }

            self.showEditAlert(for: indexPath)
            completion(true)
        }

        editAction.backgroundColor = .systemBlue

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completion in

            guard let self = self else {
                completion(false)
                return
            }

            let task = self.tasks[indexPath.row]

            self.context.delete(task)
            CoreDataStack.shared.save()

            self.tasks.remove(at: indexPath.row)

            tableView.deleteRows(
                at: [indexPath],
                with: .automatic
            )

            tableView.backgroundView = self.tasks.isEmpty
                ? emptyStateLabel("No tasks yet.\nTap + to add one.")
                : nil

            completion(true)
        }

        return UISwipeActionsConfiguration(
            actions: [deleteAction, editAction]
        )
    }

    private func showEditAlert(for indexPath: IndexPath) {
        let task = tasks[indexPath.row]

        let alert = UIAlertController(
            title: "Edit Task",
            message: "Update the task name.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = task.title
            textField.autocapitalizationType = .sentences
        }

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )

        alert.addAction(
            UIAlertAction(title: "Save", style: .default) {
                [weak self, weak alert] _ in

                guard let self = self,
                      let text = alert?.textFields?.first?.text else {
                    return
                }

                let updatedTitle = text.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                guard !updatedTitle.isEmpty else {
                    return
                }

                task.title = updatedTitle
                CoreDataStack.shared.save()

                self.loadTasks()
            }
        )

        present(alert, animated: true)
    }
}
