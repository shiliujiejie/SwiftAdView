
import UIKit

class ViewController: UIViewController {

    private let lauchScreen: UIImageView = {
        let imagev = UIImageView(image: UIImage(named: "guide02"))
        imagev.contentMode = .scaleAspectFill
        imagev.isUserInteractionEnabled = true
        return imagev
    }()
    
    var isShow: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(lauchScreen)
        lauchScreen.frame = view.bounds
        lauchScreen.setImage(urlString: "https://github.com/shiliujiejie/adResource/raw/master/folding-cell.gifg", placeHolder: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let rootVC = RootViewController()
            let nav = UINavigationController(rootViewController: rootVC)
            delegate.window?.rootViewController = nav
        }
        
    }

}
