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

class ViewController:  UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate {
    
    /*
     -----
     Global Variables
     -----
     */
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var someNodes = [SCNNode]() //using this to store text nodes, remove later.
    var bookNode: SCNNode?
    let imagePicker = UIImagePickerController()
    var currentPageNode : SCNNode? //points to the current page, assigned in page turns
    
    /*
     -----
     Generic Session Setup
     -----
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Create a session configuration
         self.registerGestureRecognizers()
         self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
         // Run the view's session
        self.configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        self.sceneView.delegate = self
    }
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    /*
     -----
     Main Story - View Controller Buttons
     -----
     */
    
    @IBAction func updateText(_ sender: Any) {
        
    }
    
    @IBAction func undo(_ sender: Any) {
    
    }
    
    var pages = [SCNNode]() //stores page nodes, can get page num from here
    func createTextNode(text: SCNText) -> SCNNode {
        let material = SCNMaterial()
        
        material.diffuse.contents = UIColor.red
        text.materials = [material]
        let node = SCNNode();
        node.geometry = text
        node.scale = SCNVector3(x: 0.01, y:0.01, z:0.01)
        node.position = SCNVector3(0.01, 0.01, -0.01)
        return node;
    }

    @IBAction func addText(_ sender: Any) {
        let page = currentPageNode
        let text = SCNText(string: getClipboard(), extrusionDepth: 0.1)
        

        text.isWrapped = true
        let material = SCNMaterial()
        if(pages.count % 2 == 0){
            material.diffuse.contents = UIColor.black
        }
        else {
            material.diffuse.contents = UIColor.blue
        }
        text.materials = [material]
        let node = SCNNode()
        node.geometry = text
        node.scale = SCNVector3Make(0.01, 0.01, 0.01)
        node.position = SCNVector3(-0.7, 0.0, 0.05)
        page?.addChildNode(node)
        
        /*
         
         Trying to contain the text to the page
         ------
         
         credit: https://stackoverflow.com/questions/44828764/arkit-placing-an-scntext-at-a-particular-point-in-front-of-the-camera
         let (min, max) = node.boundingBox
              //  text.containerFrame = CGRect(origin: .zero, size: CGSize(width: 1.4, height: 1.8))
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        */
        
        //node.eulerAngles = SCNVector3(0, 180.degreesToRadians, 0) //for some reason text is added backward
    }

    @IBAction func chooseIMG(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let page = currentPageNode
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            //send picked image to the database
            let node = SCNNode()
            node.geometry = SCNBox(width: 1.4, height: 1.8, length: 0.001, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [pickedImage], duration: 0)
            node.position = SCNVector3(-0.7,0.0, 0.05)
            page?.addChildNode(node)
        }
        else{
            //
        }
        dismiss(animated: true, completion: nil)
    }
    func getClipboard() -> String{
        let pasteboard: String? = UIPasteboard.general.string
        if let string = pasteboard {
            return string
            //update database here
        }
        return "No String Found on Clipboard"
    }
    /*
     -----
     Add Pages
     -----
     */
    @IBAction func addPage(_ sender: Any) {
        if let bookNode = self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) {
            //gemoetry to figure out the size of the book placed //
            let pageNode = SCNNode(geometry: SCNBox(width: 1.4, height: 1.8, length:0.001, chamferRadius: 0.0))
            //@FIXME have fixed hieght for now bounding box isnt working
            
            if(pages.count % 2 == 0){
                 pageNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "page")
            }
            else{
                 pageNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            }
            pageNode.geometry?.firstMaterial?.isDoubleSided = true
            //issues with y position here, the page isnt placed right ontop of the book.
            let offset = Float(pages.count) * Float(0.01);
            //@DISCUSS should we add pages from the top or bottom?? if bottom needs to fix paging.
            pageNode.position = SCNVector3(bookNode.position.x, bookNode.position.y - offset, bookNode.position.z)
            pageNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
            pages.append(pageNode)
            pageNode.name = String(pages.count - 1) //minus one so 0 index array
            currentPageNode = pageNode
            bookNode.addChildNode(pageNode)
        }
    }
  
    //page turns
    @IBAction func rightSwipe(_ sender: Any) {
        //if there is more than one page and the current page node is the last one in the array turn the page backward?
        if (pages.count > 1 && Int((currentPageNode?.name)!)! > 0) {
                let i = Int((currentPageNode?.name)!)
                let previous = i! - 1;
                let turnPage = pages[previous]
                currentPageNode?.isHidden = true;
                currentPageNode = turnPage
        }
    }
    
    @IBAction func leftSwipe(_ sender: Any) {
           //if there is more than one page and the current page node is the last one in the array turn the page forward
        if (pages.count > 1 && ((Int((currentPageNode?.name)!)!) < Int(pages.count - 1))) {
            let i = Int((currentPageNode?.name)!)
            let previous = i! + 1;
            let turnPage = pages[previous]
            turnPage.isHidden = false
            currentPageNode = turnPage
        }
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

    func passImage(image: UIImage) {
        //let page = currentPageNode
        let node = SCNNode(geometry: SCNBox(width: 1.4, height: 1.8, length:0.001, chamferRadius: 0.0))
        node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
        node.position = SCNVector3(-0.7, 0.0, 0.05)
        self.sceneView.scene.rootNode.addChildNode(node)
        
    }
    
    func passingClip(string: String) {
        let page = currentPageNode
        let text = SCNText(string: string, extrusionDepth: 0.1)
        
        //  text.containerFrame = CGRect(origin: .zero, size: CGSize(width: 1.4, height: 1.8))
        text.isWrapped = true
        let material = SCNMaterial()
        if(pages.count % 2 == 0){
            material.diffuse.contents = UIColor.black
        }
        else {
            material.diffuse.contents = UIColor.blue
        }
        text.materials = [material]
        let node = SCNNode()
        node.geometry = text
        node.scale = SCNVector3Make(0.01, 0.01, 0.01)
        
        /* credit: https://stackoverflow.com/questions/44828764/arkit-placing-an-scntext-at-a-particular-point-in-front-of-the-camera
         let (min, max) = node.boundingBox
         
         let dx = min.x + 0.5 * (max.x - min.x)
         let dy = min.y + 0.5 * (max.y - min.y)
         let dz = min.z + 0.5 * (max.z - min.z)
         node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
         */
        node.position = SCNVector3(-0.7, 0.0, 0.05)
        //node.eulerAngles = SCNVector3(0, 180.degreesToRadians, 0) //for some reason text is added backward
        page?.addChildNode(node)
        print("clipboard string recieved")
    }
}

//converts degrees to radians, since objects are oriented according to radians
//credit to udemy video
extension Int {
    var degreesToRadians: Double {return Double(self) * .pi/180}
}



