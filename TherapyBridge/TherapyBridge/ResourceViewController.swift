import UIKit

class ResourceViewController: UIViewController {

    @IBOutlet weak var lightbulbIcon: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLightbulbIcon()
    }

    private func setupLightbulbIcon() {
        lightbulbIcon.image = UIImage(systemName: "lightbulb")
        //lightbulbIcon.translatesAutoresizingMaskIntoConstraints = false
        lightbulbIcon.tintColor = .systemYellow
    }
}
