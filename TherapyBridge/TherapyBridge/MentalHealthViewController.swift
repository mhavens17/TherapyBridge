import UIKit

class MentalHealthViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // Structure for hotlines
    struct Hotline {
        let category: String
        let name: String
        let number: String
    }

    let hotlines: [Hotline] = [
        Hotline(category: "Suicide Prevention", name: "National Suicide Prevention Lifeline", number: "988"),
        Hotline(category: "Domestic Violence and Abuse", name: "National Domestic Violence Hotline", number: "8007997233"),
        Hotline(category: "Substance Abuse", name: "SAMHSA National Helpline", number: "8006624357"),
        Hotline(category: "Sexual Assault", name: "RAINN National Sexual Assault Hotline", number: "8006564673"),
        Hotline(category: "Child Abuse", name: "Childhelp National Child Abuse Hotline", number: "8004224453"),
        Hotline(category: "Elder Abuse", name: "Elder Abuse Hotline", number: "8006771116")
    ]

    // Table view
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mental Health Resources"
        view.backgroundColor = .systemBackground

        // Set up table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HotlineCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        // Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hotlines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HotlineCell", for: indexPath)
        let hotline = hotlines[indexPath.row]

        cell.textLabel?.text = "\(hotline.category): \(hotline.name) - \(hotline.number)"
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.accessoryType = .none

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Handle tap and show confirmation alert
        let hotline = hotlines[indexPath.row]

        if hotline.number.lowercased() != "contact local chapter" { // Skip invalid numbers
            showCallConfirmationAlert(for: hotline)
        }
    }

    // MARK: - Call Confirmation

    func showCallConfirmationAlert(for hotline: Hotline) {
        let alertController = UIAlertController(
            title: "Call \(hotline.name)?",
            message: "Do you want to call \(hotline.number)?",
            preferredStyle: .alert
        )

        // Call action
        let callAction = UIAlertAction(title: "Call", style: .default) { _ in
            if let phoneURL = URL(string: "tel://\(hotline.number)") {
                UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
            }
        }

        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(callAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}
