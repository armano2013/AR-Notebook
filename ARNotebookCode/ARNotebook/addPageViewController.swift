//
//  shareViewController.swift
//  ARNotebook
//
//  Created by AR Notebook on 10/15/17.
//  Copyright © 2017 AR Notebook. All rights reserved.
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
    var notebookID: Int {get set}
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
        if (delegate?.accessToWrite)!{
            let string = "double"
            //add to database even if empty
            savePage()
            self.delegate?.addPage(text : string)
        }
        else{
            alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
        }
    }
    @IBAction func addOneSlotPage(_ sender: Any) {
        if (delegate?.accessToWrite)! {
            let string = "single"
            savePage()
            self.delegate?.addPage(text : string)
        }
        else{
            alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
    func savePage(){
        //because save page gets called before the page count in incremented we need to do it now
        let pageID = (self.delegate?.currentPage)! + 1
        self.ref.child("notebooks/\((self.delegate?.notebookID)!)/\(pageID)").setValue(["empty": "true"])
        self.ref.child("notebooks/\((self.delegate?.notebookID)!)/\(pageID)").setValue(["color": "default"])
    }
}


