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

class insertViewController: UIViewController, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UITextViewDelegate  {
    
    
    @IBOutlet weak var image: UIButton!
    @IBOutlet weak var text: UIButton!
    @IBOutlet weak var clipboard: UIButton!
    
    var VC1 = ViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    let imagePicker = UIImagePickerController()

    @IBAction func image(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true)
        }
    
    @IBAction func Text(_ sender: Any) {
        //
    }
    @IBAction func clipboard(_ sender: Any) {
        let ourText = SCNText(string: getClipboard(), extrusionDepth: 1.0)
        let node = createTextNode(text: ourText)

        self.presentingViewController?.dismiss(animated: true, completion: {self.VC1.renderNode(node: node)})
    }
    
    func createTextNode(text: SCNText) -> SCNNode {
        let material = SCNMaterial()
        
        material.diffuse.contents = UIColor.red
        
        text.materials = [material]
        let node = SCNNode();
        node.geometry = text;
        node.scale = SCNVector3(x: 0.01, y:0.01, z:0.01)
        node.position = SCNVector3(0.01, 0.01, -0.01)
        
        return node;
    }
    func getClipboard() -> String{
        let pasteboard: String? = UIPasteboard.general.string
        if let string = pasteboard {
            return string
            //update database here
        }
        return "No String Found on Clipboard"
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            //send picked image to the database
            let node = SCNNode()
            node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.001, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [pickedImage], duration: 0)
            VC1.renderNode(node: node)
            
        }
        else{
            //
        }
        dismiss(animated: true, completion: nil)
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

