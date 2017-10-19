//
//  Final.swift
//  passBackText
//
//  Created by Denise Green on 10/18/17.
//  Copyright © 2017 Darion Thompson. All rights reserved.
//

import UIKit

protocol finalDelegate {
    func finishPassing (string :String )
}

class Final: UIViewController {
    
    @IBOutlet weak var passData: UIButton!
    
    var delegate : finalDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dataPassed(_ sender: Any) {
        delegate?.finishPassing(string: "string recieved")
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
