//
//  AppDelegate.swift
//  SwiftAdView
//
//  Created by mac on 2019/6/20.
//  Copyright © 2019年 mac. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        return true
    }


}

let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height
let statusBarHeight = UIApplication.shared.statusBarFrame.height
let screenFrame:CGRect = UIScreen.main.bounds
let safeAreaTopHeight:CGFloat = (screenHeight >= 812.0 && UIDevice.current.model == "iPhone" ? 88 : 64)
let safeAreaBottomHeight:CGFloat = (screenHeight >= 812.0 && UIDevice.current.model == "iPhone"  ? 34 : 0)
