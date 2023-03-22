//
//  AppDelegate.swift
//  TrainingCourse
//
//  Created by Mitch Baumgartner on 2/27/21.
//

import UIKit
import FirebaseCore
import IQKeyboardManagerSwift

// class that changes the color of the small letters at the very top of the app (time, battery life, wifi, etc) with white. THis class gives us the light content
class CustomNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // white color
        return .lightContent
    }
}

// this extension changes the color of the small letters at the very top of the app (time, battery life, wifi, etc) with white. THis class gives us the light content when the user taps to add a new image
//extension UINavigationController {
//    open override var perferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
//}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        

        FirebaseConfiguration.shared.setLoggerLevel(FirebaseLoggerLevel.min)
        FirebaseApp.configure()
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = false
        IQKeyboardManager.shared.toolbarDoneBarButtonItemText = "Done"

//        // anything that accesses navigationBar will contain these styling attributes
//        UINavigationBar.appearance().tintColor = .white
//        // makes navigation bar title to be large
        UINavigationBar.appearance().prefersLargeTitles = true
        // creates lighter color shade of red for navigation bar
        // makes navigation bar light red color from the variable we made
        UINavigationBar.appearance().barTintColor = UIColor.darkBlue
        // makes text "cancel" button white color
        UINavigationBar.appearance().tintColor = .white
        UIWindow.appearance().overrideUserInterfaceStyle = .light
        
        UITabBar.appearance().barTintColor = UIColor.darkBlue
        UITabBar.appearance().overrideUserInterfaceStyle = .light
        UITabBar.appearance().isTranslucent = true
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            UINavigationBar.appearance().tintColor = .white
            //appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.darkBlue
            //appearance.configureWithTransparentBackground()
            // makes large navigation bar title color white
            appearance.largeTitleTextAttributes = [.foregroundColor : UIColor.white] //portrait title
            // modifty regular text attributes on view controller as white color. There is a bug where if you scroll down the table view the "files" title at the top turns back to the black default
            appearance.titleTextAttributes = [.foregroundColor : UIColor.white] //landscape title
            appearance.shadowColor = .clear

            UINavigationBar.appearance().tintColor = .white
            UINavigationBar.appearance().standardAppearance = appearance //landscape
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance //portrait





        } else {

            UINavigationBar.appearance().isTranslucent = true
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

