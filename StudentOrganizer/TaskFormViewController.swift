import UIKit
import CoreData

final class TaskFormViewController: UIViewController, UITextFieldDelegate {

    // The Tasks screen supplies the subject, and supplies a task only in edit mode.
    var subject: Subject?
    var taskToEdit: TaskItem?

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var prioritySegmentedControl: UISegmentedControl!
    @IBOutlet weak var completedSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleTextField.delegate = self
        detailsTextField.delegate = self
        titleTextField.autocapitalizationType = .sentences
        detailsTextField.autocapitalizationType = .sentences
        detailsTextField.returnKeyType = .done
        dueDatePicker.datePickerMode = .dateAndTime

        if let task = taskToEdit {
            title = "Edit Task"
            titleTextField.text = task.title
            detailsTextField.text = task.details
            dueDatePicker.date = task.dueDate ?? Date()

            let savedPriority = Int(task.priority)
            prioritySegmentedControl.selectedSegmentIndex =
                (0...2).contains(savedPriority) ? savedPriority : 1
            completedSwitch.isOn = task.isDone
        } else {
            title = "New Task"
            dueDatePicker.date = Date()
            prioritySegmentedControl.selectedSegmentIndex = 1
            completedSwitch.isOn = false
        }

        // Add a visible Save button to the navigation bar.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped(_:))
        )

        // Let the user dismiss the keyboard without interfering with control taps.
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === titleTextField {
            detailsTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)

        let taskTitle = (titleTextField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !taskTitle.isEmpty else {
            showAlert(
                title: "Title required",
                message: "Please type a title for your task."
            )
            return
        }

        guard taskToEdit != nil || subject != nil else {
            showAlert(
                title: "Subject unavailable",
                message: "Return to a subject and open its Tasks screen again."
            )
            return
        }

        let task = taskToEdit ?? TaskItem(context: CoreDataStack.shared.context)
        task.title = taskTitle

        let details = (detailsTextField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        task.details = details.isEmpty ? nil : details
        task.dueDate = dueDatePicker.date
        task.priority = Int16(prioritySegmentedControl.selectedSegmentIndex)
        task.isDone = completedSwitch.isOn

        if taskToEdit == nil {
            task.subject = subject
        }

        guard CoreDataStack.shared.save() else {
            showAlert(
                title: "Could not save task",
                message: "Please try saving again."
            )
            return
        }

        navigationController?.popViewController(animated: true)
    }
}
