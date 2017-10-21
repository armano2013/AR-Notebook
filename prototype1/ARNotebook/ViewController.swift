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

class ViewController:  UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate {
    /*
     -----
     Global Variables
     -----
     */
    
    @IBOutlet weak var UserInputText: UITextField!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var bookNode: SCNNode?
    let imagePicker = UIImagePickerController()
    var currentPageNode : SCNNode? //points to the current page, assigned in page turns
    var lastNode = [SCNNode]() //used to for undo function to delete the last input node
    var pages = [SCNNode]() //stores page nodes, can get page num from here
    
    var ref: DatabaseReference!
    var myStorage: Storage!

    var storageRef: StorageReference!
    /*
     -----
     Generic Session Setup
     -----
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        myStorage = Storage.storage()
        storageRef = myStorage?.reference()
        
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
        UserInputText.delegate = self as? UITextFieldDelegate
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
        if !(UserInputText.text?.isEmpty)! {
            let keyText = SCNText(string: UserInputText.text, extrusionDepth: 0.1)
            let node = createTextNode(text: keyText)
            renderNode(node: node)
                  // Uploading text to database
            let dbString = UserInputText.text
            let userID = Auth.auth().currentUser?.uid
            ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in 
            let textString = ["Update Text":dbString]
            let childUpdates = ["users/\(userID)/notebook/page": textString]
            
            self.ref.updateChildValues(childUpdates as Any as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                if  err != nil{
                    print(err as Any)
                    return
                }
                print("text update successful")
            })
            
        }){ (error) in
            print(error.localizedDescription)
          }
        }
        else {
            let alertController = UIAlertController(title: "Error", message: "You did not enter any text.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }

    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateText(self)
        textField.resignFirstResponder()
        return true
    }
    //this function will shutdown the keyboard when touch else where
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this ends the key boards
        self.view.endEditing(true)
    }
    
    @IBAction func undo(_ sender: Any) {
        if let last = (lastNode.last){
            last.removeFromParentNode()
            lastNode.removeLast()
        }
        else {
            print("no last")
        }
    }
    
    // limit the text characters to be less than 140
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let startingLength = UserInputText.text?.characters.count ?? 0
        let lengthToAdd = string.characters.count
        let lengthToReplace = range.length
        
        let newLength = startingLength + lengthToAdd - lengthToReplace
        
        return newLength <= 140
    }
    
    func createTextNode(text: SCNText) -> SCNNode {
        let material = SCNMaterial()
        
        material.diffuse.contents = UIColor.red
        text.materials = [material]
        let node = SCNNode();
        node.geometry = text
        node.scale = SCNVector3(x: 0.01, y:0.01, z:0.01)
        node.position = SCNVector3(-0.7, 0.0, 0.5)
        return node;
    }
    func renderNode(node: SCNNode) {
        let page = currentPageNode
        lastNode.append(node)
        page?.addChildNode(node)
    }

    @IBAction func addText(_ sender: Any) {
        let page = currentPageNode
        let text = SCNText(string: getClipboard(), extrusionDepth: 0.1)
        //adding clipboard to database
        let dbClipboard = getClipboard()
        let userID = String(describing: Auth.auth().currentUser?.uid)
        ref.child("users").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let clipboardString = ["Update Clipboard":dbClipboard]
            let childUpdates = ["users/\(userID)/notebook/page": clipboardString]
            
            self.ref.updateChildValues(childUpdates as Any as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                if  err != nil{
                    print(err as Any)
                    return
                }
                print("clipboard successful")
            })
            
        }) { (error) in
            print(error.localizedDescription)
        }
        text.isWrapped = true
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        text.materials = [material]
        let node = SCNNode()
        node.geometry = text
        node.scale = SCNVector3Make(0.01, 0.01, 0.01)
        node.position = SCNVector3(-0.7, 0.0, 0.05)
        page?.addChildNode(node) // add to screen
        
        lastNode.append(node) //add for undo
    }

    @IBAction func chooseIMG(_ sender: Any) {
       if bookNode != nil {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true)
        }
        else{ //error for if there is no book
            let alertController = UIAlertController(title: "Error", message: "Please add a notebook before choosing an image", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let page = currentPageNode {
          if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
              //send picked image to the database
              let userID = String(describing: Auth.auth().currentUser?.uid)
              let imageRef = storageRef?.child("images")
              let fileRef = imageRef?.child((userID))

              var data = UIImageJPEGRepresentation(pickedImage, 1)! as NSData
              //normally would have your error handling; in this case we just do a return
              let dataInfo = fileRef?.putData(data as Data, metadata: nil){
                  (metadata, error) in guard metadata != nil else {

                      print("There was an error")
                      return
                    }
                  //happens AFTER the completion of the putData() and est of your program will run while this does it's thing
                  // https://firebase.google.com/docs/storage/ios/upload-files?authuser=0
                  print(metadata?.downloadURLs as Any)
                  guard let imageURL =  metadata?.downloadURLs?.first?.absoluteString else { fatalError() }

                  self.ref.child("users").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
                      let urlString = ["image url":imageURL]
                      let childUpdates = ["users/\(userID)/notebook/page": urlString]
                      self.ref.updateChildValues(childUpdates as Any as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                          if  err != nil{
                              print(err as Any)
                              return
                          }
                          print("image url successful")
                      })

                  }){ (error) in
                      print(error.localizedDescription)
                  }
              }
             let node = SCNNode()
            node.geometry = SCNBox(width: 1.2, height: 1.6, length: 0.001, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [pickedImage], duration: 0)
            node.position = SCNVector3(0,0, 0.01)
            page.addChildNode(node)
          }
        }
        else{ //error for if there is no page
            dismiss(animated: true, completion: nil)
            let alertController = UIAlertController(title: "Error", message: "Please add a page before adding an image", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel)
            let addPageAction = UIAlertAction(title: "Add Page", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                self.addPage(self)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(addPageAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
        
    func getClipboard() -> String{
        let pasteboard: String? = UIPasteboard.general.string
        if let string = pasteboard {
            return string
            //update database here
        }
        else{ //error for if there is nothing on the clipboard
            dismiss(animated: true, completion: nil)
            let alertController = UIAlertController(title: "Error", message: "Your Clipboard is empty", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
            }
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
            return ""
        }
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
            //issues with y position here, the page isnt placed right ontop of the book
          
           let offset = Float(pages.count) * Float(0.01);
            //@DISCUSS should we add pages from the top or bottom?? if bottom needs to fix paging.
            pageNode.position = SCNVector3(bookNode.position.x, 0.05 + offset, bookNode.position.z)
            pageNode.eulerAngles = SCNVector3(-90.degreesToRadians, 0, 0)
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
    //updated cover for only 2D
//    func addBook(hitTestResult: ARHitTestResult) {
//        let scene = SCNScene()
//        let node = SCNNode(geometry: SCNBox(width: 1.4, height: 1.8, length:0.001, chamferRadius: 0.0))
//        node.name = "Book"
//
//        let coverMaterial = SCNMaterial()
//        coverMaterial.diffuse.contents = UIImage(named: "BookCover(Ancient)_COLOR")
//        coverMaterial.locksAmbientWithDiffuse = true
//        node.geometry?.firstMaterial = coverMaterial
//        //coordinates from the hit test give us the plane anchor to put the book ontop of, coordiantes are stored in the 3rd column.
//        let transform = hitTestResult.worldTransform
//        let thirdColumn = transform.columns.3
//        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
//        bookNode = node //assign the book node to the global variable for book node
//        //check if another book object exists
//        if self.sceneView.scene.rootNode.childNode(withName: "Book", recursively: true) != nil {
//            //this means theres already a book placed in the scene.. what do we want to do here??
//            //user should only have one book open at a time.
//        }
//        else{
//            self.sceneView.scene.rootNode.addChildNode(node)
//
//        }
    //}
    // original 3d model
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
        bookNode = node //assign the book node to the global variable for book node
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
// functions to pass the image through to the VIEW CONTROLLER
    func passImage(image: UIImage) {
        //let page = currentPageNode
        let node = SCNNode(geometry: SCNBox(width: 1.4, height: 1.8, length:0.001, chamferRadius: 0.0))
        node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [image], duration: 0)
        node.position = SCNVector3(-0.7, 0.0, 0.05)
        self.sceneView.scene.rootNode.addChildNode(node)
        
    }
}
//converts degrees to radians, since objects are oriented according to radians
//credit to udemy video
extension Int {
    var degreesToRadians: Double {return Double(self) * .pi/180}
}
