//
//  ViewController.swift
//  ARNotebook
//
//  Created by AR Notebook on 10/15/17.
//  Copyright © 2017 AR Notebook. All rights reserved.
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
    var cameFromShare: Bool = false
    var pageObjectArray = [Page]()
    var selectedTemplate : SCNNode!
    var previousSelectedTemplate :SCNNode?
    var accessToWrite : Bool = true
    var alert = alertHelper()
    var prevVC: retrieveViewController!
    var contentExist : Bool = false
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
        self.longPressGestures()
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
    @IBOutlet weak var openButton: UIButton!
    
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
    
    /*
     -----
     Instructions for buttons
     -----
     */
    
    func longPressGestures(){
        let longDeleteGesture = UILongPressGestureRecognizer(target: self, action: #selector(deleteInstruction(_:)))
        self.deletePageButton.addGestureRecognizer(longDeleteGesture)
        let longDismissGesture = UILongPressGestureRecognizer(target: self, action: #selector(dismissInstruction(_:)))
        self.dismissButton.addGestureRecognizer(longDismissGesture)
        let longShareGesture = UILongPressGestureRecognizer(target: self, action: #selector(shareInstruction(_:)))
        self.shareButton.addGestureRecognizer(longShareGesture)
        let longUndoGesture = UILongPressGestureRecognizer(target: self, action: #selector(undoInstruction(_:)))
        self.undoButton.addGestureRecognizer(longUndoGesture)
        let longAddPageGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPageInstruction(_:)))
        self.addPageButton.addGestureRecognizer(longAddPageGesture)
        let longEditGesture = UILongPressGestureRecognizer(target: self, action: #selector(editInstruction(_:)))
        self.editButton.addGestureRecognizer(longEditGesture)
        let longInsertGesture = UILongPressGestureRecognizer(target: self, action: #selector(insertInstruction(_:)))
        self.insertButton.addGestureRecognizer(longInsertGesture)
        let longOpenGesture = UILongPressGestureRecognizer(target: self, action: #selector(openInstruction(_:)))
        self.openButton.addGestureRecognizer(longOpenGesture)
    }
    
    @objc func deleteInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "This button will PERMANENTLY delete the current page.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func dismissInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "This button will dismiss the current notebook. It will NOT delete it permanently", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func shareInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "Press this button to share the current notebook. Note that read means the other person cannot edit it while write means they have all editing permissions.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func undoInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "This button will undo the last action. This will not work on items you have not added yourself, such as when you retrieve a notebook. If you retrieve a notebook, add an item, and then undo, it will revert that change only.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func addPageInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "This button will add a new page at the end of your notebook. If you choose a single slot, it will add a new page with only one slot for adding images or text. If you select a two-slot, it will give you two slots. You must tap on the slot that you want to update. The slot will be highlighted to confirm that you tapped on it.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func editInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "This button will let you edit the cover style of your notebook as well as the color of the pages.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func insertInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "This button will let you insert text or images to a slot you have selected. If you tap images, you will be redirected to your photo gallery. If you tap on the keyboard, you will be allowed to type in what you want so long as it is under 500 characters. The clipboard button will paste what you have on your clipboard to the slot you have selected.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func openInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "This button will open a list of previous notebooks you have created. You can also log out of AR Notebook in this menu.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
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
            if templateExists == true {
                if let last = (lastNode.last){
                    last.removeFromParentNode()
                    lastNode.removeLast()
                }
            }
            else {
                alert.alert(fromController: self, title: "No Template Selected", message: "select a Template before adding content.")
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
        let page = currentPageNode
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
        if self.notebookExists == true || self.retrievedFlag == true  {
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
            addPageNum()
            self.enablePageButtons()
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
    func setPagesForSwipe(previous: Int) -> SCNNode{
        var offset = 0.0
        let turnPage = pages[previous]
        if(previous != 0){
            offset = Double(previous) * 0.02;
        }
        turnPage.position = SCNVector3(-0.9, 0.021 + offset, 0)
        return turnPage
    }
    func leftSwipeAnimation(turnPage: SCNNode, currentPointer: Int){
        var i = currentPointer
        var x = Int(turnPage.name!)!
        turnPage.pivot = SCNMatrix4MakeTranslation(-0.9, 0, 0)
        turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 1))
        turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 0)) //rotate the rest of the way without animation
        x -= 1
        repeat {
            currentPageNode?.isHidden = true;
            i -= 1
            currentPageNode = self.pages[i]
        } while x != i
        currentPageNode = turnPage
        currentPage = Int((currentPageNode?.name)!)!
    }
    func rightSwipeAnimation(turnPage: SCNNode, currentPointer: Int){
        var i = currentPointer
        let x = Int(turnPage.name!)!
        turnPage.pivot = SCNMatrix4MakeTranslation(-0.9, 0, 0)
        turnPage.runAction(SCNAction.rotate(by: -.pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 1))
        turnPage.runAction(SCNAction.rotate(by: .pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 0)) //rotate the rest of the way without animation
        while x != i  {
            turnPage.isHidden = false
            i += 1
        }
        currentPageNode = turnPage
        currentPage = Int((currentPageNode?.name)!)!
    }
    @IBAction func rightSwipe(_ sender: Any) {
        //if there is more than one page and the current page node is the last one in the array turn the page backward?
        if (pages.count > 1 && (currentPage <= Int(pages.count - 1))) {
            let i = Int((currentPageNode?.name)!)
            let previous = i!;
            let turnPage = setPagesForSwipe(previous: previous)
            rightSwipeAnimation(turnPage: turnPage, currentPointer: currentPage)
            templateReset()
        }
    }
    
    @IBAction func leftSwipe(_ sender: Any) {
        //if there is more than one page and the current page node is the last one in the array turn the page forward
        if (pages.count > 0 && currentPage > 1) {
            let  i = Int((currentPageNode?.name)!)
            let previous = i! - 2;
            let turnPage = setPagesForSwipe(previous: previous)
            leftSwipeAnimation(turnPage: turnPage, currentPointer: i!)
            templateReset()
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
        if pages.isEmpty == false{
            if self.templateExists == true {
                self.hitResult2 = hitTest.first
                let node = hitTest.first?.node
                if node == currentPageNode?.childNode(withName: "Top node", recursively: false){
                    self.selectedTemplate = node
                    print("Top node selected")
                    templateSelectColorChange(node: node!)
                    print(node)
                }
                else if node == currentPageNode?.childNode(withName: "Bottom node", recursively: false){
                    self.selectedTemplate = node
                    print("Bottom node selected")
                    templateSelectColorChange(node: node!)
                    print(node)
                }
                else if node == currentPageNode?.childNode(withName: "Single node", recursively: false){
                    self.selectedTemplate = node
                    print("Single template selected")
                    templateSelectColorChange(node: node!)
                    print(node)
                }
                else{
                    print("cant find a node")
                    print(node)
                }
            }
        }
    }
    func templateSelectColorChange(node :SCNNode){
        templateDeselectColorChange()
        if node == selectedTemplate{
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.previousSelectedTemplate = node
        }
    }
    
    func templateReset(){
        
        selectedTemplate?.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        selectedTemplate = nil
        
    }
    
    func templateDeselectColorChange(){
        previousSelectedTemplate?.geometry?.firstMaterial?.diffuse.contents = UIColor.white
    }
    
    func rerenderContent(){
        if selectedTemplate == templateNode{
            selectedTemplate.removeFromParentNode()
            oneSlotTemplate()
            let temp = currentPageNode?.childNode(withName: "Single node", recursively:false)
            self.selectedTemplate = temp
        }
        if selectedTemplate == topTempNode{
            selectedTemplate.removeFromParentNode()
            createTopNode()
            let temp = currentPageNode?.childNode(withName: "Top node", recursively:false)
            self.selectedTemplate = temp
        }
        if selectedTemplate == bottomTempNode{
            selectedTemplate.removeFromParentNode()
            createBottomNode()
            let temp = currentPageNode?.childNode(withName: "Bottom node", recursively:false)
            self.selectedTemplate = temp
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
        lastNode.append(node)
        contentExist = true
        selectedTemplate?.addChildNode(node)
        previousSelectedTemplate?.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        selectedTemplate = nil
    }
    func downloadImage(i: Int, w: CGFloat, h: CGFloat, text: String, tmp: String){
        let url = URL(string: text)
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            guard let image = UIImage(data: data!) else {return}
            let node = SCNNode(geometry: SCNBox(width: w, height: h, length: 0.001, chamferRadius: 0))
            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
            node.name = "content"
            node.position = SCNVector3(0,0, 0.01)
            self.lastNode.append(node)
            let page = self.pages[i-1]
            page.childNode(withName: tmp, recursively: false)?.addChildNode(node)
        }).resume()
        return
    }
    /*
     -----
     Insert View Controller Callback Functions
     -----
     */
    
    func passText(text: String, i: Int = 0) {
        if bookNode != nil && currentPageNode != nil {
            if selectedTemplate != nil {
                if contentExist {
                    if selectedTemplate == currentPageNode?.childNode(withName: "Single node", recursively: true){
                        selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                        createSlots(xf: -0.5, yf: -8.0, hght: 16, text: text)
                    }
                    else {
                        selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                        createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                    }
                }
                if template == "single"{
                    //check to see if the content is a sotrage url - which means its an image.
                    if text.range(of:"firebasestorage.googleapis.com") != nil {
                        downloadImage(i: i, w: 1.2, h: 1.6, text: text, tmp: "Single node")
                    }
                    else{
                        createSlots(xf: -0.5, yf: -8.0, hght: 16, text: text)
                    }
                }
                else if template == "double"{
                    if topTempNode == selectedTemplate{
                        if text.range(of:"firebasestorage.googleapis.com") != nil {
                            downloadImage(i: i, w: 1.2, h: 0.7, text: text, tmp: "Top node")
                        }
                        else{
                            if contentExist {
                                if selectedTemplate == currentPageNode?.childNode(withName: "Top node", recursively: true){
                                    selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                                    createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                                }
                                else{
                                    createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                                }
                            }
                        }
                    }
                    else if bottomTempNode == selectedTemplate {
                        if text.range(of:"firebasestorage.googleapis.com") != nil {
                            downloadImage(i: i, w: 1.2, h: 0.7, text: text, tmp: "Bottom node")
                        }
                        else{
                            if contentExist {
                                if selectedTemplate == currentPageNode?.childNode(withName: "Bottom node", recursively: true){
                                    selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                                    createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                                }
                                else{
                                    createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                                }
                            }
                        }
                    }
                }
            }
            else {
               alert.alert(fromController: self, title: "No Template Selected", message: "Select a Template before adding content.")
            }
        }
    }
    // functions to pass the image through to the VIEW CONTROLLER
    func passImage(image: UIImage) {
        dismiss(animated: true, completion: nil)
        if currentPageNode != nil {
            if selectedTemplate != nil{
                    if contentExist == true {
                        rerenderContent()
                        let tempNode = selectedTemplate
                        let node = SCNNode(geometry: SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0))
                        node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                        node.name = "content"
                        node.position = SCNVector3(0,0, 0.001)
                        lastNode.append(node)
                        tempNode?.addChildNode(node)
                        contentExist = true
                    }
                    else if template == "single" {
                        let tempNode = selectedTemplate
                        let node = SCNNode(geometry: SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0))
                        node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                        node.name = "content"
                        node.position = SCNVector3(0,0, 0.001)
                        lastNode.append(node)
                        tempNode?.addChildNode(node)
                        contentExist = true
                    }
                else if template == "double"{
                    if selectedTemplate == topTempNode{
                        if contentExist == true {
                            rerenderContent()
                            let tempNode = selectedTemplate
                            let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                            node.name = "content"
                            node.position = SCNVector3(0,0, 0.001)
                            lastNode.append(node)
                            tempNode?.addChildNode(node)
                            contentExist = true
                        }
                        else{
                            let tempNode = selectedTemplate
                            let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                            node.name = "content"
                            node.position = SCNVector3(0,0, 0.001)
                            lastNode.append(node)
                            tempNode?.addChildNode(node)
                            contentExist = true
                        }
                    }
                    else if selectedTemplate == bottomTempNode{
                        if contentExist == true {
                            rerenderContent()
                            let tempNode = selectedTemplate
                            let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                            node.name = "content"
                            node.position = SCNVector3(0,0, 0.001)
                            lastNode.append(node)
                            tempNode?.addChildNode(node)
                            contentExist = true
                        }
                        else{
                            let tempNode = selectedTemplate
                            let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
                            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
                            node.name = "content"
                            node.position = SCNVector3(0,0, 0.001)
                            lastNode.append(node)
                            tempNode?.addChildNode(node)
                            contentExist = true
                        }
                    }
                }
            }
        }
        else { // no template selected
            alert.alert(fromController: self, title: "No Template Selected", message: "select a Template before adding content.")
        }
        selectedTemplate = nil
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
        self.contentExist = false
    }
    
    func clearBook(){
        //remove the listeners from firebase
        if self.cameFromShare{
            ref.removeAllObservers()
        }
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
        if(accessToWrite){
            self.deletePage()
        }
        else{
             alert.alert(fromController: self, title:"No Write Access", message:"You are viewing a shared notebook that you do not have write access to. Please continue to use this notebook as read only.")
        }
    }
    
    func deletePage(){
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
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel)
        alertController.addAction(addReadAccess)
        alertController.addAction(addWriteAccess)
        alertController.addAction(cancelAction)
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
            node.name = "Single node"
            page.addChildNode(node)
            templateNode = node
            templateExists = true
        }
    }
    
    func twoSlotTemplate(){
        createTopNode()
        createBottomNode()
    }
    
    func createTopNode(){
        if let page = currentPageNode{
            let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node.position = SCNVector3(0,0.4, 0.001)
            node.name = "Top node"
            currentPageNode?.addChildNode(node)
            topTempNode = node
            templateExists = true
        }
    }
    
    func createBottomNode(){
        let node = SCNNode(geometry: SCNBox(width: 1.2, height: 0.7, length: 0.001, chamferRadius: 0))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node.position = SCNVector3(0,-0.4, 0.001)
        node.name = "Bottom node"
        currentPageNode?.addChildNode(node)
        bottomTempNode = node
        templateExists = true
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
                guard let index = currentPageNode?.name else {return}
                passText(text: content, i: Int(index)!)
            }
            else if temp == "double"{
                createPage()
                twoSlotTemplate()
                template = temp
                self.selectedTemplate = self.topTempNode
                guard let index = currentPageNode?.name else {return}
                passText(text: content, i: Int(index)!)
            }
            else if temp == "doubleSecond" {
                template = "double"
                guard let index = currentPageNode?.name else {return}
                self.selectedTemplate = self.bottomTempNode
                passText(text: content, i: Int(index)!)
            }
        }
        else {
            //error no book
        }
    }
    
    func addContent(id: String, pageObjs: [Page]) {
        self.notebookExists = true
        self.notebookID = Int(id)!
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
        if self.retrievedFlag && self.cameFromShare {
            //connect listener to notebook to see if anything changes.
            attachEventListeners()
            
        }
    }
    func attachEventListeners(){
        let postRef = self.ref.child("notebooks/\(self.notebookID)")
        postRef.observe(.childChanged, with: { (snapshot) -> Void in
            if snapshot.childrenCount == 2 {
                self.handleSingleChildChange(snapshot: snapshot)
            }
            else if snapshot.childrenCount == 3 {
                self.handleDoubleChildChange(snapshot: snapshot)
            }
        })
    }
    func handleSingleChildChange(snapshot: DataSnapshot){
        if(Int(snapshot.key) != currentPage) {
            if (Int(snapshot.key)! <= currentPage){
                moveCurrentPage(i: snapshot.key)
            }
            else{
                createPage()
                oneSlotTemplate()
                template = "single"
            }
        }
        let enumPages = snapshot.children
        while let page = enumPages.nextObject() as? DataSnapshot {
            guard let i = currentPageNode?.name else {return}
            if(page.key == "content1") {
                let text = page.value as! String
                selectedTemplate = currentPageNode?.childNode(withName: "Single node", recursively: true)
                selectedTemplate.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                if text.range(of:"firebasestorage.googleapis.com") != nil {
                    downloadImage(i: Int(i)!, w: 1.2, h: 07, text: text, tmp: "Single node")
                }
                else{
                    createSlots(xf: -0.5, yf: -8.0, hght: 16, text: text)
                }
            }
        }
    }
    func handleDoubleChildChange(snapshot: DataSnapshot) {
        if(Int(snapshot.key) != currentPage) {
            if(Int(snapshot.key)! <= currentPage) {
                moveCurrentPage(i: snapshot.key)
            }
            else{
                createPage()
                createTopNode()
                createBottomNode()
                template = "double"
            }
        }
        let enumPages = snapshot.children
        while let page = enumPages.nextObject() as? DataSnapshot {
            let text = page.value as! String
             guard let i = currentPageNode?.name else {return}
            //let textNode = currentPageNode?.childNode(withName: "text", recursively: true)
            if (page.key == "content1"){
                //select the top node of current page
                let temp = currentPageNode?.childNode(withName: "Top node", recursively: false);
                self.selectedTemplate = temp
                selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                if text.range(of:"firebasestorage.googleapis.com") != nil {
                    downloadImage(i: Int(i)!, w: 1.2, h: 0.7, text: text , tmp: "Top node")
                }
                else{
                    createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                }
            }
            else if (page.key == "content2"){
                //select the top node of current page
                let temp = currentPageNode?.childNode(withName: "Bottom node", recursively: false);
                self.selectedTemplate = temp
                selectedTemplate?.childNode(withName: "content", recursively: true)?.removeFromParentNode()
                if text.range(of:"firebasestorage.googleapis.com") != nil {
                    downloadImage(i: Int(i)!, w: 1.2, h: 0.7, text: text, tmp: "Bottom node")
                }
                else{
                    createSlots(xf: -0.5, yf: -3.5, hght: 7, text: text)
                }
            }
        }
    }
    func moveCurrentPage(i: String){
        if let index = Int(i) {
            //check to see if we need to call right/left swipe here to move pages forward backward.
            let i = index - 1
            let testPage = self.pages[i]
            let turnPage = setPagesForSwipe(previous: i)
            guard let currentPageIndex = Int((currentPageNode?.name!)!) else {return}
            guard let turnPageIndex = Int(testPage.name!) else {return}
            if turnPageIndex < currentPageIndex {
                //right swipe
                leftSwipeAnimation(turnPage: turnPage, currentPointer: currentPageIndex)
            }
            else{
                rightSwipeAnimation(turnPage: turnPage, currentPointer: currentPageIndex)
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
        let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
            if !(controller is ViewController) {
                controller.dismiss(animated: true, completion: nil)
            }
        }
        alertController2.addAction(cancelAction)
        controller.present(alertController2, animated: true, completion:nil)
    }
}
