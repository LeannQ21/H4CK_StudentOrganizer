import UIKit
import CoreData

final class TasksViewController: UITableViewController {

    private var tasks: [TaskItem] = []
    private let context = CoreDataStack.shared.context

    var selectedSubject: Subject?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Tasks"
        addNotesButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
    }

    private func addNotesButton() {
        let notesButton = UIBarButtonItem(
            title: "Notes",
            style: .plain,
            target: self,
            action: #selector(notesTapped)
        )

        // Keep Add at the far right and put Notes immediately beside it.
        if let addButton = navigationItem.rightBarButtonItem {
            navigationItem.rightBarButtonItems = [addButton, notesButton]
        } else {
            navigationItem.rightBarButtonItem = notesButton
        }
    }

    @objc private func notesTapped() {
        performSegue(withIdentifier: "ShowNotesSegue", sender: self)
    }

    private func loadTasks() {
        guard let selectedSubject else {
            tasks = []
            updateEmptyState()
            tableView.reloadData()
            return
        }

        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "subject == %@",
            selectedSubject
        )
        // Keep unfinished work first; completed tasks move to the bottom.
        request.sortDescriptors = [
            NSSortDescriptor(key: "isDone", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true),
            NSSortDescriptor(key: "title", ascending: true)
        ]

        do {
            tasks = try context.fetch(request)
        } catch {
            print("Could not fetch tasks: \(error)")
            tasks = []
        }

        updateEmptyState()
        tableView.reloadData()
    }

    private func updateEmptyState() {
        tableView.backgroundView = tasks.isEmpty
            ? emptyStateLabel("No tasks yet.\nTap + to add one.")
            : nil
    }

    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowTaskFormSegue", sender: nil)
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        tasks.count
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
        let dueDate = task.dueDate?.formatted(
            date: .abbreviated,
            time: .shortened
        ) ?? "No due date"

        var content = cell.defaultContentConfiguration()
        content.text = task.title ?? "Untitled task"
        content.secondaryText = "\(task.isDone ? "Completed" : "Pending") · \(dueDate) · \(priorityName(for: task.priority))"
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.accessoryType = task.isDone ? .checkmark : .none
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let task = tasks[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowTaskFormSegue", sender: task)
    }

    // A right swipe marks a task done; swiping it again restores it.
    override func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        let action = UIContextualAction(
            style: .normal,
            title: task.isDone ? "Undo" : "Done"
        ) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }

            task.isDone.toggle()
            _ = CoreDataStack.shared.save()
            completion(true)

            // Refresh after the swipe closes so the task can move in sort order.
            DispatchQueue.main.async {
                self.loadTasks()
            }
        }
        action.image = UIImage(systemName: task.isDone ? "arrow.uturn.backward" : "checkmark")
        action.backgroundColor = task.isDone ? .systemOrange : .systemGreen
        return UISwipeActionsConfiguration(actions: [action])
    }

    // A left swipe deletes the selected task from Core Data.
    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }

            let task = self.tasks[indexPath.row]
            self.context.delete(task)
            _ = CoreDataStack.shared.save()
            self.tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateEmptyState()
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    private func priorityName(for priority: Int16) -> String {
        switch priority {
        case 0: return "Low"
        case 2: return "High"
        default: return "Medium"
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowNotesSegue":
            guard let destination = segue.destination as? NotesViewController else {
                return
            }
            destination.subject = selectedSubject

        case "ShowTaskFormSegue":
            guard let destination = segue.destination as? TaskFormViewController else {
                return
            }
            destination.subject = selectedSubject
            destination.taskToEdit = sender as? TaskItem

        default:
            break
        }
    }
}
