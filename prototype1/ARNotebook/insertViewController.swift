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

class insertViewController: UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UITextViewDelegate  {
    
    let VC1 = ViewController()
    
    @IBOutlet weak var image: UIButton!
    @IBOutlet weak var text: UIButton!
    @IBOutlet weak var clipboard: UIButton!
    
    let imagePicker = UIImagePickerController()
    var someNodes = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
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
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            //send picked image to the database
            let node = SCNNode()
            node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.001, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [pickedImage], duration: 0)
            node.position = SCNVector3(0.1,0.1,0.1)
            VC1.sceneView.scene.rootNode.addChildNode(node)
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

