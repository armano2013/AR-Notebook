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
    var someNodes = [SCNNode]() //using this to store text nodes, remove later.
    var bookNode: SCNNode?
    var currentPageNode : SCNNode?
    @IBOutlet weak var menu: UIButton!
    var pages = [SCNNode]() //stores page nodes, can get page num from here
    
    
    //mock add pages //
    @IBAction func addPage(_ sender: Any) {
        if let bookNode = self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) {
            //gemoetry to figure out the size of the book placed //
            let pageNode = SCNNode(geometry: SCNBox(width: 1.4, height: 1.8, length:0.1, chamferRadius: 0.0))
            //@FIXME have fixed hieght for now bounding box isnt working
            
            if(pages.count % 2 == 0){
                 pageNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "page")
            }
            else{
                 pageNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            }
            pageNode.geometry?.firstMaterial?.isDoubleSided = true
            //issues with y position here, the page isnt placed right ontop of the book.
            let offset = Float(pages.count) * Float(0.1);
            pageNode.position = SCNVector3(bookNode.position.x, bookNode.position.y - offset, bookNode.position.z)
            pageNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
            pages.append(pageNode)
            currentPageNode = pageNode
            pageNode.name = String(pages.count)
            bookNode.addChildNode(pageNode)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerGestureRecognizers()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
    }
   
    func renderNode(node: SCNNode) {
        someNodes.append(node)
        self.sceneView.scene.rootNode.addChildNode(node)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //page turns
    @IBAction func rightSwipe(_ sender: Any) {
        //if there is more than one page and the current page node is the last one in the array turn the page backward?
        if (pages.count > 1 && Int((currentPageNode?.name)!)! >= 0) {
            print("right swipe loop")
            let previous = Int((currentPageNode?.name)!)! - 2
            let turnPage = pages[previous]
            turnPage.position = SCNVector3(0.01, 0.01, -0.01)
            currentPageNode = turnPage
            if let pageExists = self.sceneView.scene.rootNode.childNode(withName: "previousPage", recursively: false) {
                self.sceneView.scene.rootNode.replaceChildNode(pageExists, with:turnPage)
            }
            else{
                //if node with name previous page exists, replace it with the new one
                self.sceneView.scene.rootNode.addChildNode(turnPage)
            }
         
        }
    }
    
    @IBAction func leftSwipe(_ sender: Any) {
           //if there is more than one page and the current page node is the last one in the array turn the page forward
        if (pages.count > 1 && (Int((currentPageNode?.name)!)! <= Int(pages.count))) {
            print("left swipe loop")
            let previous = Int((currentPageNode?.name)!)! - 1
            let turnPage = pages[previous]
            turnPage.position = SCNVector3(0.01, 0.01, -0.01)
            currentPageNode = turnPage
            self.sceneView.scene.rootNode.addChildNode(turnPage)
        }
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
            self.addBook(hitTestResult: hitTest.first!)
        }
    }
    
    func addBook(hitTestResult: ARHitTestResult) {
        let scene = SCNScene(named: "art.scnassets/Book.dae")
        let node = (scene?.rootNode.childNode(withName: "Book_", recursively: false))!
        node.name = "Book"
        
        let coverMaterial = SCNMaterial()
        coverMaterial.diffuse.contents = UIImage(named: "BookCover(Ancient)_COLOR")
        coverMaterial.locksAmbientWithDiffuse = true
        node.geometry?.firstMaterial = coverMaterial
        //coordinates from the hit test give us the plane anchor to put the book ontop of, coordiantes are stored in the 3rd column.
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        someNodes.append(node);
        //check if another book object exists
        if self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) != nil {
            //this means theres already a book placed in the scene.. what do we want to do here??
            //user should only have one book open at a time.
        }
        else{
            self.sceneView.scene.rootNode.addChildNode(node)
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
      /*

     This section will show the 'focus square' when AR Kit detects a flat surface.
     This will help users know when the can click to set a notebook object
     
     */
    func createPlaneFocusSquare(planeAnchor: ARPlaneAnchor)->SCNNode{
        //.extent means the width and height of horizontal surface detected
        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height:CGFloat(planeAnchor.extent.z)))
        planeNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "focus")
        //since the page is being pasted on horizontal we need to make sure it is double sided so the top and bottom of the plane both have the content
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        planeNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        return planeNode
    }
    //add more page nodes on detecting of planes... Not useful for our application added as example.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes{(childNode, _) in
            childNode.removeFromParentNode()
        }
        let planeNode = createPlaneFocusSquare(planeAnchor: planeAnchor)
        node.addChildNode(planeNode)
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
