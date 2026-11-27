import UIKit
import CoreData

final class NoteDetailViewController: UIViewController {

    var note: Note?

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Note"

        guard let note else { return }

        noteLabel.text = note.text
        dateLabel.text = note.createdAt?.formatted(
            date: .long,
            time: .shortened
        )

        if let data = note.photoData,
           let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFit
        } else {
            photoImageView.image = UIImage(systemName: "text.alignleft")
            photoImageView.contentMode = .center
            photoImageView.tintColor = .systemGray3
        }
    }

    @IBAction func deleteTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Delete this note?",
            message: "This cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )

        let deleteAction = UIAlertAction(
            title: "Delete",
            style: .destructive
        ) { [weak self] _ in
            guard let self, let note = self.note else { return }

            let context = CoreDataStack.shared.context
            context.delete(note)
            guard CoreDataStack.shared.save() else {
                context.rollback()
                self.showAlert(
                    title: "Could not delete note",
                    message: "Please try deleting it again."
                )
                return
            }
            self.navigationController?.popViewController(animated: true)
        }

        alert.addAction(deleteAction)
        present(alert, animated: true)
    }
}
