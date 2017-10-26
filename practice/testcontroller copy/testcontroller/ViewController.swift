//
//  ViewController.swift
//  testcontroller
//
//  Created by Denise Green on 10/17/17.
//  Copyright © 2017 Darion Thompson. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,UINavigationControllerDelegate, UIImagePickerControllerDelegate, finalDelegate{
    func finishPassing(image: UIImage) {
         print("data processed")
        imageView?.image = image
    }
    
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var imageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nextButton(_ sender: Any) {
        performSegue(withIdentifier: "nextView", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? secondViewController{
            destination.delegate = self
        }
       
    }
    @IBAction func myUnwindAction(unwindSegue:UIStoryboardSegue){
        //
    }
}
