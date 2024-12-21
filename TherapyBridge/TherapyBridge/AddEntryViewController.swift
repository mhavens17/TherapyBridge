import UIKit

class AddEntryViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    struct JournalEntry: Codable {
        let date: Date
        let mood: String
        let text: String
    }
    
    // UI Components
    private let titleLabel = UILabel()
    public let datePicker = UIDatePicker()
    private let moodLabel = UILabel()
    public let moodPicker = UIPickerView()
    public let textView = UITextView()
    private let submitButton = UIButton()
    
    public var isEdit: Bool = false {
        didSet {
            submitButton.isHidden = isEdit
            titleLabel.text = isEdit ? "Edit Journal Entry" : "Add Journal Entry"
        }
    }
    
    // Data for mood picker
    public let moodOptions = ["Great", "Good", "Okay", "Meh", "Sad", "Angry", "Anxious", "Excited", "Tired", "Lonely", "Grateful", "Hopeful", "Stressed"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Setup UI
        setupUI()
        setupConstraints()
        setupTapToDismissKeyboard()
        setupKeyboardToolbar()
        submitButton.isHidden = isEdit
        titleLabel.text = isEdit ? "Edit Journal Entry" : "Add Journal Entry"
    }
    
    private func setupUI() {
        // Title Label
        titleLabel.text = "Add Journal Entry"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Date Picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        view.addSubview(datePicker)
        
        // Mood Label
        moodLabel.text = "Mood"
        moodLabel.font = UIFont.systemFont(ofSize: 18)
        moodLabel.textAlignment = .center
        view.addSubview(moodLabel)
        
        // Mood Picker
        moodPicker.delegate = self
        moodPicker.dataSource = self
        view.addSubview(moodPicker)
        
        // Text View (Scrollable)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.text = ""
        textView.delegate = self
        
        // Placeholder for text
        textView.text = "How was your day?"
        textView.textColor = .lightGray
        
        view.addSubview(textView)
        
        // Submit Button
        submitButton.setTitle("Submit", for: .normal)
        submitButton.addTarget(self, action: #selector(submitEntry), for: .touchUpInside)
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 5
        view.addSubview(submitButton)
    }

    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))

        toolbar.items = [flexSpace, doneButton]
        textView.inputAccessoryView = toolbar
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func submitEntry() {
        let selectedDate = datePicker.date
        let selectedMood = moodOptions[moodPicker.selectedRow(inComponent: 0)]
        var journalText = textView.text ?? ""

        // Check if the textView is empty or contains placeholder
        if textView.text == "How was your day?" || textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            journalText = ""
        }

        let entry = JournalEntry(date: selectedDate, mood: selectedMood, text: journalText)
        saveEntry(entry)
        
        // Navigate back to the previous view
        navigationController?.popViewController(animated: true)
    }

    private func saveEntry(_ entry: JournalEntry) {
        var entries = loadEntries()
        entries.append(entry)
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "journalEntries")
        }
    }

    private func loadEntries() -> [JournalEntry] {
        if let data = UserDefaults.standard.data(forKey: "journalEntries"), let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            return decoded
        }
        return []
    }

    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        moodLabel.translatesAutoresizingMaskIntoConstraints = false
        moodPicker.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Title Label Constraints
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Date Picker Constraints
            datePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Mood Label Constraints
            moodLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 10),
            moodLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Mood Picker Constraints
            moodPicker.topAnchor.constraint(equalTo: moodLabel.bottomAnchor, constant: 5),
            moodPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            moodPicker.heightAnchor.constraint(equalToConstant: 80),
            moodPicker.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            
            // Text View Constraints
            textView.topAnchor.constraint(equalTo: moodPicker.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 200),
            
            // Submit Button Constraints
            submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 30),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 100),
            submitButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - UIPickerView DataSource Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return moodOptions.count
    }
    
    // MARK: - UIPickerView Delegate Methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return moodOptions[row]
    }
}

// MARK: - UITextViewDelegate
extension AddEntryViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "How was your day?" {
            textView.text = ""
            textView.textColor = .black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "How was your day?"
            textView.textColor = .lightGray
        }
    }
}
