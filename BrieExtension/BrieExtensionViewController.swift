import SafariServices

class BrieExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: BrieExtensionViewController = {
        let shared = BrieExtensionViewController()
        shared.preferredContentSize = NSSize(width: 320, height: 240)
        return shared
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = NSSize(width: 320, height: 240)
    }
}

