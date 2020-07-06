
import UIKit

public enum PlayerOrietation: Int {
    case orientationPortrait
    case orientationLeftAndRight
    case orientationAll
    
    public func getOrientSupports() -> UIInterfaceOrientationMask {
        switch self {
        case .orientationPortrait:
            return [.portrait]
        case .orientationLeftAndRight:
            return [.landscapeLeft, .landscapeRight]
        case .orientationAll:
            return [.portrait, .landscapeLeft, .landscapeRight]
        }
    }
}
public var orientationSupport: PlayerOrietation = .orientationPortrait

// log
public func NLog(_ item: Any, _ file: String = #file,  _ line: Int = #line, _ function: String = #function) {
    #if DEBUG
    print(file + ":\(line):" + function, item)
    #endif
}
