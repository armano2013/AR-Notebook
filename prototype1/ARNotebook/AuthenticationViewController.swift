//
//  AuthenticationViewController.swift
//  ARNotebook
//
//  Created by Artur Bushi on 10/15/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import FacebookLogin
import FirebaseAuth
import FacebookCore
import FirebaseDatabase


class AuthenticationViewController: UIViewController, LoginButtonDelegate, profileNameDelegate {
    
    var ref: DatabaseReference!
    var profileName : String!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let FBLogin = LoginButton(readPermissions: [.publicProfile])
        FBLogin.center = view.center
        view.addSubview(FBLogin)
        FBLogin.delegate = self as LoginButtonDelegate
        ref = Database.database().reference().child("users")
    }
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            self.profileName = (Auth.auth().currentUser?.uid)!
            performSegue(withIdentifier: "loginSegue", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        switch result {
        case .success:
            
            let accessToken = AccessToken.current
            guard let accessTokenString = accessToken?.authenticationToken else { return }
            let credential = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                if error != nil {
                    print("error: \(describing: error?.localizedDescription)")
                    return
                }
                //let names = ["name":user?.displayName] old version
                let IDs = ["ID":self.profileName]
                self.ref.updateChildValues(IDs as Any as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                    if  err != nil{
                        print(err as Any)
                        return
                    }
                })
                
            })
            
            performSegue(withIdentifier: "loginSegue", sender: self)
        default:
            break
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        
    }
    
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as?  ViewController {
            destination.nameDelegate = self
        }
    
    }
}

