//
//  ViewController.swift
//  example4PlzWork
//
//  Created by Mohammed Ali on 10/6/17.
//  Copyright © 2017 Mohammed Ali. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    var refName: DatabaseReference!

    @IBOutlet weak var textFieldPersonName: UITextField!
    
    @IBOutlet weak var resultLableField: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
   //     FirebaseApp.configure()
        
        refName = Database.database().reference().child("name")
    }
    @IBAction func addingButton(_ sender: Any) {
        addName()
    }
    
    func addName(){
        let key = refName.childByAutoId().key
        let name = ["id":key, "name": textFieldPersonName.text! as String]
        refName.child(key).setValue(name)
        resultLableField.text="Name Added"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

