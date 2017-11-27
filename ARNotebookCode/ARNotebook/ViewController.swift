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


class ViewController:  UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate, insertDelegate, addPageDelegate, pageColorDelegate, retrieveDelegate {
    
    
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
    var hitResult2 : SCNHitTestResult? = nil
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
    var topTempNodeContent :String = ""
    var bottomTempNodeContent :String = ""
    var templateExists : Bool = false
    var notebookExists : Bool = false
    var retrievedFlag : Bool = false
    var pageObjectArray = [Page]()
    var selectedTemplate : SCNNode!
    var accessToWrite : Bool = true
    var alert = alertHelper()
    var prevVC: retrieveViewController!
    
    /*
     -----
     Generic Session Setup
     -----
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()
        if prevVC != nil {
            prevVC.dismiss(animated: false, completion: nil)
        }
        self.disableButtons()
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
        self.registerGestures()
        self.configuration.planeDetection = .horizontal  // Create a session configuration
        sceneView.session.run(configuration) // Run the view's session
        self.sceneView.delegate = self
        currentProfile = nameDelegate?.profileName
        self.sceneView.autoenablesDefaultLighting = true
        addTimer()
    }
    
    /*
     -----
     Outlets to buttons
     -----
     */
    @IBOutlet weak var deletePageButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var addPageButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var insertButton: UIButton!
    
    func disableButtons(){
        self.deletePageButton.isEnabled = false
        self.dismissButton.isEnabled = false
        self.shareButton.isEnabled = false
        self.undoButton.isEnabled = false
        self.addPageButton.isEnabled = false
        self.editButton.isEnabled = false
        self.insertButton.isEnabled = false
    }
    
    func enableBookButtons(){
        self.dismissButton.isEnabled = true
        self.addPageButton.isEnabled = true
        self.editButton.isEnabled = true
    }
    
    func enablePageButtons(){
        self.deletePageButton.isEnabled = true
        self.undoButton.isEnabled = true
        self.insertButton.isEnabled = true
        self.shareButton.isEnabled = true
    }
    
    func addTimer(){
        var planetimeout: Timer?
        planetimeout = Timer.scheduledTimer(withTimeInterval: 40.0, repeats: true, block: { (_) in
            if self.notebookExists == true{
                planetimeout?.invalidate()
            } else {
                let alertController = UIAlertController(title: "No Book Detected", message: "Please place a notebook, or try a clear flat surface.", preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    func registerGestures(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        print((self.sceneView.gestureRecognizers)!)
    }
    
    func tapGestureEnabling(){
        let tempGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        for object in self.sceneView.gestureRecognizers!{
            if object == tempGesture{
                if notebookExists == true {
                    object.isEnabled = false
                }
                else {
                    object.isEnabled = true
                }
            }
        }
    }
    
    
    //@objc becuse selector is an object c
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        if sender.state == .began{
        } else if sender.state == .ended{
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
        if accessToWrite == true {
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
        }
        else {
            alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
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
        node.name = "content"
        node.scale = SCNVector3(x: 0.1, y:0.1, z:0.1)
        node.position = SCNVector3(-0.5, 0.0, 0.001)
        return node;
    }
    func renderNode(node: SCNNode) {
        if template == "single"{
            let temp = selectedTemplate
            lastNode.append(node)
            temp?.addChildNode(node)
        }
        else if template == "double"{
            if selectedTemplate != nil{
                let tempNode = selectedTemplate
                lastNode.append(node)
                tempNode?.addChildNode(node)
            }
            else if selectedTemplate != nil{
                let tempNode = selectedTemplate
                lastNode.append(node)
                bottomTempNode?.addChildNode(node)
                tempNode?.addChildNode(node)
            }
        }
    }
    
    func addPage(text: String){
        dismiss(animated: true, completion: nil)

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
        self.enablePageButtons()
    }
    
    func createPage(){
        var offset = 0.0
        let pageNode = SCNNode(geometry: SCNBox(width: 1.4, height: 1.8, length:0.001, chamferRadius: 0.0))
        //@FIXME have fixed hieght for now bounding box isnt working
        pageNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "page")
        pageNode.geometry?.firstMaterial?.isDoubleSided = true
        //@FIXME issues with y position here, the page isnt placed right ontop of the book
        if(pages.count != 0){
            offset = Double(pages.count) * 0.02
        }
        pageNode.position = SCNVector3(0.0, 0.02 + offset, 0)
        pageNode.eulerAngles = SCNVector3(-90.degreesToRadians, 0, 0)
        pages.append(pageNode)
        pageNode.name = String(pages.count)
        currentPageNode = pageNode
        self.bookNode?.addChildNode(pageNode)
        currentPage = Int((currentPageNode?.name)!)!
        //          page.currentPageNode = pageNode
        //           pageStack.append(page)
        //            topTempNodeContent = "empty"
        //            bottomTempNodeContent = "empty"
        addPageNum()
        //            print(pageStack.count)
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
            var offset = 0.0
            let  i = Int((currentPageNode?.name)!)
            let previous = i! - 2;
            let turnPage = pages[previous]
            //need to calculate some offset.
            
            if(previous != 0){
                offset = Double(previous) * 0.02;
            }
            turnPage.pivot = SCNMatrix4MakeTranslation(-0.9, 0, 0)
            turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 1))
            turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 0)) //rotate the rest of the way without animation
            turnPage.position = SCNVector3(-0.9, 0.021 + offset, 0)
            currentPageNode?.isHidden = true;
            currentPageNode = turnPage
            currentPage = Int((currentPageNode?.name)!)!
        }
    }
    
    @IBAction func leftSwipe(_ sender: Any) {
        //if there is more than one page and the current page node is the last one in the array turn the page forward
        
        if (pages.count > 1 && (currentPage <= Int(pages.count - 1))) {
            var offset = 0.0
            let i = Int((currentPageNode?.name)!)
            let previous = i!;
            let turnPage = pages[previous]
            if(previous != 0){
                offset = Double(previous) * 0.02;
            }
            // Point in the -z direction
            turnPage.pivot = SCNMatrix4MakeTranslation(-0.9, 0, 0)
            turnPage.runAction(SCNAction.rotate(by: -.pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 1))
            turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 0)) //rotate the rest of the way without animation
            turnPage.position = SCNVector3(-0.9, 0.021 + offset, 0)
            turnPage.isHidden = false
            currentPageNode = turnPage
            currentPage = Int((currentPageNode?.name)!)!
            
        }
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if notebookExists == false{
            if retrievedFlag == true {
                if !hitTest.isEmpty {
                    self.addRetrievedBook(hitTestResult: hitTest.first!)
                }
            }
            else if !hitTest.isEmpty {
                self.addBook(hitTestResult: hitTest.first!)
            }
        }
        else if notebookExists == true {
            let tapLocation2 = sender.location(in: sceneView)
            let hitTest2 = sceneView.hitTest(tapLocation2)
            if hitTest2.isEmpty {
                print("nothing has been tapped on")
            }
            else {
                let results = hitTest2
                selectTemplate(hitTest: results)
                print("successful tap")
            }
        }
    }
    func selectTemplate(hitTest : [SCNHitTestResult]){
        if self.templateExists == true {
            self.hitResult2 = hitTest.first
            let node = hitTest.first?.node
            if node == self.topTempNode{
                print("Top node selected")
                self.selectedTemplate = node
            }
            else if node == self.bottomTempNode{
                self.selectedTemplate = node
                print("Bottom node selected")
            }
            else if node == self.templateNode{
                self.selectedTemplate = node
                print("Single template selected")
            }
            else{
                print("cant find a node")
            }
        }
    }
    
    func addBook(hitTestResult: ARHitTestResult) {
        if self.notebookExists == true {
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
            }
            alertController.addAction(confirmAction)
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func addRetrievedBook(hitTestResult: ARHitTestResult){
        //check if another book object exists
        if self.notebookExists == true {
            return
        }
        else{
            let node = createBook(hitTestResult: hitTestResult)
            //render book on root
            self.sceneView.scene.rootNode.addChildNode(node)
            self.notebookExists = true
            self.addContent(id: String(notebookID), pageObjs: self.pageObjectArray)
            self.setTime(id: String(notebookID))
            self.tapGestureEnabling()
            self.enableBookButtons()
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
        self.sceneView.scene.rootNode.addChildNode(node)  //render book on root
        self.setTime(id: String(notebookID))
        self.notebookExists = true
        self.tapGestureEnabling()
        self.enableBookButtons()
    }
    
    func setTime(id: String){
        let now = Date()
        let format = DateFormatter()
        format.timeZone = TimeZone.current
        format.dateFormat = "MM-dd-yyyy"
        let dateString = format.string(from: now)
        self.ref.child("notebooks/\(id)").updateChildValues(["LastAccessed":dateString])
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
        textNode.name = "content"
        textNode.containerFrame = CGRect(origin:CGPoint(x: xf, y:yf), size: CGSize(width: 10, height: hght))
        textNode.truncationMode = kCATruncationEnd
        textNode.alignmentMode = kCAAlignmentLeft
        textNode.isWrapped = true
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        textNode.materials = [material]
        let node = createTextNode(text: textNode)
        self.selectedTemplate.addChildNode(node)
        //renderNode(node: node)
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
                if selectedTemplate != nil{
                    let tempNode = selectedTemplate
                    //check to see if the content is a sotrage url - which means its an image.

                    if text.range(of:"firebasestorage.googleapis.com") != nil {
                        if let page = currentPageNode {
                            let url = URL(string: text)
                            URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
                                guard let image = UIImage(data: data!) else {return}
                                let node = SCNNode(geometry: SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0))
                                node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                                node.name = "content"
                                node.position = SCNVector3(0,0, 0.01)
                                self.lastNode.append(node)
                                self.selectedTemplate.addChildNode(node)
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
                else {
                    alertAddTemplate()
                }
            }
            else if template == "double"{
                if selectedTemplate != nil{
                    if topTempNode == selectedTemplate{
                        if text.range(of:"firebasestorage.googleapis.com") != nil {
                            if currentPageNode != nil {
                                let url = URL(string: text)
                                URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
                                    guard let image = UIImage(data: data!) else {return}
                                    let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                                    node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                                    node.position = SCNVector3(0,0, 0.01)
                                    self.lastNode.append(node)
                                   self.selectedTemplate.addChildNode(node)
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
                    else if bottomTempNode == selectedTemplate{
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
                                    //self.bottomTempNode?.addChildNode(node)
                                    self.selectedTemplate.addChildNode(node)
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
                else {
                    alertAddTemplate()
                }

            }
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
            if selectedTemplate != nil{
                if template == "single"{
                    let tempNode = selectedTemplate
                    let node = SCNNode(geometry: SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0))
                    node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                    node.position = SCNVector3(0,0, 0.001)
                    lastNode.append(node)
                    tempNode?.addChildNode(node)
                }
                else if template == "double"{
                    let tempNode = selectedTemplate
                    let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                    node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                    node.position = SCNVector3(0,0, 0.001)
                    lastNode.append(node)
                    tempNode?.addChildNode(node)
                }

            }
            else if template == "double"{
                let tempNode = selectedTemplate
                let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                node.position = SCNVector3(0,0, 0.001)
                lastNode.append(node)
                tempNode?.addChildNode(node)
            }
        }
        else { // no template selected
            alertAddTemplate()
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
        let deleteAction = UIAlertAction(title: "Clear", style: .default) { (result : UIAlertAction) -> Void in
            let loadingAlert = UIAlertController(title: nil, message: "Clearing", preferredStyle: .alert)
            self.present(loadingAlert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.clearBook()
                loadingAlert.dismiss(animated: true, completion: nil)
            })
        }
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func clearNodes(){  // resets all of the current global node variables
        self.currentPageNode = nil
        self.bookNode = nil
        self.selectedTemplate = nil
        self.bottomTempNode = nil
        self.topTempNode = nil
        self.templateNode = nil
        self.notebookExists = false
        self.hitResult = nil
        self.retrievedFlag = false
        self.templateExists = false
    }
    
    func clearBook(){
        //dismiss(animated: true, completion: nil) might delete if this is in the main view controller
        self.bookNode?.removeFromParentNode()
        self.pages.removeAll()
        self.lastNode.removeAll()
        self.clearNodes()
        self.accessToWrite = true;
        self.registerGestures()
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
    
    @IBAction func deletePage(_ sender: Any) {
        self.deletePage()
    }
    
    func deletePage(){
        dismiss(animated: true, completion: nil)
        if accessToWrite == true {
            let alertController = UIAlertController(title: "Confirm Delete Page", message: "Are you sure you want to delete the page ?", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel)
            let deletePageAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                self.currentPageNode?.removeFromParentNode()
                self.ref?.child("notebooks").child(String(self.notebookID)).child(String(self.currentPage)).removeValue()
                self.pages.removeLast()
                self.currentPageNode = self.pages.last
            }
            alertController.addAction(cancelAction)
            alertController.addAction(deletePageAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
        }
    }
    
    func deleteNotebook(book: String){
        dismiss(animated: true, completion: nil)
        if accessToWrite == true {
            dismiss(animated: true, completion: nil)
            let alertController = UIAlertController(title: "Confirm Delete Notebook", message: "Are you sure you want to delete the Notebook ?", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel)
            let deletePageAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                let loadingAlert = UIAlertController(title: nil, message: "Deleting", preferredStyle: .alert)
                self.present(loadingAlert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.ref?.child("notebooks").child(book).removeValue()
                    self.ref?.child("users").child(self.currentProfile).child("notebooks").child(book).removeValue()
                    self.clearBook()
                    loadingAlert.dismiss(animated: true, completion: nil)
                })
            }
            alertController.addAction(cancelAction)
            alertController.addAction(deletePageAction)
            self.present(alertController, animated: true, completion: nil)
            self.notebookExists = false
        }
        else{
            alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
        }
    }

    /*
     -----
     Page Color Delegate Functions
     -----
     */
    
    func pageColor(image: UIImage) {
        if accessToWrite == true {
            if bookNode != nil && currentPageNode != nil {
                for page in pages {
                    page.geometry?.firstMaterial?.diffuse.contents = image
                }
                // maybe an array for all the pages to change all or a single page at a time ?
            }
            else{ //error for if there is no book
                let alertController = UIAlertController(title: "Error", message: "Please add a notebook before adding text", preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    /*
     -----
     book Color Deletegate Funcitons
     -----
     */
    
    func bookColor(imageOne: UIImage, cover: String) {
        if accessToWrite == true {
            bookNode?.geometry?.firstMaterial?.diffuse.contents = imageOne
            ref.child("notebooks/\(notebookID)").updateChildValues(["CoverStyle" : cover])
        }
        else {
            //alet extension
        }
    }
    /*
     -----
     Share Button
     -----
     */
    @IBAction func shareNotebook(){
        if accessToWrite == true {
            //notebook ID of the notebook to share
            if self.notebookID > 0 {
                let id = String(self.notebookID)
                showShareAlert(id: id)
            }
            else {
                showErrorShareAlert()
            }
        }
        else{
            alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
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
            node.name = "Single Template"
            page.addChildNode(node)
            templateNode = node
            templateExists = true
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
            node.name = "Top node"
            node2.name = "Bottom node"
            topTempNode = node
            bottomTempNode = node2
            templateExists = true
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
                 self.selectedTemplate = self.templateNode
                passText(text: content, f: 1)
            }
            else if temp == "double"{
                createPage()
                twoSlotTemplate()
                template = temp
                self.selectedTemplate = self.topTempNode
                passText(text: content, f: 1)
            }
            else if temp == "doubleSecond" {
                template = "double"
                self.selectedTemplate = self.bottomTempNode
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
            if end >= 0{
                for i in 0...end {
                    if (i == 1 && t == "double"){
                        t = "doubleSecond"
                    }
                    addPageWithContent(content: page.content[i], temp: t)
                }
            }
            else {
                print("no book")
            }
        }
        //probably need to also check if shared flag? Dont need to listen for changes on own notebook.
        if self.retrievedFlag {
            //connect listener to notebook to see if anything changes.
            attachEventListeners()
        }
    }
    func attachEventListeners(){
        let postRef = self.ref.child("notebooks/\(notebookID)")
        postRef.observe(.childChanged, with: { (snapshot) -> Void in
            print("something changed")
            print("snapshot key:", snapshot.key)
            print("snapshot value:", snapshot.value)
            print("snapshot children count", snapshot.childrenCount)
            if snapshot.childrenCount == 1 {
                self.handleSingleChildChange(snapshot: snapshot)
            }
            else if snapshot.childrenCount == 2 {
                self.handleDoubleChildChange(snapshot: snapshot)
            }
        })
    }
    func handleSingleChildChange(snapshot: DataSnapshot){
        print("snapshot value from other func:", snapshot.children)
        moveCurrentPage(i: snapshot.key)
        let enumPages = snapshot.children
        while let page = enumPages.nextObject() as? DataSnapshot {
            print(page.value)
            let text = page.value as! String
            selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
            createSlots(xf: -0.5, yf: -8.0, hght: 16, text: text)
        }
    }
    func handleDoubleChildChange(snapshot: DataSnapshot) {
         moveCurrentPage(i: snapshot.key)
        let enumPages = snapshot.children
        while let page = enumPages.nextObject() as? DataSnapshot {
            print(page.value)
            let text = page.value as! String
            //let textNode = currentPageNode?.childNode(withName: "text", recursively: true)
            if (page.key == "content1"){
                //select the top node of current page
                let temp = currentPageNode?.childNode(withName: "Top node", recursively: false);
                self.selectedTemplate = temp
                 selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                 createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
            }
            else if (page.key == "content2"){
                //select the top node of current page
                let temp = currentPageNode?.childNode(withName: "Bottom node", recursively: false);
                self.selectedTemplate = temp
                selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
            }
        }
        //reset ages to last for testing purposes
        currentPageNode = self.pages.last
        
    }
    func moveCurrentPage(i: String){
        if let index = Int(i) {
            //check to see if we need to call right/left swipe here to move pages forward backward.
            currentPageNode = self.pages[index - 1]
            //try to do some animation if needed.
        }
    }
    
    func alertAddTemplate() {
        let alertController = UIAlertController(title: "Error", message: "select a Template before adding content.", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
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
class alertHelper {
    func alert(fromController controller: UIViewController, title: String = "", message: String) {
        let alertController2 = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in}
        alertController2.addAction(cancelAction)
        controller.present(alertController2, animated: true, completion: nil)
    }
}