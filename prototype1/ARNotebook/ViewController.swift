//
//  ViewController.swift
//  ARNotebook
//
//  Created by Artur Bushi on 10/15/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import ARKit
import FirebaseAuth

class ViewController: UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UITextViewDelegate {

    
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    let imagePicker = UIImagePickerController()
    var someNodes = [SCNNode]()
    
    var bookNode: SCNNode?
    
    @IBOutlet weak var menu: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.registerGestureRecognizers()
        // Do any additional setup after loading the view, typically from a nib.
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self

        sceneView.showsStatistics = true
     
    }
/*
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first
            else {return}
        
        let results = sceneView.hitTest(touch.location(in: sceneView),
                                        types: [ARHitTestResult.ResultType.featurePoint])
        
        guard let hitFeature = results.last else {return}
        
        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        let bookClone = bookNode!.clone()
        sceneView.scene.rootNode.addChildNode(bookClone)
    }
    */
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
    
    func getClipboard() -> String{
        let pasteboard: String? = UIPasteboard.general.string
        if let string = pasteboard {
            return string
            //update database here
        }
        return "No String Found on Clipboard"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func registerGestureRecognizers() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
         self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
   
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            self.addItem(hitTestResult: hitTest.first!)
        }
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
            let scene = SCNScene(named: "art.scnassets/Book.dae")
            let node = (scene?.rootNode.childNode(withName: "Book_", recursively: false))!
            let transform = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            self.sceneView.scene.rootNode.addChildNode(node)
    }
    /*func createPage(planeAnchor: ARPlaneAnchor)->SCNNode{
        //.extent means the width and height of horizontal surface detected
        let pageNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height:CGFloat(planeAnchor.extent.z)))
        pageNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "page")
        //since the page is being pasted on horizontal we need to make sure it is double sided so the top and bottom of the plane both have the content
        pageNode.geometry?.firstMaterial?.isDoubleSided = true
        pageNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        pageNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        return pageNode
    }*/
    
    //arscnview deleagete for when a new horz surface is detected
    //didadd can tell you the plane size -- but probably not needed for our project since books will be predefined
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //if a surface is detected will return plane anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        print("plane")
        /*
        let bookScene = SCNScene(named: "art.scnassets/Book.dae")!
        let bookNode = bookScene.rootNode.childNode(withName: "Book_", recursively: false)!
        bookNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        bookNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        bookNode.geometry?.firstMaterial?.isDoubleSided = true
        self.sceneView.scene.rootNode.addChildNode(bookNode)*/
        
    }
    
    /*add more page nodes on detecting of planes... Not useful for our application added as example.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes{(childNode, _) in
            childNode.removeFromParentNode()
        }
        let pageNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height:CGFloat(planeAnchor.extent.z)))
        node.addChildNode(pageNode)
    }*/
    
    //didRemove runs when a feature point is removed - in this case check to see if the feature point removed was a plane note
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes{(childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
}

//converts degrees to radians, since objects are oriented according to radians
//credit to udemy video
extension Int {
    var degreesToRadians: Double {return Double(self) * .pi/180}
}
