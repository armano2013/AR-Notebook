//
//  ViewController.swift
//  Gallery Choice
//
//  Created by Denise Green on 9/27/17.
//  Copyright © 2017 Darion Thompson. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,UINavigationControllerDelegate, UIImagePickerControllerDelegate{

    @IBOutlet weak var myImageView: UIImageView!
    
    @IBAction func ImportImage(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        image.allowsEditing = false
        
        self.present(image, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            myImageView.image = image
        }
        else{
            
            // error message
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

