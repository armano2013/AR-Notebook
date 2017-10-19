//
//  insertViewController.swift
//  ARNotebook
//
//  Created by Artur Bushi on 10/15/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

protocol imageDelegate : class {
    func passImage (image :UIImage)
    
}
protocol textDelegate {
    func passingClip(string: String)
}

class insertViewController: UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UITextViewDelegate  {
    
    
    @IBOutlet weak var image: UIButton!
    @IBOutlet weak var text: UIButton!
    @IBOutlet weak var clipboard: UIButton!
    var delegate : imageDelegate?
    var delegate1 : textDelegate?
    var one : String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func image(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true)
        
        }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageOne = info[UIImagePickerControllerOriginalImage] as? UIImage{
             print("xcode sucks")
            delegate?.passImage(image: imageOne)
        }
        else{
                    print("xcode sucks")        }
        dismiss(animated: true, completion: nil)        
    }
    @IBAction func Text(_ sender: Any) {
        //
    }
    func getClipboard() -> String{
        let pasteboard: String? = UIPasteboard.general.string
        if let stringOne = pasteboard {
            
            return stringOne
            //update database here
            
        }
        return "No String Found on Clipboard"
    }
    @IBAction func clipboard(_ sender: Any) {
        one = getClipboard()
        delegate1?.passingClip(string: one)
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

