//
//  insertViewController.swift
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

protocol insertDelegate {
    var currentPage: Int {get set}
    func passImage (image :UIImage)
    func passingClip(text: String)
}

class insertViewController: UIViewController ,UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var delegate : insertDelegate?
    
    var ref: DatabaseReference! //calling a reference to the firebase database
    var storageRef: StorageReference! //calling a reference to the firebase storage
    
    @IBOutlet weak var Insert: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    @IBAction func addClipboardText(_ sender: Any) {
        let text = getClipboard()
        delegate?.passingClip(text: text)
        
        //adding clipboard to database
        /*let dbClipboard = getClipboard()
        let userID = String(describing: Auth.auth().currentUser?.uid)
        ref.child("users").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let clipboardString = ["Update Clipboard":dbClipboard]
            let childUpdates = ["users/\(userID)/notebook/page " + "\(self.delegate?.currentPage ?? nil)": clipboardString]
            
            self.ref.updateChildValues(childUpdates as Any as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                if  err != nil{
                    print(err as Any)
                    return
                }
                print("clipboard successful")
            })
            let pageOrder = (self.ref.child("users/\(userID)/notebook/page " + "\(self.delegate?.currentPage)").child((Auth.auth().currentUser?.uid)!)).queryOrdered(byChild: "page " + "\(self.delegate?.currentPage)")

            
        }) { (error) in
            print(error.localizedDescription)
        }*/
    }
    @IBAction func chooseGalleryImage(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        image.allowsEditing = false
        
        self.present(image, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
          dismiss(animated: true, completion: nil)
        
        /*
         
         Coppied DB Fucntion from view controller:
         ------
         
         if let page = currentPageNode {
         if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
         //send picked image to the database
         dismiss(animated: true, completion: nil)
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
         let childUpdates = ["users/\(userID)/notebook/page " + "\(self.currentPage)": urlString]
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
         let pageOrder = (self.ref.child("users/\(userID)/notebook/page " + "\(self.currentPage)").child((Auth.auth().currentUser?.uid)!)).queryOrdered(byChild: "page " + "\(self.currentPage)")
         */
        if let imageOne = info[UIImagePickerControllerOriginalImage] as? UIImage{
            delegate?.passImage(image: imageOne)
        }
        else{
            
            // error message
        }
    }
    
}

