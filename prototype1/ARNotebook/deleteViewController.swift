//
//  deleteViewController.swift
//  ARNotebook
//
//  Created by Megan Majewski on 10/26/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit

protocol deleteDelegate {
    func deletePage()
    func deleteNotebook()
}
class deleteViewController : UIViewController {
    /*
     -----
     Global Variables
     -----
     */
    var delegate : deleteDelegate?
    
    /*
     -----
     Generic Set Up
     -----
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
}
