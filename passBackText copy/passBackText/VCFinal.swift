//
//  ViewController.swift
//  passBackText
//
//  Created by Denise Green on 10/18/17.
//  Copyright © 2017 Darion Thompson. All rights reserved.
//

import UIKit

class VCFinal: UIViewController, finalDelegate {
@IBOutlet weak var buttonPressed: UIButton!
    
    @IBOutlet weak var text: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        performSegue(withIdentifier: "VCtoFinal", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? Final{
            destination.delegate = self
        }
    }
    func finishPassing(string: String) {
        print("data processed")
        print(string)
        text.text = string
    }
     @IBAction func myUnwindAction(unwindSegue:UIStoryboardSegue){
        //
    }

}

