import UIKit

class StartViewController: UIViewController {

    // UI Elements
    private let firstNameTextField = UITextField()
    private let therapistEmailTextField = UITextField()
    @IBOutlet weak var nextButton: UIButton!
    private let smileIcon = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Check if data is already saved
        let defaults = UserDefaults.standard
        if let savedFirstName = defaults.string(forKey: "firstName"),
           let savedTherapistEmail = defaults.string(forKey: "therapistEmail"),
           !savedFirstName.isEmpty, !savedTherapistEmail.isEmpty {
            skipToTabBarController()
            return
        }

        setupUI()
        loadSavedData() // Load saved data into text fields
    }

    private func setupUI() {
        // Common styling for text fields
        func styleTextField(_ textField: UITextField, placeholder: String) {
            textField.placeholder = placeholder
            textField.borderStyle = .roundedRect
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        }

        // Configure smile icon
        smileIcon.image = UIImage(systemName: "smiley")?.withTintColor(.green, renderingMode: .alwaysOriginal)
        smileIcon.translatesAutoresizingMaskIntoConstraints = false

        // Configure title label
        titleLabel.text = "Therapy Bridge"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure subtitle label
        subtitleLabel.text = "Get started"
        subtitleLabel.font = UIFont.systemFont(ofSize: 18)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure text fields
        styleTextField(firstNameTextField, placeholder: "First Name")
        styleTextField(therapistEmailTextField, placeholder: "Therapist's Email")
        therapistEmailTextField.keyboardType = .emailAddress

        // Configure button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        nextButton.isEnabled = false // Disabled initially
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)

        // Add subviews
        view.addSubview(smileIcon)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(firstNameTextField)
        view.addSubview(therapistEmailTextField)
        view.addSubview(nextButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Smile Icon
            smileIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            smileIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            smileIcon.widthAnchor.constraint(equalToConstant: 100),
            smileIcon.heightAnchor.constraint(equalToConstant: 100),

            // Title Label
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: smileIcon.bottomAnchor, constant: 20),

            // Subtitle Label
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            // First Name Text Field
            firstNameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            firstNameTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            firstNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            firstNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Therapist Email Text Field
            therapistEmailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            therapistEmailTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 20),
            therapistEmailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            therapistEmailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Next Button
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.topAnchor.constraint(equalTo: therapistEmailTextField.bottomAnchor, constant: 40)
        ])
    }

    private func loadSavedData() {
        // Retrieve saved data from UserDefaults
        let defaults = UserDefaults.standard
        firstNameTextField.text = defaults.string(forKey: "firstName")
        therapistEmailTextField.text = defaults.string(forKey: "therapistEmail")

        // Update the button
        textFieldEditingChanged()
    }

    // If user has inputted info
    private func skipToTabBarController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            present(tabBarController, animated: true, completion: nil)
        }
    }

    @objc private func textFieldEditingChanged() {
        // Enable the next button only if all text fields are filled
        let isFormComplete = !(firstNameTextField.text?.isEmpty ?? true) &&
                             !(therapistEmailTextField.text?.isEmpty ?? true)
        nextButton.isEnabled = isFormComplete
    }

    @IBAction private func nextButtonTapped() {
        // Save the data
        let defaults = UserDefaults.standard
        defaults.set(firstNameTextField.text, forKey: "firstName")
        defaults.set(therapistEmailTextField.text, forKey: "therapistEmail")

        // Debug log to confirm saving
        print("Saved: First Name = \(firstNameTextField.text ?? ""), Therapist Email = \(therapistEmailTextField.text ?? "")")

        // Navigate to TabBarController
        skipToTabBarController()
    }
}
