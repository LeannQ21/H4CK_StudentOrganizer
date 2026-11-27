import UIKit

final class NoteCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        contentView.backgroundColor = .secondarySystemBackground

        photoImageView.clipsToBounds = true
        photoImageView.contentMode = .scaleAspectFill
    }

    func configure(with note: Note) {
        noteLabel.text = note.text

        if let data = note.photoData,
           let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFill
            photoImageView.tintColor = nil
        } else {
            photoImageView.image = UIImage(systemName: "text.alignleft")
            photoImageView.contentMode = .center
            photoImageView.tintColor = .systemGray3
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        noteLabel.text = nil
    }
}
