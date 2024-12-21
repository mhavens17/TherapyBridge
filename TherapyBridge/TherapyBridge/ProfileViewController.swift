import UIKit

class ProfileViewController: UIViewController {

    // UI Elements
    private let firstNameTextField = UITextField()
    private let therapistEmailTextField = UITextField()
    @IBOutlet weak var saveButton: UIButton!
    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupUI()
        loadSavedData()
    }

    private func setupUI() {

        func styleTextField(_ textField: UITextField, placeholder: String) {
            textField.placeholder = placeholder
            textField.borderStyle = .roundedRect
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
            addDoneButtonToKeyboard(for: textField)
        }

        titleLabel.text = "Edit Profile"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        styleTextField(firstNameTextField, placeholder: "First Name")
        styleTextField(therapistEmailTextField, placeholder: "Therapist's Email")
        therapistEmailTextField.keyboardType = .emailAddress

        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        saveButton.isEnabled = false // Disabled initially
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)

        view.addSubview(titleLabel)
        view.addSubview(firstNameTextField)
        view.addSubview(therapistEmailTextField)
        view.addSubview(saveButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),

            // First Name Text Field
            firstNameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            firstNameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            firstNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            firstNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Therapist Email Text Field
            therapistEmailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            therapistEmailTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 20),
            therapistEmailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            therapistEmailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Save Button
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.topAnchor.constraint(equalTo: therapistEmailTextField.bottomAnchor, constant: 40)
        ])
    }

    private func addDoneButtonToKeyboard(for textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([doneButton], animated: false)

        textField.inputAccessoryView = toolbar
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func loadSavedData() {
        let defaults = UserDefaults.standard
        firstNameTextField.text = defaults.string(forKey: "firstName")
        therapistEmailTextField.text = defaults.string(forKey: "therapistEmail")

        textFieldEditingChanged()
    }

    @objc private func textFieldEditingChanged() {
        // Enable save only if all text fields are filled
        let isFormComplete = !(firstNameTextField.text?.isEmpty ?? true) &&
                             !(therapistEmailTextField.text?.isEmpty ?? true)
        saveButton.isEnabled = isFormComplete
    }

    @IBAction private func saveButtonTapped() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let therapistEmail = therapistEmailTextField.text, !therapistEmail.isEmpty else {
            return
        }

        let defaults = UserDefaults.standard
        defaults.set(firstName, forKey: "firstName")
        defaults.set(therapistEmail, forKey: "therapistEmail")

        // Debug
        print("Updated: First Name = \(firstName), Therapist Email = \(therapistEmail)")

        // Success
        let alert = UIAlertController(title: "Success", message: "Your changes were saved.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
