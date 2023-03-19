//
//  SceneDelegate.swift
//  TrainingCourse
//
//  Created by Mitch Baumgartner on 2/27/21.
//
import FirebaseAuth
import Firebase
import SwiftUI


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    let db = Firestore.firestore()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
//        // Use a UIHostingController as window root view controller.
//        if let windowScene = scene as? UIWindowScene {
//            let window = UIWindow(windowScene: windowScene)
//            
//            let filesController = FilesController()
//            let navController = CustomNavigationController(rootViewController: filesController)
//            window.rootViewController = navController
//            
//            self.window = window
//            window.makeKeyAndVisible()
//        }
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        if Auth.auth().currentUser != nil {
            print("sceneDelegate signed in")
//            return self.signInVC()
            guard let uid = Auth.auth().currentUser?.uid else { return self.signInVC() }
            db.collection("Users").document(uid).getDocument(completion: { snapshot, error in
                if let err = error {
                    debugPrint("Error fetching profile: \(err)")
                } else {
                    if let data = snapshot?.data() {
                        let companyId = data["companyId"] as? String
                        
                        if companyId != "" {
                            return self.setTabs()
                        } else {
                            return self.setNoTabs()
                        }
                    }
                }
            })
            
        } else {
            print("sceneDelegate signed out")
            return self.signInVC()
        }
        
        
    }
    
    func signInVC() {
        let signInController = SignInController()
        let navController = CustomNavigationController(rootViewController: signInController)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
    }
    
    func setTabs() {
        let tabBar = UITabBarController()
        
        let filesVC = CustomNavigationController(rootViewController: FilesController())
        let teamVC = CustomNavigationController(rootViewController: TeamController())
        
        filesVC.tabBarItem = UITabBarItem(title: "My Files", image: UIImage(systemName: "folder.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), tag: 0)
        teamVC.tabBarItem = UITabBarItem(title: "Team", image: UIImage(systemName: "person.3.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular)), tag: 1)
        tabBar.setViewControllers([filesVC, teamVC], animated: false)
        tabBar.tabBar.tintColor = UIColor.white
        tabBar.tabBar.backgroundColor = UIColor.darkBlue
        
        window?.rootViewController = tabBar
        window?.makeKeyAndVisible()
    }
    
    func setNoTabs() {
        let filesController = FilesController()
        let navController = CustomNavigationController(rootViewController: filesController)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
    }
                                                             
    
    func changeRootViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let window = self.window else {
            return
        }
        
        // change the root view controller to your specific view controller
        window.rootViewController = vc
        
        // add animation
        UIView.transition(with: window,
                          duration: 0.5,
                          options: [.transitionCurlUp],
                          animations: nil,
                          completion: nil)
    }
    
}

