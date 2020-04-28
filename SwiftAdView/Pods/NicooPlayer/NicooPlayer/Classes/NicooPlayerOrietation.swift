//
//  NicooPlayerOrietation.swift
//
//  Created by 小星星 on 2018/6/27.
//

import UIKit

public enum NicooPlayerOrietation: Int {
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
public var orientationSupport: NicooPlayerOrietation = .orientationPortrait

// log
public func NLog(_ item: Any, _ file: String = #file,  _ line: Int = #line, _ function: String = #function) {
    #if DEBUG
    print(file + ":\(line):" + function, item)
    #endif
}
