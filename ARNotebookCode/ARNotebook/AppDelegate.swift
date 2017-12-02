//
//  AppDelegate.swift
//  ARNotebook
//
//  Created by AR Notebook on 10/15/17.
//  Copyright © 2017 AR Notebook. All rights reserved.
//


import UIKit
import Firebase
import FirebaseDatabase
import FacebookLogin
import FacebookCore
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var passedParams = [String]()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //the timer for the welcome splash screen
        Thread.sleep(forTimeInterval: 3.0)
        // Override point for customization after application launch.
        //FirebaseOptions.defaultOptions()?.deepLinkURLScheme = self.customURLScheme
        FirebaseApp.configure()
        Firebase.Database().isPersistenceEnabled = true
        
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return SDKApplicationDelegate.shared.application(app, open: url, options:options)
    }
    
    
    //This is called when a dynamic link into the app is recognized. We only need to support ios11+ so only need this  restorationHandler. Taken from Firebase Documentation
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let dynamicLinks = DynamicLinks.dynamicLinks() else {
            return false
        }
        let handled = dynamicLinks.handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
            if let dynamiclink = dynamiclink, let _ = dynamiclink.url {
                //pass the url to handle method
                self.handleIncomingLink(dynamiclink: dynamiclink)
            }
        }
        return handled
    }
    
    //This function handles the parsing of a URL that has been opened with the app
    func handleIncomingLink(dynamiclink: DynamicLink) {
        guard let pathComponents = dynamiclink.url?.pathComponents else {return}
        for nextPiece in pathComponents {
            //use firebase API method to break into path components, discard the first '/'
            //urls should have the notebook id and the read/ write access?? So 2 parameters expected
            if nextPiece != "/" {
                //save the 2 params in an array
                passedParams.append(nextPiece)
            }
        }
        if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "share") as? shareViewController {
            if let window = self.window, let rootViewController = window.rootViewController {
                var currentController = rootViewController
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                controller.setShareParams(arr: passedParams)
                currentController.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    //func application()
    
}



