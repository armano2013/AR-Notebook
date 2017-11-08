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
    
    @IBAction func undo(_ sender: Any) {
        if let last = (lastNode.last){
            last.removeFromParentNode()
            lastNode.removeLast()
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
            lastNode.append(node)
            page.addChildNode(node)
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
            
            let offset = Float(pages.count) * Float(0.01);
            //@DISCUSS should we add pages from the top or bottom?? if bottom needs to fix paging.
            pageNode.position = SCNVector3(bookNode.position.x, 0.05 + offset, bookNode.position.z)
            pageNode.eulerAngles = SCNVector3(-90.degreesToRadians, 0, 0)
            pages.append(pageNode)
            pageNode.name = String(pages.count) //minus one so 0 index array  why??
            currentPageNode = pageNode
            bookNode.addChildNode(pageNode)
            currentPage = Int((currentPageNode?.name)!)!
        }
        else{//book error
            let alertController = UIAlertController(title: "Error", message: "Please add a notebook or page before adding text", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
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
            turnPage.isHidden = false
            currentPageNode = turnPage
            currentPage = Int((currentPageNode?.name)!)!
        }
    }
    
    // tap outside any popup to dismiss
    //@FIXME with Facebook Enabled we need to catch this touch so that it doesnt dismiss all the way back to auth view controller
    //should be possible with an if statement??
    /*override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       dismiss(animated: true, completion: nil)
    }*/
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            self.addBook(hitTestResult: hitTest.first!)
        }
    }

    func addBook(hitTestResult: ARHitTestResult) {
        //commenting out since we moved the facebook detection for now
        currentProfile = (self.nameDelegate?.profileName!)!
        
        let scene = SCNScene(named: "art.scnassets/Book.dae")
        let node = (scene?.rootNode.childNode(withName: "Book_", recursively: false))!
        node.name = "Book"

        let coverMaterial = SCNMaterial()
        coverMaterial.diffuse.contents = UIImage(named: "purpleRain")
        coverMaterial.locksAmbientWithDiffuse = true
        node.geometry?.firstMaterial = coverMaterial
        //coordinates from the hit test give us the plane anchor to put the book ontop of, coordiantes are stored in the 3rd column.
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        bookNode = node //assign the book node to the global variable for book node
        //check if another book object exists
        if self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) != nil {
            //this means theres already a book placed in the scene.. what do we want to do here??
            //user should only have one book open at a time.
        }
        else{
            //add book to database
            saveBook(node: node)
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
            let textNode = SCNText(string: text, extrusionDepth: 0.1)
            textNode.font = UIFont(name: "Arial", size:1)
            textNode.containerFrame = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))
            textNode.truncationMode = kCATruncationEnd
            textNode.alignmentMode = kCAAlignmentLeft
            textNode.isWrapped = true
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.black
            textNode.materials = [material]
            let node = createTextNode(text: textNode)
            renderNode(node: node)
//            let page = currentPageNode
//            let text = SCNText(string: getClipboard(), extrusionDepth: 0.1)
//
//            //  text.containerFrame = CGRect(origin: .zero, size: CGSize(width: 1.4, height: 1.8))
//            text.isWrapped = true
//            let material = SCNMaterial()
//            if(pages.count % 2 == 0){
//                material.diffuse.contents = UIColor.black
//            }
//            else {
//                material.diffuse.contents = UIColor.blue
//            }
//            text.materials = [material]
//            let node = SCNNode()
//            node.geometry = text
//            node.scale = SCNVector3Make(0.01, 0.01, 0.01)
//
//            /* credit: https://stackoverflow.com/questions/44828764/arkit-placing-an-scntext-at-a-particular-point-in-front-of-the-camera
//             let (min, max) = node.boundingBox
//
//             let dx = min.x + 0.5 * (max.x - min.x)
//             let dy = min.y + 0.5 * (max.y - min.y)
//             let dz = min.z + 0.5 * (max.z - min.z)
//             node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
//             */
//            node.position = SCNVector3(-0.7, 0.0, 0.05)
//            //node.eulerAngles = SCNVector3(0, 180.degreesToRadians, 0) //for some reason text is added backward
//            page?.addChildNode(node)
        }
        else{ //error for if there is no book
            let alertController = UIAlertController(title: "Error", message: "Please add a notebook or page before adding text", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    // functions to pass the image through to the VIEW CONTROLLER
    func passImage(image: UIImage) {
        dismiss(animated: true, completion: nil)
        if let page = currentPageNode {
            let node = SCNNode()
            node.geometry = SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
            node.position = SCNVector3(0,0, 0.001)
            lastNode.append(node)
            page.addChildNode(node)
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
    func addPage(string: String){
        dismiss(animated: true, completion: nil)
        if bookNode == nil {
            let alertController = UIAlertController(title: "Error", message: "Please add a notebook before adding a page", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else{
                createPage()
            
                //@ARTUR: Fix this so that render page nums dont use render node
                //Probably can extract method since we create page numbs in 2 places
                let pageNumberNode = SCNText(string: String(self.currentPage), extrusionDepth: 0.1)
                pageNumberNode.isWrapped = true
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.black
                pageNumberNode.materials = [material]
                let node = createTextNode(text: pageNumberNode)
                node.scale = SCNVector3(x: 0.006, y:0.006, z:0.006)
                node.position = SCNVector3(0.55, -0.888, 0.001)
            
                //@ ARTUR: Fix this so that render page nums dont use render node
                //Probably can extract method since we create page numbs in 2 places
                renderNode(node: node)
            }
    }
    func saveBook(node: SCNNode) {
        //generate a unique id for the notebook
        guard let profile = currentProfile else {print("error"); return}
        let id = self.generateUniqueNotebookID(node: node)
        self.notebookID = id
        let childUpdates = ["users/\((profile))/notebooks/\(id)": id]
        
        self.ref.updateChildValues(childUpdates as Any as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
            if  err != nil{
                print(err as Any)
                return
            }
            return
        })
    }
    
    func generateUniqueNotebookID(node: SCNNode) ->Int {
        return ObjectIdentifier(node).hashValue
    }
    
    /*
     -----
     Delete Deletegate Funcitons
     -----
     */
    
    func deletePage(){
        dismiss(animated: true, completion: nil)
        if currentPageNode == nil && pages == nil {
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
    
    func bookColor(imageOne: UIImage) {
        bookNode?.geometry?.firstMaterial?.diffuse.contents = imageOne
    }
    /*
     -----
     Retrieve delegate function
     -----
     */
    func addPageWithContent(content: String){
            if let bookNode = self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) {
                createPage()
                //@ARTUR: Fix this so that render page nums dont use render node
                //This is the second place we generate page numbers- put it in a method.
                let pageNumberNode = SCNText(string: String(self.currentPage), extrusionDepth: 0.1)
                pageNumberNode.isWrapped = true
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.black
                pageNumberNode.materials = [material]
                let node = createTextNode(text: pageNumberNode)
                node.scale = SCNVector3(x: 0.006, y:0.006, z:0.006)
                node.position = SCNVector3(0.55, -0.888, 0.001)
                renderNode(node: node)
                
                //check to see if the content is a sotrage url - which means its an image.
                if content.range(of:"firebasestorage.googleapis.com") != nil {
                    if let page = currentPageNode {
                        let url = URL(string: content)
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
                //if its not a url then its just regular text.
                else{
                    let textNode = SCNText(string: content, extrusionDepth: 0.1)
                    textNode.materials = [material]
                    let text = createTextNode(text: textNode)
                    renderNode(node: text)
                }
        }
        else{
         //error no book
        }
    }
    
    func addContent(numPages: Int, content: [String]) {
        dismiss(animated: true, completion: nil)
        let end = numPages - 2
        for i in 0...end {
            addPageWithContent(content: content[i])
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


