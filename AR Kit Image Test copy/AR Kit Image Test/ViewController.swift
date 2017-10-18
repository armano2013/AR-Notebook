//
//  ViewController.swift
//  AR Kit Image Test
//
//  Created by Denise Green on 9/27/17.
//  Copyright © 2017 Darion Thompson. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate , FinalVCDelegate {
    func passImage(image: UIImage) {
        let node = SCNNode()
                node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.001, chamferRadius: 0)
                node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                sceneView.scene.rootNode.addChildNode(node)
        print("data passed")
    }
    
    

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()

    override func viewDidLoad() {
    
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.session.run(configuration)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    @IBAction func addImage(_ sender: Any) {
        let image = UIImagePickerController()
        
        image.delegate = self

        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
       
        image.allowsEditing = false

        self.present(image, animated: true)
    }
    @IBAction func Insert(_ sender: Any) {
        performSegue(withIdentifier: "insertView", sender: nil)
    }
    //    @IBAction func addRect(_ sender: Any) {
//        let image = UIImagePickerController()
//
//        image.delegate = self
//
//        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
//
//        image.allowsEditing = false
//
//        self.present(image, animated: true)
//        let node = SCNNode()
//        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.001, chamferRadius: 0)
//        node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
//        sceneView.scene.rootNode.addChildNode(node)
//
//    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? FinalVC{
            destination.delegate = self
        }
        
    }
    
    @IBAction func myUnwindAction(unwindSegue:UIStoryboardSegue){
        //
    }
    
    
}


