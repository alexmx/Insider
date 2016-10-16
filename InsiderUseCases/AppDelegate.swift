//
//  AppDelegate.swift
//  InsiderUseCases
//
//  Created by Alexandru Maimescu on 3/17/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import UIKit

import Insider

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        Insider.shared.start(withDelegate: self)
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        
        let alertController = UIAlertController(
            title: "Insider Demo",
            message: "Did receive Push Notification with payload: \(userInfo.description)",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in }
        alertController.addAction(cancelAction)
        
        self.window?.rootViewController!.present(alertController, animated: true) {}
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        // Process custom scheme invocation
        print(url)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate: InsiderDelegate {
    
    func insider(_ insider: Insider, invokeMethodWithParams params: JSONDictionary?) {
        // Simulate push notification
        application(UIApplication.shared, didReceiveRemoteNotification: params!)
    }
    
    func insider(_ insider: Insider, invokeMethodForResponseWithParams params: JSONDictionary?) -> JSONDictionary? {
        // Simulate app invokation using a custom scheme
        let url = URL(string: "insiderDemo://hello/params")
        let response = application(UIApplication.shared, handleOpen: url!)
        
        return ["response" as NSObject : response as AnyObject]
    }
}

