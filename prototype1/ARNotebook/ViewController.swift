//
//  ViewController.swift
//  ARNotebook
//
//  Created by Artur Bushi on 10/15/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import ARKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FacebookLogin
import FacebookCore

protocol profileNameDelegate {
    var profileName : String! {get set}
}


class ViewController:  UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, insertDelegate, addPageDelegate, deleteDelegate, pageColorDelegate, retrieveDelegate {
    
    
    
    
    /*
     -----
     Global Variables
     -----
     */
    
    var maxScale: CGFloat = 0
    var minScale: CGFloat = 5
    
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var hitResult : ARHitTestResult? = nil
    var offset = Float(0.025);
    var notebookName = "Untitled"
    var bookNode: SCNNode?
    var currentPageNode : SCNNode? //points to the current page, assigned in page turns
    var lastNode = [SCNNode]() //used to for undo function to delete the last input node
    var pages = [SCNNode]() //stores page nodes, can get page num from here
    var currentPage : Int = 1 // global variable to keep track of current page number
    var pageColor : UIImage? // global variable to keep track of the page color when the user changes it
    var nameDelegate : profileNameDelegate? // calling the delegate to the AuthViewCont to get user's profile name
    var currentProfile : String!
    var ref: DatabaseReference! //calling a reference to the firebase database
    var storageRef: StorageReference! //calling a reference to the firebase storage
    var notebookID: Int = 0 //unique id of notebook
    var pageContentInfo : String = ""    
    var currentPageColor: String = ""
    var template : String = ""
    var topTempNode : SCNNode?
    var bottomTempNode : SCNNode?
    var templateNode : SCNNode?
    var currentTemplateNode : SCNNode?
    var currentTemplate : Int = 1
    var topTempNodeContent :String = ""
    var bottomTempNodeContent :String = ""
    var planetimeout : Timer?
    var notebookExists : Bool = false
    var retrievedFlag : Bool = false
    /*
     -----
     Generic Session Setup
     -----
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()
        
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
        self.registerGestureRecognizers()
        /// Create a session configuration
        self.registerGestureRecognizers()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        // Run the view's session
        self.configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        self.sceneView.delegate = self
        currentProfile = nameDelegate?.profileName
        self.sceneView.autoenablesDefaultLighting = true
        
        addTimer()

    }
    
    func addTimer(){
        planetimeout = Timer.scheduledTimer(withTimeInterval: 40.0, repeats: false, block: { (_) in
            let alertController = UIAlertController(title: "Invalid Horizontal Plane", message: "Please find a flat surface to place your notebook onto.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    
    //@objc becuse selector is an object c
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        
        if sender.state == .began{
            
        }else if sender.state == .ended{
            //stops all actions once user removes finger
            
        }
        let scale: CGFloat = sender.scale
        if scale > 1 {
            maxScale += scale
            //scale = 1
        }
        else if scale < 1 {
            minScale -= scale
        }
        
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        
        if !hitTest.isEmpty {
            
            let results = hitTest.first!
            _ = results.boneNode
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 1)
            print(sender.scale)
            
            topTempNode?.runAction(pinchAction)
            bottomTempNode?.runAction(pinchAction)
            currentPageNode?.runAction(pinchAction)
            sender.scale = 1.0
        }
    }
    
    /*
     -----
     Main Story - View Controller Buttons
     -----
     */
    
    @IBAction func undo(_ sender: Any) {
        if template == "single" {
            if let last = (lastNode.last){
                last.removeFromParentNode()
                lastNode.removeLast()
            }
        }
        else if template == "double"{
            if topTempNodeContent == "full"{
                if let last = (lastNode.last){
                    last.removeFromParentNode()
                    lastNode.removeLast()
                    topTempNodeContent = "empty"
                }
            }
            else if bottomTempNodeContent == "full"{
                if let last = (lastNode.last){
                    last.removeFromParentNode()
                    lastNode.removeLast()
                    bottomTempNodeContent = "empty"
                }
            }
        }
        else {
            let alertController = UIAlertController(title: "Nothing to Undo", message: "There is nothing you are able to undo", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // limit the text characters to be less than 140
    /* func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
     let startingLength = UserInputText.text?.characters.count ?? 0
     let lengthToAdd = string.characters.count
     let lengthToReplace = range.length
     
     let newLength = startingLength + lengthToAdd - lengthToReplace
     
     return newLength <= 140
     }*/
    /*
     -----
     Render SCNNodes for Text and Image
     -----
     */
    
    func createTextNode(text: SCNText) -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        text.materials = [material]
        let node = SCNNode();
        node.geometry = text
        node.scale = SCNVector3(x: 0.1, y:0.1, z:0.1)
        node.position = SCNVector3(-0.5, 0.0, 0.001)
        return node;
    }
    func renderNode(node: SCNNode) {
        if let page = currentPageNode {
            if template == "single"{
                let temp = currentTemplateNode
                lastNode.append(node)
                temp?.addChildNode(node)
            }
            else if template == "double"{
                
                if topTempNodeContent == "empty" && bottomTempNodeContent == "empty"{
                    lastNode.append(node)
                    topTempNode?.addChildNode(node)
                    print("Top full")
                    topTempNodeContent = "full"
                }
                else if topTempNodeContent == "full" && bottomTempNodeContent == "empty"{
                    lastNode.append(node)
                    bottomTempNode?.addChildNode(node)
                    bottomTempNodeContent = "full"
                    print("bottom full")
                }
                else if topTempNodeContent == "full" && bottomTempNodeContent == "full"{
                    print("both are full")
                    let alertController = UIAlertController(title: "Error", message: "both templates are full", preferredStyle: UIAlertControllerStyle.alert)
                    let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel){ (result : UIAlertAction) -> Void in
                    }
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
            
        else {
            dismiss(animated: true, completion: nil)
            let alertController = UIAlertController(title: "Error", message: "Please add a page before adding any text", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            let addPageAction = UIAlertAction(title: "Add Page", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                //self.addPage(self)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(addPageAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func createPage(){
        if let bookNode = self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true)  {
            let pageNode = SCNNode(geometry: SCNBox(width: 1.4, height: 1.8, length:0.001, chamferRadius: 0.0))
            //@FIXME have fixed hieght for now bounding box isnt working
            
            pageNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "page")
            
            pageNode.geometry?.firstMaterial?.isDoubleSided = true
            //@FIXME issues with y position here, the page isnt placed right ontop of the book
            
            
            if(pages.count != 0){
                offset = offset + Float(0.02);
            }
            
            
            //coordinates from the hit test give us the plane anchor to put the book ontop of, coordiantes are stored in the 3rd column.
            let transform = hitResult?.localTransform
            guard let thirdColumn = transform?.columns.3 else{return}
            
            //let thirdColumn = transform?.columns.3
            pageNode.position = SCNVector3(thirdColumn.x, thirdColumn.y + offset, thirdColumn.z)
            
            // pageNode.position = SCNVector3(bookNode.position.x, 0.05 + offset, bookNode.position.z)
            pageNode.eulerAngles = SCNVector3(-90.degreesToRadians, 0, 0)
            pages.append(pageNode)
            pageNode.name = String(pages.count) //minus one so 0 index array  why??
            currentPageNode = pageNode
            bookNode.addChildNode(pageNode)
            currentPage = Int((currentPageNode?.name)!)!
            topTempNodeContent = "empty"
            bottomTempNodeContent = "empty"
            addPageNum()
        }
        else{//book error
            let alertController = UIAlertController(title: "Error", message: "Please add a notebook or page before adding text", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    func addPageNum () {
        if let pageNumberNode = currentPageNode{
            let node = SCNText(string: String(self.currentPage), extrusionDepth: 0.1)
            node.isWrapped = true
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.black
            node.materials = [material]
            let pageNode = createTextNode(text: node)
            pageNode.scale = SCNVector3(x: 0.006, y: 0.006, z: 0.006)
            pageNode.position = SCNVector3(0.55, -0.888, 0.001)
            pageNumberNode.addChildNode(pageNode)
        }
    }
    /*
     -----
     Tap Interactions
     -----
     */
    @IBAction func rightSwipe(_ sender: Any) {
        //if there is more than one page and the current page node is the last one in the array turn the page backward?
        if (pages.count > 0 && currentPage > 1) {
            let i = Int((currentPageNode?.name)!)
            let previous = i! - 2;
            let turnPage = pages[previous]
            // Point in the -z direction
            //the first varible has to be 360 or 180 to play place
            turnPage.pivot = SCNMatrix4MakeRotation(Float(360.degreesToRadians), 0, 1, 0)
            
            let spin = CABasicAnimation(keyPath: "rotation")
            //// Use from-to to explicitly make a full rotation around z
            spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 1, w: 0))
            spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: -1, z: -0.001, w: .pi))
            spin.duration = 0.5
            spin.repeatCount = 0
            turnPage.addAnimation(spin, forKey: "spin around")
            
            currentPageNode?.isHidden = true;
            currentPageNode = turnPage
            currentPage = Int((currentPageNode?.name)!)!
        }
    }
    @IBAction func leftSwipe(_ sender: Any) {
        //if there is more than one page and the current page node is the last one in the array turn the page forward
        if (pages.count > 1 && (currentPage <= Int(pages.count - 1))) {
            let i = Int((currentPageNode?.name)!)
            let previous = i!;
            let turnPage = pages[previous]
            
            // Point in the -z direction
            turnPage.pivot = SCNMatrix4MakeRotation( 0, Float(360.degreesToRadians), 0, 0)
            
            let spin = CABasicAnimation(keyPath: "rotation")
            //// Use from-to to explicitly make a full rotation around z
            spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: -1, z: -0.001, w: 0))
            spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 1, w: .pi))
            spin.duration = 0.5
            spin.repeatCount = 1
            turnPage.addAnimation(spin, forKey: "spin around")
            
            turnPage.isHidden = false
            currentPageNode = turnPage
            currentPage = Int((currentPageNode?.name)!)!
        }
    }
    
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        print(retrievedFlag)
        if retrievedFlag == true {
            self.addRetrievedBook(hitTestResult: hitTest.first!)
        }
        else if !hitTest.isEmpty {
            self.addBook(hitTestResult: hitTest.first!)
        }
    }
    
    func addBook(hitTestResult: ARHitTestResult) {
        
        let scene = SCNScene(named: "art.scnassets/Book.dae")
        let node = (scene?.rootNode.childNode(withName: "Book_", recursively: false))!
        node.name = "Book"
        
        let coverMaterial = SCNMaterial()
        coverMaterial.diffuse.contents = UIImage(named: "purpleRain")
        coverMaterial.locksAmbientWithDiffuse = true
        node.geometry?.firstMaterial = coverMaterial
        ref.child("notebooks/\(notebookID)").updateChildValues(["CoverStyle" : "purple"])
        
        //for adding pages ontop
        hitResult = hitTestResult
        //coordinates from the hit test give us the plane anchor to put the book ontop of, coordiantes are stored in the 3rd column.
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        bookNode = node //assign the book node to the global variable for book node
        
        //check if another book object exists
        if self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) != nil {
            let alertController = UIAlertController(title: "Error", message: "You can only place one book at a time.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel){ (result : UIAlertAction) -> Void in
            }
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            //give the user an option to name the notebook
            let alertController = UIAlertController(title: "Notebook Name", message: "Enter a name to create your new notebook.", preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "Save", style: .default) { (_) in
                guard let name = alertController.textFields?[0].text else{return}
                self.notebookName = name
                //add book to database
                self.saveBook(node: node, name: self.notebookName)
            }
            alertController.addTextField { (textField) in
                textField.placeholder = "New Notebook"
            }
            alertController.addAction(confirmAction)
            self.present(alertController, animated: true, completion: nil)
            //render book on root
            self.sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func addRetrievedBook(hitTestResult: ARHitTestResult){
        let scene = SCNScene(named: "art.scnassets/Book.dae")
        let node = (scene?.rootNode.childNode(withName: "Book_", recursively: false))!
        node.name = "Book"
        
        let coverMaterial = SCNMaterial()
        coverMaterial.diffuse.contents = UIImage(named: "purpleRain")
        coverMaterial.locksAmbientWithDiffuse = true
        node.geometry?.firstMaterial = coverMaterial
        ref.child("notebooks/\(notebookID)").updateChildValues(["CoverStyle" : "purple"])
        
        hitResult = hitTestResult
        //coordinates from the hit test give us the plane anchor to put the book ontop of, coordinates are stored in the 3rd column.
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        bookNode = node //assign the book node to the global variable for book node
        //check if another book object exists
        if self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) != nil {
            let alertController = UIAlertController(title: "Error", message: "You can only place one book at a time.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel){ (result : UIAlertAction) -> Void in
            }
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            //give the user an option to name the notebook
            let alertController = UIAlertController(title: "Notebook Namesdgdfsgs", message: "Enter a name to create your new notebook.", preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "Save", style: .default) { (_) in
                guard let name = alertController.textFields?[0].text else{return}
                self.notebookName = name
                //add book to database
                self.saveBook(node: node, name: self.notebookName)
                self.notebookExists = true
            }
            alertController.addTextField { (textField) in
                textField.placeholder = "New Notebook"
            }
            alertController.addAction(confirmAction)
            self.present(alertController, animated: true, completion: nil)
            //render book on root
            self.sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    /*
     -----
     Focus Square
     -----
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
    
    /*
     -----
     Insert View Controller Callback Functions
     -----
     */
    func passText(text: String) {
        dismiss(animated: true, completion: nil)
        if bookNode != nil && currentPageNode != nil{
            
            if template == "single"{
                //check to see if the content is a sotrage url - which means its an image.
                if text.range(of:"firebasestorage.googleapis.com") != nil {
                    if let page = currentPageNode {
                        let url = URL(string: text)
                        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
                            guard let image = UIImage(data: data!) else {return}
                            let node = SCNNode()
                            node.geometry = SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0)
                            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                            node.position = SCNVector3(0,0, 0.001)
                            self.lastNode.append(node)
                            page.addChildNode(node)
                        }).resume()
                    }
                }
                else{
                addTopContent(content1: text)
                let textNode = SCNText(string: text, extrusionDepth: 0.1)
                textNode.font = UIFont(name: "Arial", size:1)
                textNode.containerFrame = CGRect(origin:CGPoint(x: -0.5,y :-8.0), size: CGSize(width: 10, height: 16))
                textNode.truncationMode = kCATruncationEnd
                textNode.alignmentMode = kCAAlignmentLeft
                textNode.isWrapped = true
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.black
                textNode.materials = [material]
                let node = createTextNode(text: textNode)
                renderNode(node: node)
            }
            }
                
            else if template == "double"{
                if topTempNodeContent == "empty" && bottomTempNodeContent == "empty"{
                    addTopContent(content1: text)
                    let textNode = SCNText(string: text, extrusionDepth: 0.1)
                    textNode.font = UIFont(name: "Arial", size:1)
                    textNode.containerFrame = CGRect(origin:CGPoint(x: -0.5,y :-8.0), size: CGSize(width: 10, height: 16))
                    textNode.truncationMode = kCATruncationEnd
                    textNode.alignmentMode = kCAAlignmentLeft
                    textNode.isWrapped = true
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.black
                    textNode.materials = [material]
                    let node = createTextNode(text: textNode)
                    renderNode(node: node)
                }
            }
            else if template == "double"{
                if topTempNodeContent == "empty" && bottomTempNodeContent == "empty"{
                    //check to see if the content is a sotrage url - which means its an image.
                    if text.range(of:"firebasestorage.googleapis.com") != nil {
                        if let page = currentPageNode {
                            let url = URL(string: text)
                            URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
                                guard let image = UIImage(data: data!) else {return}
                                let node = SCNNode()
                                node.geometry = SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0)
                                node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                                node.position = SCNVector3(0,0, 0.001)
                                self.lastNode.append(node)
                                page.addChildNode(node)
                            }).resume()
                        }
                    }
                    else{
                        //check to see if the content is a sotrage url - which means its an image.
                        if text.range(of:"firebasestorage.googleapis.com") != nil {
                            if let page = currentPageNode {
                                let url = URL(string: text)
                                URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
                                    guard let image = UIImage(data: data!) else {return}
                                    let node = SCNNode()
                                    node.geometry = SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0)
                                    node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                                    node.position = SCNVector3(0,0, 0.001)
                                    self.lastNode.append(node)
                                    page.addChildNode(node)
                                }).resume()
                            }
                        }
                        else{
                            addTopContent(content1: text)
                            let textNode = SCNText(string: text, extrusionDepth: 0.1)
                            textNode.font = UIFont(name: "Arial", size:1)
                            textNode.containerFrame = CGRect(origin:CGPoint(x: -0.5,y :-3.5), size: CGSize(width: 10, height: 7))
                            textNode.truncationMode = kCATruncationEnd
                            textNode.alignmentMode = kCAAlignmentLeft
                            textNode.isWrapped = true
                            let material = SCNMaterial()
                            material.diffuse.contents = UIColor.black
                            textNode.materials = [material]
                            let node = createTextNode(text: textNode)
                            renderNode(node: node)
                        }
                    }
                }
                else if topTempNodeContent == "full" && bottomTempNodeContent == "empty"{
                    addBottomContent(content2: text)
                    let textNode = SCNText(string: text, extrusionDepth: 0.1)
                    textNode.font = UIFont(name: "Arial", size:1)
                    textNode.containerFrame = CGRect(origin:CGPoint(x: -0.5,y :-3.5), size: CGSize(width: 10, height: 7))
                    textNode.truncationMode = kCATruncationEnd
                    textNode.alignmentMode = kCAAlignmentLeft
                    textNode.isWrapped = true
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.black
                    textNode.materials = [material]
                    let node = createTextNode(text: textNode)
                    renderNode(node: node)
                }
            }
        }
        else{ //error for if there is no book
            let alertController = UIAlertController(title: "Error", message: "Please add a notebook or page before adding text", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func addTopContent(content1: String){
        ref.child("notebooks/\((self.notebookID))/\(self.currentPage)").updateChildValues(["content1" : content1])
    }
    
    func addBottomContent(content2: String){
        ref.child("notebooks/\((self.notebookID))/\(self.currentPage)").updateChildValues(["content2" : content2])
    }
    
    // functions to pass the image through to the VIEW CONTROLLER
    func passImage(image: UIImage) {
        dismiss(animated: true, completion: nil)
        if let page = currentPageNode {
            if template == "single"{
                let node = SCNNode(geometry: SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0))
                node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                node.position = SCNVector3(0,0, 0.001)
                lastNode.append(node)
                templateNode?.addChildNode(node)            }
            else if template == "double"{
                if topTempNodeContent == "empty" && bottomTempNodeContent == "empty"{
                    let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                    node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                    node.position = SCNVector3(0,0.0, 0.001)
                    lastNode.append(node)
                    topTempNode?.addChildNode(node)
                    topTempNodeContent = "full"
                }
                else if topTempNodeContent == "full" && bottomTempNodeContent == "empty"{
                    
                    let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                    node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                    node.position = SCNVector3(0,0,0.001)
                    lastNode.append(node)
                    bottomTempNode?.addChildNode(node)
                    bottomTempNodeContent = "full"
                }
                else if topTempNodeContent == "full" && bottomTempNodeContent == "full"{
                    print("both are full")
                    let alertController = UIAlertController(title: "Error", message: "both templates are full", preferredStyle: UIAlertControllerStyle.alert)
                    let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel){ (result : UIAlertAction) -> Void in
                    }
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            else { //error for no page
                dismiss(animated: true, completion: nil)
                let alertController = UIAlertController(title: "Error", message: "Please add a page before adding an image", preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
                let addPageAction = UIAlertAction(title: "Add Page", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                    //@FIXME Add page needs to call other view controller.
                    //self.addPage(self)
                }
                alertController.addAction(cancelAction)
                alertController.addAction(addPageAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    /*
     -----
     Add Page Deletegate Funcitons
     -----
     */
    /* added page, templates will be based on if else conditions,
     if temp == single ( create single temp) geometry slight smaller than page node positioned center of page
     else temp == two slot (create two slots) geometry ( height and width of noth nodes equal) positioned half
     of page
     
     */
    
    func addPage(text: String){
        dismiss(animated: true, completion: nil)
        if bookNode == nil {
            let alertController = UIAlertController(title: "Error", message: "Please add a notebook before adding a page", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            if text == "single" {
                createPage()
                oneSlotTemplate()
                template = text
            }
            else if text == "double"{
                createPage()
                twoSlotTemplate()
                template = text
            }
            
        }
    }
    
    func saveBook(node: SCNNode, name: String) {
        //generate a unique id for the notebook
        guard let profile = currentProfile else {print("error"); return}
        let id = self.generateUniqueNotebookID(node: node)
        self.notebookID = id
        self.ref.child("users/\(profile)/notebooks/\(id)").setValue(["name": self.notebookName])
        self.ref.child("notebooks/\(id)").setValue(["name": self.notebookName])
    }
    
    func generateUniqueNotebookID(node: SCNNode) ->Int {
        return ObjectIdentifier(node).hashValue
    }
    func deleteBook(node: SCNNode) {
        
        let bookID : Int = notebookID
        let bookString = String(bookID)
        print(bookString)
        self.ref?.child("notebooks").child(bookString).removeValue()
        self.ref?.child("users").child(currentProfile).child("notebooks").child(bookString).removeValue()
    }
    func deletePage(node: SCNNode){
        guard let profile = currentProfile else {print("error"); return}
        let bookID : Int = notebookID
        let bookString = String(bookID)
        let pageID : Int = currentPage
        let pageString = String(pageID)
        print(bookString)
        self.ref?.child("notebooks").child(bookString).child(pageString).removeValue()
    }
    
    func pageContent(node: SCNNode){
        guard let profile = currentProfile else {print("error"); return}
        let bookID : Int = notebookID
        let bookString = String(bookID)
        let pageID : Int = currentPage
        let pageString = String(pageID)
        let pageContent : String = pageContentInfo//global var
        let pageSting = String(pageContent)
        
        print(bookString)
        self.ref?.child("notebooks").child(bookString).child(pageString).removeValue()
    }
    
    /*
     -----
     Delete Deletegate Funcitons
     -----
     */
    
    func deletePage(){
        dismiss(animated: true, completion: nil)
        if currentPageNode == nil && pages.isEmpty == true{
            let alertController = UIAlertController(title: "Error", message: "There is nothing to delete, Please add a page.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else if  bookNode == nil && currentPageNode == nil{
            let alertController = UIAlertController(title: "Error", message: "There is nothing to delete, Please add a book and page.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else {
            
            let deletePageNode = SCNNode()
            let alertController = UIAlertController(title: "Confirm Delete Page", message: "Are you sure you want to delete the page ?", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel)
            let deletePageAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                self.currentPageNode?.removeFromParentNode()
                self.deletePage(node: self.currentPageNode!)
                self.pages.removeLast()
                self.currentPageNode = self.pages.last
                
            }
            alertController.addAction(cancelAction)
            alertController.addAction(deletePageAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    func deleteNotebook(){
        dismiss(animated: true, completion: nil)
        
        if  bookNode == nil {
            let alertController = UIAlertController(title: "Error", message: "There is nothing to delete, Please add a book.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else {
            let alertController = UIAlertController(title: "Confirm Delete Notebook", message: "Are you sure you want to delete the Notebook ?", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel)
            let deletePageAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                
                
                if self.bookNode != nil && self.pages.isEmpty == true{
                    self.bookNode?.removeFromParentNode()
                }
                else if self.bookNode != nil && self.pages.isEmpty == false{
                    self.bookNode?.removeFromParentNode()
                    self.deleteBook(node: self.bookNode!)
                    self.pages.removeAll()
                    self.lastNode.removeAll()
                    self.currentPageNode = nil
                    self.bookNode = nil
                    self.currentTemplateNode = nil
                }
                self.bookNode?.removeFromParentNode()
                self.bookNode = nil
                self.pages.removeAll()
                self.lastNode.removeAll()
                self.currentPageNode = nil
            }
            alertController.addAction(cancelAction)
            alertController.addAction(deletePageAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    /*
     -----
     Page Color Deletegate Funcitons
     -----
     */
    
    func pageColor(image: UIImage) {
        if bookNode != nil {
            if currentPageNode != nil{
                for page in pages {
                    page.geometry?.firstMaterial?.diffuse.contents = image
                }
            }
            else{
                let alertController = UIAlertController(title: "Error", message: "Please add a page before selecting color", preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            // maybe an array for all the pages to change all or a single page at a time ?
        }
        else{ //error for if there is no book
            let alertController = UIAlertController(title: "Error", message: "Please add a notebook or page before adding text", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    /*
     -----
     book Color Deletegate Funcitons
     -----
     */
    
    func bookColor(imageOne: UIImage, cover: String) {
        bookNode?.geometry?.firstMaterial?.diffuse.contents = imageOne
        ref.child("notebooks/\(notebookID)").updateChildValues(["CoverStyle" : cover])
    }
    /*
     -----
     Template Functions
     -----
     */
    
    func oneSlotTemplate(){
        if let page = currentPageNode{
            let node = SCNNode(geometry: SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0))
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node.position = SCNVector3(0,0, 0.001)
            page.addChildNode(node)
            templateNode = node
            currentTemplateNode = node
        }
    }
    
    func twoSlotTemplate(){
        if let page = currentPageNode{
            let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
            let node2 = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
            //creating the first slot of the two slot template
            
            
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node.position = SCNVector3(0,0.4, 0.001)
            //creating the second slot of the two slot template
            
            node2.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node2.position = SCNVector3(0,-0.4, 0.001)
            //adding both to the page
            page.addChildNode(node)
            page.addChildNode(node2)
            topTempNode = node
            bottomTempNode = node2
        }
    }
    /*
     -----
     Retrieve delegate function
     -----
     */
    func addPageWithContent(content: String, temp: String){
        if let bookNode = self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) {
            
            if temp == "single" {
                createPage()
                oneSlotTemplate()
                template = temp
                
            }
            else if temp == "double"{
                createPage()
                twoSlotTemplate()
                template = temp
            }
            passText(text: content)
            
        }
        else{
            //error no book
        }
    }
    
    func addContent(id: String, pageObjs: [Page]) {
        notebookID = Int(id)!
        var t = "single"
        dismiss(animated: true, completion: nil)
        for page in pageObjs {
            let end = page.content.count - 1
            if(end > 0){
                t = "double"
            }
            for i in 0...end {
                print(page.content[i])
                addPageWithContent(content: page.content[i], temp: t)
            }
            /*
             int end = page.count - 1
             for i in 0...end {
             if (page.content[i].count > 1){
             print("page has more than one child")
             }
             else{
             print("page has one child")
             /// pass a sting that choose the template sting"single"???
             }
             }*/
        }
        //let end = Page
        /* for i in 0...end {
         addPageWithContent(content: content[i])
         }*/
    }
    /*
     -----
     Segue definitions
     -----
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? insertViewController{
            destination.delegate = self
        }
        else if let destination = segue.destination as? addPageViewController {
            destination.delegate = self
        }
        else if let destination = segue.destination as? deleteViewController {
            destination.delegate = self
        }
        else if let destination = segue.destination as? pageColorViewController{
            destination.delegate = self
        }
        else if let destination = segue.destination as? retrieveViewController {
            destination.delegate = self
        }
    }
    @IBAction func myUnwindAction(unwindSegue:UIStoryboardSegue){
        //
    }
    
}


//converts degrees to radians, since objects are oriented according to radians
//credit to udemy video
extension Int {
    var degreesToRadians: Double {return Double(self) * .pi/180}
}


