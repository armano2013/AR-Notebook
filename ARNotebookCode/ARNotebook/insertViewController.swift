//
//  insertViewController.swift
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


protocol insertDelegate {
    var currentProfile: String!  {get set}
    var currentPage: Int {get set}
    var notebookID : Int { get set}
    var selectedTemplate: SCNNode! {get set}
    func passImage (image: UIImage)
    func passText(text: String,  i: Int)
    var accessToWrite: Bool {get set}
}


class insertViewController: UIViewController ,UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate  {
    /*
     -----
     Global Variables
     -----
     */
    var delegate : insertDelegate?
    var ref: DatabaseReference! //calling a reference to the firebase database
    var storageRef: StorageReference! //calling a reference to the firebase storage
    @IBOutlet weak var UserInputText: UITextField!
    @IBOutlet var textFieldBottomConstraint: NSLayoutConstraint!
     var alert = alertHelper()
    
    /*
     -----
     Generic Set Up
     -----
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()
        // Do any additional setup after loading the view.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(dissmiss)))
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        self.UserInputText.delegate = self

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // limit the text characters to be less than 500
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool { //Swift 3 to Swift 4 String is Collection type so you can directly use count on String.
        let startingLength = UserInputText.text?.count ?? 0
        let lengthToAdd = string.count
        let lengthToReplace = range.length
        let newLength = startingLength + lengthToAdd - lengthToReplace
        return newLength <= 500
    }

    /*
     -----
     Insert View Controller - Buttons
     -----
     */
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            textFieldBottomConstraint.constant = keyboardSize.height + 20
            
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        textFieldBottomConstraint.constant = 20
    }
    
    @objc func dissmiss() {
        self.UserInputText.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        updateText(self)
        return true
    }
    
    //for keyboard
    @IBAction func updateText(_ sender: Any) {
        if let keyText = UserInputText.text {
            saveText(text: keyText)
            self.delegate?.passText(text: keyText, i: -1)
        }
    }
    
    //for clipboard
    @IBAction func addClipboardText(_ sender: Any) {
        let text = getClipboard()
        saveText(text: text)
        self.delegate?.passText(text: text, i: -1)
    }
    
    @IBAction func chooseGalleryImage(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        self.present(image, animated: true)
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /*
     -----
     Insert View Controller - Logical functions, and database connections
     -----
     */
    
    func getClipboard() -> String{
        let pasteboard: String? = UIPasteboard.general.string
        if let string = pasteboard {
            saveText(text: string)
            return string
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            if ((self.delegate?.currentProfile) != nil){
                let profile = self.delegate?.currentProfile!
                var name = "content1"
                if(delegate?.selectedTemplate?.name == "Bottom node"){
                    name = "content2"
                }
                saveImage(profile: profile!, pickedImage: pickedImage, name: name)
            }
            delegate?.passImage(image: pickedImage)
        }
        else{
            // error message
        }
    }
    
    func saveImage(profile: String, pickedImage: UIImage, name: String){
        let imageRef = storageRef?.child("images").child(profile)
        let fileRef = imageRef?.child(String(pickedImage.hashValue))
        let data = UIImageJPEGRepresentation(pickedImage, 1)! as NSData
        fileRef?.putData(data as Data, metadata: nil){
            (metadata, error) in guard metadata != nil else {
                return
            }
            // https://firebase.google.com/docs/storage/ios/upload-files?authuser=0
            guard let imageURL =  metadata?.downloadURLs?.first?.absoluteString else { fatalError() }
            self.ref.child("notebooks/\((self.delegate?.notebookID)!)/\((self.delegate?.currentPage)!)").updateChildValues([name:imageURL, "empty": "false"])
        }
    }
    func saveText(text: String){
        if (delegate?.accessToWrite)! {
            var name = "content1"
            if(delegate?.selectedTemplate != nil) {
                if(delegate?.selectedTemplate.name == "Bottom node"){
                    name = "content2"
                }
                self.ref.child("notebooks/\((self.delegate?.notebookID)!)/\((self.delegate?.currentPage)!)").updateChildValues([name: text, "empty": "false"])
            }
        }
    }
}

