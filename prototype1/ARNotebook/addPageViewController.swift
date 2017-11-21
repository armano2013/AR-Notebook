//
//  shareViewController.swift
//  ARNotebook
//
//  Created by Artur Bushi on 10/15/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import ARKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol addPageDelegate {
    var currentPage: Int {get set}
    func addPage(text : String)
    var accessToWrite: Bool {get set}
}

class addPageViewController: UIViewController {
    
    /*
     -----
     Global Variables
     -----
     */
    var ref: DatabaseReference! //calling a reference to the firebase database
    var storageRef: StorageReference! //calling a reference to the firebase storage
    var delegate : addPageDelegate?
    var selection : String?
    var alert = alertHelper()
    
    /*
     -----
     Generic Set Up
     -----
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()
        // Do any additional setup after loading the view.
    }
    
    /*
     -----
     newPageController - Buttons
     -----
     */
    @IBAction func addTwoSlotPage(_ sender: Any) {
        if (delegate?.accessToWrite)! {
            let string = "double"
            delegate?.addPage(text : string)
        }
        else{
            self.dismiss(animated: true, completion: nil)
            alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
        }
    }
    @IBAction func addOneSlotPage(_ sender: Any) {
        if (delegate?.accessToWrite)! {
            let string = "single"
            delegate?.addPage(text : string)
        }
        else{
            self.dismiss(animated: true, completion: nil)
            alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
    
}


