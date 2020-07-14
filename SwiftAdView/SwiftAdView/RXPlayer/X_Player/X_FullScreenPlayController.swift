
import UIKit
import AVKit

class X_FullScreenPlayController: AVPlayerViewController {

    override var shouldAutorotate: Bool  {
        return true
    }
    
    deinit {
        print("X_FullScreenPlayController - deinit")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player?.play()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player = nil
    }
}
