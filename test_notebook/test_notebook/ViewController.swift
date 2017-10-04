//
//  ViewController.swift
//  World Tracking
//
//  Created by Rayan Slim on 2017-08-20.
//  Copyright © 2017 Rayan Slim. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var userInputBox: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.session.run(configuration)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addFromClip(_ sender: Any) {
        let ourText = SCNText(string: getClipboard(), extrusionDepth: 1.0)
        let material = SCNMaterial()
        
        material.diffuse.contents = UIColor.red
        
        ourText.materials = [material]
        let node = SCNNode();
        node.geometry = ourText;
        node.scale = SCNVector3(x: 0.01, y:0.01, z:0.01)
        node.position = SCNVector3(0.01, 0.01, -0.01)
        
        sceneView.scene.rootNode.addChildNode(node)

    }
    func getClipboard() -> String{
        let pasteboard: String? = UIPasteboard.general.string
        if let string = pasteboard {
            return "hi the string is: \(string)"
        }
        return "else"
    }
    
    //gallery
    @IBAction func addImage(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let node = SCNNode()
            node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.001, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [pickedImage], duration: 0)
            node.position = SCNVector3(0.1,0.1,0.1)
            sceneView.scene.rootNode.addChildNode(node)
        }
        else{
            //
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func updateText(_ sender: Any) {
        let ourText = SCNText(string: userInputBox.text, extrusionDepth: 1.0)
        let material = SCNMaterial()
        
        material.diffuse.contents = UIColor.red
        
        ourText.materials = [material]
        let node = SCNNode();
        node.geometry = ourText;
        node.scale = SCNVector3(x: 0.01, y:0.01, z:0.01)
        node.position = SCNVector3(0.01, 0.01, -0.01)
        
        sceneView.scene.rootNode.addChildNode(node)

    }
    
}

