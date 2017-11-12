
//  pageColorViewController.swift
//  ARNotebook
//
//  Created by Denise Green on 10/26/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import ARKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol pageColorDelegate {
    func pageColor(image : UIImage)
    func bookColor(imageOne : UIImage, cover: String)
    var currentProfile: String!  {get set}
    var notebookID : Int { get set }
    var currentPage: Int {get set}
    var currentPageColor: String {get set}

}

class pageColorViewController: UIViewController {
    /*
     -----
     Global Variables
     -----
     */
    var delegate : pageColorDelegate?
    var ref: DatabaseReference!
    var storageref : StorageReference!
    var pageColorString : String?

    /*
     -----
     Generic Set Up
     -----
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        storageref = Storage.storage().reference()

        // Do any additional setup after loading the view.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
     ----
     BookCover Functions

     -----
     */
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func blueButton(_ sender: Any) {
        let blueOne = #imageLiteral(resourceName: "spiralNotebook")
        delegate?.bookColor(imageOne: blueOne, cover: "blue")
    }
    
    @IBAction func purpleRain(_ sender: Any) {
        let purpleOne = #imageLiteral(resourceName: "graphicBook1 copy2")
        delegate?.bookColor(imageOne: purpleOne, cover: "purple")
    }
    
    @IBAction func blackButton(_ sender: Any) {
        let blackOne = #imageLiteral(resourceName: "brownBook")
        delegate?.bookColor(imageOne: blackOne, cover: "black")
    }
    /*
     -----
     Pae color Functions
     -----
     */
    @IBAction func redButton(_ sender: Any) {
        let red = #imageLiteral(resourceName: "RedPage")
        pageColorString = "red"
        delegate?.pageColor(image : red)
        if let keyText = pageColorString{
            if ((self.delegate?.currentProfile) != nil){
                let profile = self.delegate?.currentProfile!
                addPageColorDatabase(profile: profile!, text: pageColorString!)
            }
        }
    }
    @IBAction func blueColor(_ sender: Any) {
        let blue = #imageLiteral(resourceName: "BluePage")
        pageColorString = "blue"
        delegate?.pageColor(image : blue)
        if let keyText = pageColorString{
            if ((self.delegate?.currentProfile) != nil){
                let profile = self.delegate?.currentProfile!
                addPageColorDatabase(profile: profile!, text: pageColorString!)
            }
        }
    }
    @IBAction func greenColor(_ sender: Any) {
        let green = #imageLiteral(resourceName: "GreenPage")
        pageColorString = "green"
        if let keyText = pageColorString{
            if ((self.delegate?.currentProfile) != nil){
                let profile = self.delegate?.currentProfile!
                addPageColorDatabase(profile: profile!, text: pageColorString!)
            }
        }
        delegate?.pageColor(image : green)
    }
    @IBAction func purpleColor(_ sender: Any) {
        let purple = #imageLiteral(resourceName: "PurplePage")
        pageColorString = "purple"
        if let keyText = pageColorString{
            if ((self.delegate?.currentProfile) != nil){
                let profile = self.delegate?.currentProfile!
                addPageColorDatabase(profile: profile!, text: pageColorString!)
            }
        }
        delegate?.pageColor(image : purple)
    }
    @IBAction func yellowPage(_ sender: Any) {
        let yellow = #imageLiteral(resourceName: "YellowPage")
        pageColorString = "yellow"
        if let keyText = pageColorString{
            if ((self.delegate?.currentProfile) != nil){
                let profile = self.delegate?.currentProfile!
                addPageColorDatabase(profile: profile!, text: pageColorString!)
            }
        }
        delegate?.pageColor(image : yellow)
    }
    @IBAction func DefaultPage(_ sender: Any) {
        let plain = #imageLiteral(resourceName: "page")
        pageColorString = "default"
        delegate?.pageColor(image : plain)
        if let keyText = pageColorString {
            if((self.delegate?.currentProfile) != nil){
                let profile = self.delegate?.currentProfile!
                addPageColorDatabase(profile: profile!, text: pageColorString!)
            }
            delegate?.pageColor(image : plain)
        }
    }
    /*
     -----

     Database function

     -----
     */
    func addPageColorDatabase(profile: String, text: String){
        ref.child("notebooks/\((self.delegate?.notebookID)!)/\((self.delegate?.currentPage)!)").updateChildValues(["color" : text])
    }
    func addBookStlyeDatabase(profile: String, text: String){
       ref.child("notebooks/\((self.delegate?.notebookID)!)").updateChildValues(["Cover Style" : text])
}
}
