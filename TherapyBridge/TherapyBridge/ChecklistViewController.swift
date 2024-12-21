import UIKit
import SwiftUI
import MessageUI

class ChecklistItem: Codable {
    let title: String
    var isChecked: Bool
    
    init(title: String, isChecked: Bool = false) {
        self.title = title
        self.isChecked = isChecked
    }
}

class ChecklistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    
    private let userDefaultsKey = "ChecklistItems"
    var items: [ChecklistItem] = []
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Set navigation bar title
        navigationItem.title = getCurrentDate()

        // Add navigation bar buttons
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareButtonTapped)
        )

        // Setup tableView
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self

        // Setup constraints for tableView
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadItems()
    }
    
    @objc private func addButtonTapped() {

        let addItemVC = AddItemViewController()
        addItemVC.delegate = self
        present(addItemVC, animated: true)
    }

    @objc private func shareButtonTapped() {
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertController(title: "Email Unavailable", message: "This device is not configured to send emails.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self

        let therapistEmail = UserDefaults.standard.string(forKey: "therapistEmail") ?? ""
        mailComposeVC.setToRecipients([therapistEmail])

        let currentDate = getCurrentDate()
        mailComposeVC.setSubject("Therapy Bridge - Checklist - \(currentDate)")

        let checklistContent = items.map { item in
            "<li>\(item.isChecked ? "✅" : "❌") \(item.title)</li>"
        }.joined(separator: "")

        mailComposeVC.setMessageBody("<html><body><ul>\(checklistContent)</ul></body></html>", isHTML: true)

        present(mailComposeVC, animated: true)
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedItems = try? JSONDecoder().decode([ChecklistItem].self, from: data) {
            items = savedItems
        }
    }
    
    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // Get Date
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }

    // MARK: - TableView DataSource and Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.isChecked ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].isChecked.toggle()
        saveItems()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            saveItems()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // MARK: - MailCompose

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)

        switch result {
        case .sent:
            print("Email sent successfully.")
        case .saved:
            print("Email draft saved.")
        case .cancelled:
            print("Email composition cancelled.")
        case .failed:
            print("Failed to send email: \(error?.localizedDescription ?? "Unknown error")")
        @unknown default:
            break
        }
    }
}

// MARK: - AddItemViewController

protocol AddItemViewControllerDelegate: AnyObject {
    func didAddItem(_ item: ChecklistItem)
}

class AddItemViewController: UIViewController, UITextFieldDelegate {
    
    weak var delegate: AddItemViewControllerDelegate?
    
    private let textField: UITextField = {
        let field = UITextField()
        field.placeholder = "Add to checklist"
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return field
    }()
    
    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        textField.delegate = self
        
        view.addSubview(textField)
        view.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            submitButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 100),
            submitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        
        // Add done button to keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([doneButton], animated: false)
        textField.inputAccessoryView = toolbar
    }
    
    @objc private func submitButtonTapped() {
        guard let text = textField.text, !text.isEmpty else { return }
        let newItem = ChecklistItem(title: text)
        delegate?.didAddItem(newItem)
        dismiss(animated: true)
    }
    
    @objc private func doneButtonTapped() {
        textField.resignFirstResponder()
    }
}

// MARK: - AddItemViewControllerDelegate Implementation

extension ChecklistViewController: AddItemViewControllerDelegate {
    func didAddItem(_ item: ChecklistItem) {
        items.append(item)
        saveItems()
        tableView.reloadData()
    }
}

// Canvas
struct ChecklistViewPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ChecklistViewController {
        return ChecklistViewController()
    }
    
    func updateUIViewController(_ uiViewController: ChecklistViewController, context: Context) {
        // No updates needed for now
    }
}

struct ChecklistViewPreview_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistViewPreview()
            .ignoresSafeArea()
    }
}
