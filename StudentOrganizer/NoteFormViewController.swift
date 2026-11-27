import UIKit
import PhotosUI
import CoreData

private enum PurplePalette {
    // A clear purple for buttons and navigation controls.
    static let accent = UIColor(red: 0.42, green: 0.25, blue: 0.63, alpha: 1)

    // A very light purple for the photo placeholder and text field border.
    static let soft = UIColor(red: 0.96, green: 0.93, blue: 0.99, alpha: 1)
    static let border = UIColor(red: 0.80, green: 0.72, blue: 0.90, alpha: 1)
}

final class NoteFormViewController: UIViewController,
                                   PHPickerViewControllerDelegate {

    var subject: Subject?
    private var selectedImage: UIImage?

    @IBOutlet private weak var noteTextView: UITextView!
    @IBOutlet private weak var photoImageView: UIImageView!
    @IBOutlet private weak var choosePhotoButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "New Note"

        // Apply purple to the navigation controls without changing the layout.
        view.tintColor = PurplePalette.accent
        navigationController?.navigationBar.tintColor = PurplePalette.accent
        navigationItem.rightBarButtonItem?.tintColor = PurplePalette.accent

        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = PurplePalette.border.cgColor
        noteTextView.layer.cornerRadius = 8

        photoImageView.image = UIImage(systemName: "photo")
        photoImageView.tintColor = PurplePalette.accent.withAlphaComponent(0.55)
        photoImageView.backgroundColor = PurplePalette.soft
        photoImageView.layer.cornerRadius = 12
        photoImageView.clipsToBounds = true
        photoImageView.contentMode = .center

        // Set the button's actual fill color to purple.
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.title = "Choose Photo"
        buttonConfiguration.baseBackgroundColor = PurplePalette.accent
        buttonConfiguration.baseForegroundColor = .white
        choosePhotoButton.configuration = buttonConfiguration

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

    @IBAction private func choosePhotoTapped(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction private func saveTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)

        let text = (noteTextView.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            showAlert(
                title: "Note is empty",
                message: "Please write something before saving."
            )
            return
        }

        guard let subject else {
            showAlert(
                title: "Subject unavailable",
                message: "Return to a subject and open its Notes screen again."
            )
            return
        }

        let note = Note(context: CoreDataStack.shared.context)
        note.text = text
        note.createdAt = Date()
        note.photoData = selectedImage?.jpegData(compressionQuality: 0.8)
        note.subject = subject

        guard CoreDataStack.shared.save() else {
            showAlert(
                title: "Could not save note",
                message: "Please try saving again."
            )
            return
        }

        navigationController?.popViewController(animated: true)
    }

    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else {
                return
            }

            let smallImage = image.resized(maxDimension: 1024)

            DispatchQueue.main.async {
                self?.selectedImage = smallImage
                self?.photoImageView.image = smallImage
                self?.photoImageView.backgroundColor = .clear
                self?.photoImageView.contentMode = .scaleAspectFit
            }
        }
    }
}
