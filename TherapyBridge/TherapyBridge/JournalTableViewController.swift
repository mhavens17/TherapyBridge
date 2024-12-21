import UIKit
import Foundation
import MessageUI

class JournalTableViewController: UITableViewController {
    
    // Array for list journal entries.
    private var journalEntries: [JournalEntry] = []
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Journal Entries"
        
        // Add entry
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addEntry))

        // Share entry button/icon
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareEntries))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "JournalEntryCell")

        tableView.delegate = self
        tableView.dataSource = self

        // Loading entries from userDefaults
        loadEntries()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload the table view to ensure the latest entries are displayed.
        loadEntries()
        tableView.reloadData()
    }
    
    // Method to load saved entries
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "journalEntries"),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            journalEntries = decoded.sorted { $0.date > $1.date }
        }
    }

    // Method to navigate to the AddEntryViewController
    @objc private func addEntry() {
        let addEntryViewController = AddEntryViewController()
        navigationController?.pushViewController(addEntryViewController, animated: true)
    }

    // Method to handle sharing entries
    @objc private func shareEntries() {
        let alert = UIAlertController(title: "What entries do you want to send?", message: nil, preferredStyle: .actionSheet)

        let options: [(String, TimeInterval)] = [
            ("Last 7 Days", 7 * 24 * 60 * 60),
            ("Last 2 Weeks", 14 * 24 * 60 * 60),
            ("Last Month", 30 * 24 * 60 * 60),
            ("Last 3 Months", 90 * 24 * 60 * 60)
        ]

        for (title, range) in options {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.composeMessage(forRange: range)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func composeMessage(forRange range: TimeInterval) {
        let cutoffDate = Date().addingTimeInterval(-range)

        let filteredEntries = journalEntries.filter { $0.date >= cutoffDate }

        let emailContent = filteredEntries.map { entry in
            """
            <div>
                <p><strong>Date:</strong> \(dateFormatter.string(from: entry.date))</p>
                <p><strong>Mood:</strong> \(entry.mood)</p>
                <p>\(entry.text.replacingOccurrences(of: "\n", with: "<br>"))</p>
                <hr>
            </div>
            """
        }.joined(separator: "")

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
        let dateRangeDescription: String
        switch range {
        case 7 * 24 * 60 * 60:
            dateRangeDescription = "Last 7 Days"
        case 14 * 24 * 60 * 60:
            dateRangeDescription = "Last 2 Weeks"
        case 30 * 24 * 60 * 60:
            dateRangeDescription = "Last Month"
        case 90 * 24 * 60 * 60:
            dateRangeDescription = "Last 3 Months"
        default:
            dateRangeDescription = "Custom Range"
        }

        mailComposeVC.setSubject("TherapyBridge: \(dateRangeDescription) - Journal Entries")
        mailComposeVC.setMessageBody(emailContent, isHTML: true)

        present(mailComposeVC, animated: true)
    }

    // MARK: - Table view
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Single section
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return journalEntries.count // Number of rows based on entries count.
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Reusing the cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: "JournalEntryCell", for: indexPath)
        
        // Configuring the cell.
        let entry = journalEntries[indexPath.row]
        let truncatedText = String(entry.text.prefix(50))
        cell.textLabel?.text = "\(dateFormatter.string(from: entry.date)) - \(truncatedText)"
        cell.accessoryType = .disclosureIndicator // Adding indicator to show there is more content.
        
        return cell
    }
    
    // MARK: - delegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Getting the selected entry.
        let entry = journalEntries[indexPath.row]
        
        print("Selected entry: \(entry)")
        
        // Initializing the detail view controller with the selected entry.
        let detailViewController = EntryViewController(entry: entry)
        detailViewController.delegate = self // Ensure this is set

        // Pushing detail view controller onto the navigation stack.
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension JournalTableViewController: EntryViewControllerDelegate {
    func entryViewControllerDidDeleteEntry(_ viewController: EntryViewController) {
        // Reload the journal entries after an entry is deleted.
        loadEntries()
        tableView.reloadData()
    }
}

extension JournalTableViewController: MFMailComposeViewControllerDelegate {
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
