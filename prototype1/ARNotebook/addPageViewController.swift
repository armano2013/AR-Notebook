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
    func addPage(string : String)
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
     newPageController - Buttons
     -----
     */
    @IBAction func addTwoSlotPage(_ sender: Any) {
        print("two slot page add")
        selection = "two"
        delegate?.addPage(string: selection!)
    }
    @IBAction func addOneSlotPage(_ sender: Any) {
        print("one slot page add")
        selection = "one"
        delegate?.addPage(string: selection!)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}


