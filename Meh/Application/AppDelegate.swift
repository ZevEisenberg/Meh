//
//  AppDelegate.swift
//  Meh
//
//  Created by Bradley Smith on 3/2/16
//  Copyright (c) 2016 Brad Smith. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = RootViewController(nibName: nil, bundle: nil)
        window?.makeKeyAndVisible()

        return true
    }
}
