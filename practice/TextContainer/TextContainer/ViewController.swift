//
//  ViewController.swift
//  TextContainer
//
//  Created by Denise Green on 11/3/17.
//  Copyright © 2017 Darion Thompson. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSCNViewDelegate  {

    @IBOutlet weak var text: UIButton!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var node: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.session.run(configuration)
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func createText(_ sender: Any) {
        let textNode = SCNText(string: "Hello Megan My name Is Darion And I got the Container frame to Work :P", extrusionDepth: 0.1)
        textNode.font = UIFont(name: "Arial", size:1)
    textNode.containerFrame = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))
    textNode.truncationMode = kCATruncationEnd
    textNode.alignmentMode = kCAAlignmentLeft
    textNode.isWrapped = true
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.red
    textNode.materials = [material]
        let newNode = SCNNode()
     newNode.geometry = textNode
     newNode.scale = SCNVector3(x: 0.05, y:0.05, z:0.05)
     newNode.position = SCNVector3(0, 0, 0)
        node = newNode
        sceneView.scene.rootNode.addChildNode( newNode)
    
}
    
    @IBAction func deleteNode(_ sender: Any) {
        //sceneView.scene.rootNode.removeFromParentNode()
        node?.removeFromParentNode()
    }
    
}
