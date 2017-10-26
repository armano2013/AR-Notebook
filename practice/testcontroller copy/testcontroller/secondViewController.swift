//
//  secondViewController.swift
//  testcontroller
//
//  Created by Denise Green on 10/17/17.
//  Copyright © 2017 Darion Thompson. All rights reserved.
//

import UIKit
protocol finalDelegate {
    func finishPassing (image :UIImage)
}

class secondViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var insert: UIButton!
    weak var newImage : UIImageView?
    var delegate : finalDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    @IBAction func insert(_ sender: Any) {
        
        let image = UIImagePickerController()
        image.delegate = self
        
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        image.allowsEditing = false
        
        self.present(image, animated: true)
        
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageOne = info[UIImagePickerControllerOriginalImage] as? UIImage{
            delegate?.finishPassing(image: imageOne)
        }
        else{
            
            // error message
        }
        
        
    }
   
    
    
}
