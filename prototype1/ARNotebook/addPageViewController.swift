//
//  shareViewController.swift
//  ARNotebook
//
//  Created by Artur Bushi on 10/15/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit

protocol addPageDelegate {
    var currentPage: Int {get set}
    func addPage()
}

class addPageViewController: UIViewController {
    
    /*
     -----
     Global Variables
     -----
     */
    var delegate : addPageDelegate?
    
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
     newPageController - Buttons
     -----
     */
    @IBAction func addTwoSlotPage(_ sender: Any) {
        print("two slot page add")
        delegate?.addPage()
    }
    @IBAction func addOneSlotPage(_ sender: Any) {
        print("one slot page add")
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


