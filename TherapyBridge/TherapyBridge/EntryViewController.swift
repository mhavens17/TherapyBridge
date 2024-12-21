import UIKit
import MessageUI

protocol EntryViewControllerDelegate: AnyObject {
    func entryViewControllerDidDeleteEntry(_ viewController: EntryViewController)
}

class EntryViewController: UIViewController, MFMailComposeViewControllerDelegate {
    weak var delegate: EntryViewControllerDelegate?
    
    private let entry: JournalEntry
    private let textView = UITextView()
    private let deleteButton = UIButton()
    private let sendEmailButton = UIButton()
    
    init(entry: JournalEntry) {
        self.entry = entry
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(editEntry))
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = DateFormatter.localizedString(from: entry.date, dateStyle: .medium, timeStyle: .none)
        
        // Configure the textView
        textView.text = "Mood: \(entry.mood)\n\n\(entry.text)"
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false
        view.addSubview(textView)
        
        // Configure delete
        deleteButton.setTitle("Delete Entry", for: .normal)
        deleteButton.backgroundColor = .systemRed
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.layer.cornerRadius = 5
        deleteButton.addTarget(self, action: #selector(deleteEntry), for: .touchUpInside)
        view.addSubview(deleteButton)
        
        // Configure sendEmailButton
        sendEmailButton.setTitle("Send Entry via Email", for: .normal)
        sendEmailButton.backgroundColor = .systemBlue
        sendEmailButton.setTitleColor(.white, for: .normal)
        sendEmailButton.layer.cornerRadius = 5
        sendEmailButton.addTarget(self, action: #selector(sendEmail), for: .touchUpInside)
        view.addSubview(sendEmailButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        sendEmailButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // TextView constraints
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: sendEmailButton.topAnchor, constant: -20),
            
            // Send Email Button constraints
            sendEmailButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendEmailButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendEmailButton.bottomAnchor.constraint(equalTo: deleteButton.topAnchor, constant: -20),
            sendEmailButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Delete Button constraints
            deleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            deleteButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func sendEmail() {
        // Check if email is available on this device
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertController(title: "Email Unavailable", message: "This device is not configured to send emails.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Create and configure the mail composer
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self

        // Get the therapist email
        let therapistEmail = UserDefaults.standard.string(forKey: "therapistEmail") ?? ""

        // Format email
        let emailContent = """
        <div>
            <p><strong>Date:</strong> \(DateFormatter.localizedString(from: entry.date, dateStyle: .medium, timeStyle: .none))</p>
            <p><strong>Mood:</strong> \(entry.mood)</p>
            <p>\(entry.text.replacingOccurrences(of: "\n", with: "<br>"))</p>
        </div>
        <hr>
        """

        // Configure the email fields
        mailComposeVC.setToRecipients([therapistEmail])
        let formattedDate = DateFormatter.localizedString(from: entry.date, dateStyle: .medium, timeStyle: .none)
        mailComposeVC.setSubject("TherapyBridge: \(formattedDate) - Journal Entry")
        mailComposeVC.setMessageBody(emailContent, isHTML: true)

        present(mailComposeVC, animated: true)
    }

    @objc private func deleteEntry() {
        var entries = loadEntries()
        
        if let index = entries.firstIndex(where: { $0.date == entry.date && $0.mood == entry.mood && $0.text == entry.text }) {
            entries.remove(at: index)
        }
        
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "journalEntries")
        }
        
        delegate?.entryViewControllerDidDeleteEntry(self) // Notify the delegate
        navigationController?.popViewController(animated: true)
    }

    @objc private func editEntry() {
        let addEntryViewController = AddEntryViewController()
        addEntryViewController.loadViewIfNeeded()

        addEntryViewController.datePicker.date = entry.date
        if let moodIndex = addEntryViewController.moodOptions.firstIndex(of: entry.mood) {
            addEntryViewController.moodPicker.selectRow(moodIndex, inComponent: 0, animated: false)
        }
        addEntryViewController.textView.text = entry.text
        
        addEntryViewController.isEdit = true;

        addEntryViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveEditedEntry))


        navigationController?.pushViewController(addEntryViewController, animated: true)
    }

    @objc private func saveEditedEntry() {
        // Update the entry
        let addEntryVC = navigationController?.topViewController as? AddEntryViewController
        if let updatedVC = addEntryVC {
            let updatedEntry = JournalEntry(
                date: updatedVC.datePicker.date,
                mood: updatedVC.moodOptions[updatedVC.moodPicker.selectedRow(inComponent: 0)],
                text: updatedVC.textView.text
            )

            // Replace the old entry
            var entries = loadEntries()
            if let index = entries.firstIndex(where: { $0.date == entry.date && $0.mood == entry.mood && $0.text == entry.text }) {
                entries[index] = updatedEntry
            }

            if let encoded = try? JSONEncoder().encode(entries) {
                UserDefaults.standard.set(encoded, forKey: "journalEntries")
            }

            // Update the current view
            textView.text = "Mood: \(updatedEntry.mood)\n\(updatedEntry.text)"
            title = DateFormatter.localizedString(from: updatedEntry.date, dateStyle: .medium, timeStyle: .none)

            navigationController?.popViewController(animated: true)
        }
    }
    
    private func loadEntries() -> [JournalEntry] {
        if let data = UserDefaults.standard.data(forKey: "journalEntries"),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            return decoded
        }
        return []
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

        controller.dismiss(animated: true)

        // Handle Result
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
