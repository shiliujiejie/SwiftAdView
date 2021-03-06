
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var isLandscape = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        return true
    }
    
    //  整个项目支持竖屏，播放页面需要横屏，导入播放器头文件，添加下面方法：
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?)
        -> UIInterfaceOrientationMask {
            guard let num = R_PlayerOrietation(rawValue: orientationSupport.rawValue) else {
                return [.portrait]
            }
            return num.getOrientSupports()           // 这里的支持方向，做了组件化的朋友，实际项目中可以考虑用路由去播放器内拿，
    }
//    //  整个项目支持竖屏，播放页面需要横屏
//    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?)
//        -> UIInterfaceOrientationMask {
//        if isLandscape {
//            return .allButUpsideDown
//        }
//        return .portrait
//    }

}

let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height
let statusBarHeight: CGFloat = (screenHeight >= 812.0 && UIDevice.current.model == "iPhone" ? 44 : 20)
let screenFrame: CGRect = UIScreen.main.bounds
let safeAreaTopHeight:CGFloat = (screenHeight >= 812.0 && UIDevice.current.model == "iPhone" ? 88 : 64)
let safeAreaBottomHeight:CGFloat = (screenHeight >= 812.0 && UIDevice.current.model == "iPhone"  ? 34 : 0)
































































