//
//  pageColorViewController.swift
//  ARNotebook
//
//  Created by Denise Green on 10/26/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import ARKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
class pageColorViewController: UIViewController {

    var ref: DatabaseReference! //calling a reference to the firebase database
    var storageRef: StorageReference! //calling a reference to the firebase storage
    
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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
