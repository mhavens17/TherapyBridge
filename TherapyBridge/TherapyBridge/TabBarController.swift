import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let viewControllers = self.viewControllers else { return }

        // Set the icons and titles
        let tabBarIcons = [
            ("pencil", "Journal Entries"),
            ("note.text", "Checklist"),
            ("lightbulb.fill", "Resources")
        ]
        
        for (index, vc) in viewControllers.enumerated() {
            guard index < tabBarIcons.count else { break }
            let (iconName, title) = tabBarIcons[index]
            vc.tabBarItem.image = UIImage(systemName: iconName)
            vc.tabBarItem.title = title
        }
        
        // Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemGreen
        
        appearance.stackedLayoutAppearance.normal.iconColor = .white
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabBar.standardAppearance
        }
    }
}
