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
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var maxScale: CGFloat = 0
    var minScale: CGFloat = 5
    var hitResult : ARHitTestResult? = nil
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
    var notebookExists : Bool = false
    var retrievedFlag : Bool = false
    var pageObjectArray = [Page]()
    var accessToWrite : Bool = false
    
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
        // Run the view's session
        self.configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        self.sceneView.delegate = self
        currentProfile = nameDelegate?.profileName
        self.sceneView.autoenablesDefaultLighting = true
        addTimer()
    }
    
    func addTimer(){
        var planetimeout: Timer?
        planetimeout = Timer.scheduledTimer(withTimeInterval: 40.0, repeats: true, block: { (_) in
            if self.notebookExists == true{
                planetimeout?.invalidate()
            } else {
                let alertController = UIAlertController(title: "No Surface Detected", message: "Please place a notebook, or try a clear flat surface.", preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            
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
        if currentPageNode != nil {
            if template == "single"{
                let temp = currentTemplateNode
                lastNode.append(node)
                temp?.addChildNode(node)
            }
            else if template == "double"{
                
                if topTempNodeContent == "empty" && bottomTempNodeContent == "empty"{
                    lastNode.append(node)
                    topTempNode?.addChildNode(node)
                    
                    topTempNodeContent = "full"
                }
                else if topTempNodeContent == "full" && bottomTempNodeContent == "empty"{
                    lastNode.append(node)
                    bottomTempNode?.addChildNode(node)
                    bottomTempNodeContent = "full"
                    
                }
                else if topTempNodeContent == "full" && bottomTempNodeContent == "full"{
                    
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
    
    func createPage(){
        if self.notebookExists == true || self.retrievedFlag == true  {
            var offset = 0.02
            let pageNode = SCNNode(geometry: SCNBox(width: 1.4, height: 1.8, length:0.001, chamferRadius: 0.0))
            //@FIXME have fixed hieght for now bounding box isnt working
            
            pageNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "page")
            
            pageNode.geometry?.firstMaterial?.isDoubleSided = true
            //@FIXME issues with y position here, the page isnt placed right ontop of the book
            
            
            if(pages.count != 0){
                offset = Double(pages.count) * 0.01
            }
            pageNode.position = SCNVector3(0.0, offset, 0)
            pageNode.eulerAngles = SCNVector3(-90.degreesToRadians, 0, 0)
            pages.append(pageNode)
            pageNode.name = String(pages.count)
            currentPageNode = pageNode
            self.bookNode?.addChildNode(pageNode)
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
             var offset = 0.02
            let  i = Int((currentPageNode?.name)!)
            let previous = i! - 2;
            let turnPage = pages[previous]
            //need to calculate some offset.
            
            if(pages.count != 0){
                offset = Double(pages.count) * 0.01;
            }
            turnPage.pivot = SCNMatrix4MakeTranslation(-0.9, 0, 0)
            turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 1))
            turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 0)) //rotate the rest of the way without animation
            turnPage.position = SCNVector3(-0.9, offset, 0)
            currentPageNode?.isHidden = true;
            currentPageNode = turnPage
            currentPage = Int((currentPageNode?.name)!)!
        }
    }
    
    @IBAction func leftSwipe(_ sender: Any) {
        //if there is more than one page and the current page node is the last one in the array turn the page forward
        
        if (pages.count > 1 && (currentPage <= Int(pages.count - 1))) {
            var offset = 0.02
            let i = Int((currentPageNode?.name)!)
            let previous = i!;
            let turnPage = pages[previous]
            if(pages.count != 0){
                offset = Double(pages.count) * 0.01;
            }
            // Point in the -z direction
            turnPage.pivot = SCNMatrix4MakeTranslation(-0.9, 0, 0)
            turnPage.runAction(SCNAction.rotate(by: -.pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 1))
            turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 0)) //rotate the rest of the way without animation
            turnPage.position = SCNVector3(-0.9, offset, 0)
            turnPage.isHidden = false
            currentPageNode = turnPage
            currentPage = Int((currentPageNode?.name)!)!
            
        }
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if retrievedFlag == true {
            if !hitTest.isEmpty {
                self.addRetrievedBook(hitTestResult: hitTest.first!)
            }
        }
        else if !hitTest.isEmpty {
            self.addBook(hitTestResult: hitTest.first!)
        }
    }
    
    func addBook(hitTestResult: ARHitTestResult) {
        if self.notebookExists == true {
            /*
             let alertController = UIAlertController(title: "Error", message: "You can only place one book at a time.", preferredStyle: UIAlertControllerStyle.alert)
             let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel){ (result : UIAlertAction) -> Void in
             }
             alertController.addAction(cancelAction)
             self.present(alertController, animated: true, completion: nil)*/
            return
        }
        else{
            let node = createBook(hitTestResult: hitTestResult)
            //give the user an option to name the notebook
            let alertController = UIAlertController(title: "Notebook Name", message: "Enter a name to create your new notebook.", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "Save", style: .default) { (_) in
                guard let name = alertController.textFields?[0].text else{return}
                self.saveBook(node: node, name: name)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .default) { (_) in }
            alertController.addTextField { (textField) in
                textField.placeholder = "New Notebook"
                /*// limit the text characters to be less than 15
                 func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
                 let startingLength = textField.text?.characters.count ?? 0
                 let lengthToAdd = string.characters.count
                 let lengthToReplace = range.length
                 let newLength = startingLength + lengthToAdd - lengthToReplace
                 return newLength <= 500
                 }*/
            }
            alertController.addAction(confirmAction)
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func addRetrievedBook(hitTestResult: ARHitTestResult){
        //check if another book object exists
        if self.notebookExists == true {
            /* broken right now
             let alertController = UIAlertController(title: "Error", message: "You can only place one book at a time.", preferredStyle: UIAlertControllerStyle.alert)
             let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel){ (result : UIAlertAction) -> Void in }
             alertController.addAction(cancelAction)
             self.present(alertController, animated: true, completion: nil)*/
            return
        }
        else{
            let node = createBook(hitTestResult: hitTestResult)
            //render book on root
            self.sceneView.scene.rootNode.addChildNode(node)
            self.notebookExists = true
            self.addContent(id: String(notebookID), pageObjs: self.pageObjectArray)
        }
    }
    
    func createBook(hitTestResult: ARHitTestResult) -> SCNNode{
        let scene = SCNScene(named: "art.scnassets/Book.dae")
        let node = (scene?.rootNode.childNode(withName: "Book_", recursively: false))!
        node.name = "Book"
        let coverMaterial = SCNMaterial()
        coverMaterial.diffuse.contents = UIImage(named: "graphicBook1 copy2")
        coverMaterial.locksAmbientWithDiffuse = true
        node.geometry?.firstMaterial = coverMaterial
        hitResult = hitTestResult
        //coordinates from the hit test give us the plane anchor to put the book ontop of, coordinates are stored in the 3rd column.
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        self.bookNode = node //assign the book node to the global variable for book node
        return node
    }
    
    func saveBook(node: SCNNode, name: String) {
        let id = self.generateUniqueNotebookID(node: node) //generate a unique id for the notebook
        self.notebookID = id
        self.notebookName = name
        self.ref.child("users/\((self.currentProfile)!)/notebooks/\(id)").setValue(["name": self.notebookName])
        self.ref.child("notebooks/\(id)").setValue(["name": self.notebookName])
        //render book on root
        self.sceneView.scene.rootNode.addChildNode(node)
        self.notebookExists = true
        
    }
    
    func generateUniqueNotebookID(node: SCNNode) ->Int {
        return ObjectIdentifier(node).hashValue
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
    
    /*text helpers*/
    func createSlots(xf: Double, yf: Double, hght: Int, text: String){
        let textNode = SCNText(string: text, extrusionDepth: 0.1)
        textNode.font = UIFont(name: "Arial", size:1)
        textNode.containerFrame = CGRect(origin:CGPoint(x: xf, y:yf), size: CGSize(width: 10, height: hght))
        textNode.truncationMode = kCATruncationEnd
        textNode.alignmentMode = kCAAlignmentLeft
        textNode.isWrapped = true
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        textNode.materials = [material]
        let node = createTextNode(text: textNode)
        renderNode(node: node)
    }
    
    /*
     -----
     Insert View Controller Callback Functions
     -----
     */
    
    func passText(text: String, f: Int = 0) {
        if(f == 0) {
            dismiss(animated: true, completion: nil)
        }
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
                            node.position = SCNVector3(0,0, 0.01)
                            self.lastNode.append(node)
                            page.addChildNode(node)
                        }).resume()
                    }
                }
                else{
                    if(f == 0){
                        addTopContent(content1: text)
                    }
                    createSlots(xf: -0.5, yf: -8.0, hght: 16, text: text)
                }
            }
            else if template == "double"{
                if topTempNodeContent == "empty" && bottomTempNodeContent == "empty"{
                    if text.range(of:"firebasestorage.googleapis.com") != nil {
                        if currentPageNode != nil {
                            let url = URL(string: text)
                            URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
                                guard let image = UIImage(data: data!) else {return}
                                let node = SCNNode()
                                node.geometry = SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0)
                                node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                                node.position = SCNVector3(0,0, 0.01)
                                self.lastNode.append(node)
                                self.topTempNode?.addChildNode(node)
                            }).resume()
                        }
                    }
                    else{
                        if(f == 0){
                            addTopContent(content1: text)
                        }
                        createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                    }
                }
                else if topTempNodeContent == "full" && bottomTempNodeContent == "empty"{
                    if text.range(of:"firebasestorage.googleapis.com") != nil {
                        if currentPageNode != nil {
                            let url = URL(string: text)
                            URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
                                guard let image = UIImage(data: data!) else {return}
                                let node = SCNNode()
                                node.geometry = SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0)
                                node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                                node.position = SCNVector3(0,0, 0.001)
                                self.lastNode.append(node)
                                self.bottomTempNode?.addChildNode(node)
                            }).resume()
                        }
                    }
                    else{
                        if(f == 0){
                            addBottomContent(content2: text)
                        }
                        createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                    }
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
        if currentPageNode != nil {
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
     Add Notebook Clear Functions
     -----
     */
    
    @IBAction func ClearNotebook(_ sender: Any) {
        let alertController = UIAlertController(title: "Confirm Clear Notebook", message: "Are you sure you want to clear the Notebook ?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let deletePageAction = UIAlertAction(title: "Clear", style: .default) { (result : UIAlertAction) -> Void in
            let loadingAlert = UIAlertController(title: nil, message: "Clearing", preferredStyle: .alert)
            self.present(loadingAlert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.clearBook()
                loadingAlert.dismiss(animated: true, completion: nil)
            })
        }
        alertController.addAction(cancelAction)
        alertController.addAction(deletePageAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func clearNodes(){  // resets all of the current global node variables
        self.currentPageNode = nil
        self.bookNode = nil
        self.currentTemplateNode = nil
        self.bottomTempNode = nil
        self.topTempNode = nil
        self.templateNode = nil
        self.notebookExists = false
        self.hitResult = nil
        self.retrievedFlag = false
    }
    
    func clearBook(){
        //dismiss(animated: true, completion: nil) might delete if this is in the main view controller
        self.bookNode?.removeFromParentNode()
        self.pages.removeAll()
        self.lastNode.removeAll()
        self.clearNodes()
    }
    
    /*
     -----
     Add Page Delete Functions
     -----
     */
    /* added page, templates will be based on if else conditions,
     if temp == single ( create single temp) geometry slight smaller than page node positioned center of page
     else temp == two slot (create two slots) geometry ( height and width of noth nodes equal) positioned half
     of page
     
     */
    
    /*func deleteBook(node: SCNNode) {
     self.notebookExists = false
     self.ref?.child("notebooks").child((self.notebookID)!).removeValue()
     self.ref?.child("users").child(self.currentProfile).child("notebooks").child((self.notebookID)!).removeValue()
     }*/
    
    func deletePage(node: SCNNode){
        let bookID : Int = notebookID
        let bookString = String(bookID)
        let pageID : Int = currentPage
        let pageString = String(pageID)
        self.ref?.child("notebooks").child(bookString).child(pageString).removeValue()
    }
    
    func pageContent(node: SCNNode){
        let bookID : Int = notebookID
        let bookString = String(bookID)
        let pageID : Int = currentPage
        let pageString = String(pageID)
        self.ref?.child("notebooks").child(bookString).child(pageString).removeValue()
    }
    
    func deletePage(){
        dismiss(animated: true, completion: nil)
        if  bookNode == nil && currentPageNode == nil{
            let alertController = UIAlertController(title: "Error", message: "There is nothing to delete, Please add a book and page.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else {
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
                    let loadingAlert = UIAlertController(title: nil, message: "Deleting", preferredStyle: .alert)
                    self.present(loadingAlert, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        self.clearBook()
                        loadingAlert.dismiss(animated: true, completion: nil)
                    })                }
                else if self.bookNode != nil && self.pages.isEmpty == false{
                    let loadingAlert = UIAlertController(title: nil, message: "Deleting", preferredStyle: .alert)
                    self.present(loadingAlert, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        self.ref?.child("notebooks").child(String(self.notebookID)).removeValue()
                        self.ref?.child("users").child(self.currentProfile).child("notebooks").child(String(self.notebookID)).removeValue()
                        self.clearBook()
                        loadingAlert.dismiss(animated: true, completion: nil)
                    })
                }
                self.clearBook()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(deletePageAction)
            self.present(alertController, animated: true, completion: nil)
        }
        self.notebookExists = false
    }
    
    /*
     -----
     Page Color Delegate Functions
     -----
     */
    
    func pageColor(image: UIImage) {
        if bookNode != nil && currentPageNode != nil {
            for page in pages {
                page.geometry?.firstMaterial?.diffuse.contents = image
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
     Share Button
     -----
     */
    @IBAction func shareNotebook(){
        //notebook ID of the notebook to share
        if self.notebookID > 0 {
            let id = String(self.notebookID)
            showShareAlert(id: id)
        }
        else {
            showErrorShareAlert()
        }
    }
    func showShareAlert(id: String){
        let shareVC = shareViewController()
        var link = ""
        
        //on click of share present popup asking for read or write access.
        var writeAccess = false
        
        let alertController = UIAlertController(title: "Share", message: "You are sharing this notebook. Do you wish to give the receiver read or write access?", preferredStyle: UIAlertControllerStyle.alert)
        let addReadAccess = UIAlertAction(title: "Read", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            writeAccess = false
            //call to dynamic link generator here??
            shareVC.buildLinkOptions(access: writeAccess, id: id)
            link = shareVC.returnShareLink()
           self.showShareLink(url: link)
        }
        let addWriteAccess = UIAlertAction(title: "Write", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            writeAccess = true
           shareVC.buildLinkOptions(access: writeAccess, id: id)
           link = shareVC.returnShareLink()
            self.showShareLink(url: link)
        }
        alertController.addAction(addReadAccess)
        alertController.addAction(addWriteAccess)
        self.present(alertController, animated: true, completion: nil)
    }
    func showErrorShareAlert(){
        let alertController = UIAlertController(title: "Error", message: "You have no notebook visible to share!", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        
    }
    func showShareLink(url: String) {
        let activityViewController = UIActivityViewController(activityItems: [url as String], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x:185.0, y:95.0, width:1.0, height:1.0);
        present(activityViewController, animated: true, completion: nil)
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
        if self.notebookExists == true || self.retrievedFlag == true {
            if temp == "single" {
                createPage()
                oneSlotTemplate()
                template = temp
                passText(text: content, f: 1)
            }
            else if temp == "double"{
                createPage()
                twoSlotTemplate()
                template = temp
                passText(text: content, f: 1)
            }
            else if temp == "doubleSecond" {
                template = "double"
                passText(text: content, f:1)
            }
        }
        else {
            //error no book
        }
    }
    
    func addContent(id: String, pageObjs: [Page]) {
        self.notebookExists = true
        notebookID = Int(id)!
        var t = "single"
        for page in pageObjs {
            let end = page.content.count - 1
            if(end == 1){
                t = "double"
            }
            else{
                t = "single"
            }
            for i in 0...end {
                if (i == 1 && t == "double"){
                    t = "doubleSecond"
                }
                addPageWithContent(content: page.content[i], temp: t)
            }
        }
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
