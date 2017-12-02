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


class AuthenticationViewController: UIViewController, profileNameDelegate, LoginButtonDelegate {
    
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
    
    
    var ref: DatabaseReference!
    var profileName : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 0.5)
        // Do any additional setup after loading the view.
        ref = Database.database().reference().child("users")
        self.addFBButton()
        self.instructions()
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
    
    func instructions(){
        let text = UILabel(frame: CGRect(x: view.frame.minX + 100, y: view.frame.minY + 100, width: view.frame.maxX - 200, height: view.frame.height/1.33))
        text.numberOfLines = 0
        text.textAlignment = .center
        let device = UIScreen.main.traitCollection.userInterfaceIdiom
        switch device {
        case .pad:
            text.font = UIFont(name: "Helvetica", size: 24)
        case .phone:
            text.font = UIFont(name: "Helvetica", size: 17)
        default:
            break
        }
        
        //text.backgroundColor = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 0.5)
        text.textColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
        text.text = "Hello, Welcome to AR Notebook! \n\nIn order to use this application, you must first log in through Facebook. After you log in, you will see that only one button is clickable. To place down a notebook, you must first position your camera towards a flat surface until an orange square appears. You can then tap anywhere in that square to place down a notebook. Due to ARKit limitations, you are currently not allowed to postion the orientation of the notebook towards yourself. \n\nAfter you tap a notebook, you will see that many buttons become activated. You can then tap and hold down any of the buttons for a short amount of time and then release. You will see that a message showing what that button does will pop up. \n\nNOTE: The ability to find a valid square for your notebook to be placed at depends on your lighting and surface conditions. \n\nClick the login button down below and enjoy!"
        view.addSubview(text)
    }
    
    func addFBButton(){
        let customButton = UIButton(type: .custom)
        customButton.frame = CGRect(x: view.frame.width/4, y: view.frame.maxY - 100, width: view.frame.width/2, height: 35)
        customButton.layer.cornerRadius = 5
        customButton.setTitle("Login to AR Notebook with Facebook", for: .normal)
        customButton.backgroundColor = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 0.5)
        customButton.tintColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 0.5)
        customButton.addTarget(self, action: #selector(customFBButtonTapped), for: .touchUpInside)
        view.addSubview(customButton)
    }
    
    @objc func customFBButtonTapped(){
        let manager = LoginManager()
        manager.logIn(readPermissions: [.publicProfile], viewController: self) { (result) in
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
                    let IDs = ["ID":self.profileName]
                    self.ref.updateChildValues(IDs as Any as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                        if  err != nil{
                            print(err as Any)
                            return
                        }
                    })
                })
                self.performSegue(withIdentifier: "loginSegue", sender: self)
            default:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as?  ViewController {
            destination.nameDelegate = self
        }
    }
}

