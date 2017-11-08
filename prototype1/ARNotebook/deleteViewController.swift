//
//  deleteViewController.swift
//  ARNotebook
//
//  Created by Megan Majewski on 10/26/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import ARKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
protocol deleteDelegate {
    func deletePage()
    func deleteNotebook()
    var currentProfile: String!  {get set}
    var currentPage: Int {get set}
    var notebookID : Int { get set }
}
class deleteViewController : UIViewController {
    /*
     -----
     Global Variables
     -----
     */
    var delegate : deleteDelegate?
    var ref: DatabaseReference! //calling a reference to the firebase database
    var storageRef: StorageReference! //calling a reference to the firebase storage
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
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     -----
     Delete View Controller - Buttons
     -----
     */
    @IBAction func deletePg(_ sender: Any) {
        print("delete Page")
        delegate?.deletePage()
    }
    @IBAction func deleteNotebook(_ sender: Any) {
        print("Delete Notebook")
        delegate?.deleteNotebook()
    }
    /*
     -----
    Database Function 
     -----
     */
}
