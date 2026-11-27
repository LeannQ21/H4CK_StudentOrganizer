import UIKit
import CoreData

private enum SubjectsPurple {
    static let accent = UIColor(red: 0.42, green: 0.25, blue: 0.63, alpha: 1)
    static let row = UIColor(red: 0.97, green: 0.95, blue: 0.99, alpha: 1)
    static let secondaryText = UIColor(red: 0.48, green: 0.38, blue: 0.59, alpha: 1)
}

class SubjectsViewController: UITableViewController {

    private var subjects: [Subject] = []
    private let context = CoreDataStack.shared.context

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Subjects"

        view.tintColor = SubjectsPurple.accent
        tableView.tintColor = SubjectsPurple.accent
        tableView.separatorColor = SubjectsPurple.accent.withAlphaComponent(0.18)
        navigationController?.navigationBar.tintColor = SubjectsPurple.accent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSubjects()
    }

    private func loadSubjects() {
        let request: NSFetchRequest<Subject> = Subject.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]

        do {
            subjects = try context.fetch(request)
        } catch {
            print("Could not fetch subjects: \(error)")
            subjects = []
        }

        if subjects.isEmpty {
            let label = emptyStateLabel("No subjects yet.\nTap + to add one.")
            label.textColor = SubjectsPurple.secondaryText
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }

        tableView.reloadData()
    }

    @IBAction func addSubjectTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "New Subject",
            message: "Enter the name of the subject.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Enter the name of the subject"
            textField.autocapitalizationType = .words
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

                let name = text.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                guard !name.isEmpty else {
                    return
                }

                let subject = Subject(context: self.context)
                subject.name = name
                subject.createdAt = Date()

                CoreDataStack.shared.save()
                self.loadSubjects()
            }
        )

        present(alert, animated: true)
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        subjects.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SubjectCell",
            for: indexPath
        )

        let subject = subjects[indexPath.row]
        let allTasks = subject.tasks as? Set<TaskItem> ?? []
        let pendingCount = allTasks.filter { !$0.isDone }.count

        var content = cell.defaultContentConfiguration()
        content.text = subject.name ?? "Untitled subject"
        content.secondaryText = "\(pendingCount) pending task(s)"
        content.secondaryTextProperties.color = SubjectsPurple.secondaryText
        cell.contentConfiguration = content

        var background = UIBackgroundConfiguration.listPlainCell()
        background.backgroundColor = SubjectsPurple.row
        cell.backgroundConfiguration = background

        cell.accessoryType = .disclosureIndicator
        cell.tintColor = SubjectsPurple.accent

        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let subject = subjects[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowTasksSegue", sender: subject)
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete else {
            return
        }

        context.delete(subjects[indexPath.row])
        CoreDataStack.shared.save()

        subjects.remove(at: indexPath.row)

        tableView.deleteRows(
            at: [indexPath],
            with: .automatic
        )

        if subjects.isEmpty {
            let label = emptyStateLabel("No subjects yet.\nTap + to add one.")
            label.textColor = SubjectsPurple.secondaryText
            tableView.backgroundView = label
        }
    }

    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {
        guard segue.identifier == "ShowTasksSegue",
              let tasksViewController = segue.destination as? TasksViewController,
              let selectedSubject = sender as? Subject else {
            return
        }

        tasksViewController.selectedSubject = selectedSubject
    }
}
