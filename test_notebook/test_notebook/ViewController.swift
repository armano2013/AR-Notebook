//
//  ViewController.swift
//  World Tracking
//
//  Created by Rayan Slim on 2017-08-20.
//  Copyright © 2017 Rayan Slim. All rights reserved.
//

import UIKit
import ARKit
import Firebase

class ViewController: UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    let imagePicker = UIImagePickerController()
    var someNodes = [SCNNode]()
    @IBOutlet weak var userInputBox: UITextField!
    //Swipe detectors
    @IBAction func leftSwipe(_ sender: UISwipeGestureRecognizer) {
        let text = SCNText(string: "left swipe", extrusionDepth: 1.0);
        let node = createTextNode(text: text)
        node.name = "left"
        if let testNode = self.sceneView.scene.rootNode.childNode(withName: "right", recursively: true) {
            self.sceneView.scene.rootNode.replaceChildNode(testNode, with:node)
        }
        renderNode(node: node)
    }
    
    @IBAction func rightSwipe(_ sender: UISwipeGestureRecognizer) {
        let text = SCNText(string: "right swipe", extrusionDepth: 1.0);
        let node = createTextNode(text: text)
        node.name = "right"
        if let testNode = self.sceneView.scene.rootNode.childNode(withName: "left", recursively: true) {
         self.sceneView.scene.rootNode.replaceChildNode(testNode, with:node)
        }
        renderNode(node: node)
        
    }
    
    //default did load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    func renderNode(node: SCNNode) {
        someNodes.append(node)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    @IBAction func addFromClip(_ sender: Any) {
        let ourText = SCNText(string: getClipboard(), extrusionDepth: 1.0)
        renderNode(node: createTextNode(text: ourText))
    }
    func getClipboard() -> String{
        let pasteboard: String? = UIPasteboard.general.string
        if let string = pasteboard {
            return string
            //update database here
        }
        return "No String Found on Clipboard"
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
            //send picked image to the database
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
    //keyboard
    
    @IBAction func updateText(_ sender: Any) {
        let keyText = SCNText(string: userInputBox.text, extrusionDepth: 1.0)
        let node = createTextNode(text: keyText)
        renderNode(node: node)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateText(self)
        textField.resignFirstResponder()
        return true
    }
    func createPage(planeAnchor: ARPlaneAnchor)->SCNNode{
        //.extent means the width and height of horizontal surface detected
        let pageNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height:CGFloat(planeAnchor.extent.z)))
        pageNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "page")
//since the page is being pasted on horizontal we need to make sure it is double sided so the top and bottom of the plane both have the content
        pageNode.geometry?.firstMaterial?.isDoubleSided = true
        pageNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        pageNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        return pageNode
    }
    
    //arscnview deleagete for when a new horz surface is detected
    //didadd can tell you the plane size -- but probably not needed for our project since books will be predefined
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //if a surface is detected will return plane anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let pageNode = createPage(planeAnchor: planeAnchor);
        node.addChildNode(pageNode)
    }
    //add more page nodes on detecting of planes... Not useful for our application added as example.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes{(childNode, _) in
            childNode.removeFromParentNode()
        }
        let pageNode = createPage(planeAnchor: planeAnchor)
        node.addChildNode(pageNode)
    }
    
    //didRemove runs when a feature point is removed - in this case check to see if the feature point removed was a plane note
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes{(childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
}

//converts degrees to radians, since objects are oriented according to radians
//credit to udemy video
extension Int {
    var degreesToRadians: Double {return Double(self) * .pi/180}
}
