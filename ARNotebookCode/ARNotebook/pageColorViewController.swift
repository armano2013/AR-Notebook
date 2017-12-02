
//  pageColorViewController.swift
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

protocol pageColorDelegate {
    func pageColor(image : UIImage, style: String)
    func bookColor(imageOne : UIImage, cover: String)
    func addAllColorsToDB(color: String)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addLongButtonGestures()
    }
    
    /*
     ----
     BookCover Functions
     
     -----
     */
    
    
    @IBOutlet weak var redButton: buttonClass!
    @IBOutlet weak var defaultButton: buttonClass!
    @IBOutlet weak var yellowButton: buttonClass!
    @IBOutlet weak var purpleButton: buttonClass!
    @IBOutlet weak var blueButton: buttonClass!
    @IBOutlet weak var greenButton: buttonClass!
    
    func addLongButtonGestures(){
        let longRed = UILongPressGestureRecognizer(target: self, action: #selector(longRedPress(_:)))
        self.redButton.addGestureRecognizer(longRed)
        let longDefault = UILongPressGestureRecognizer(target: self, action: #selector(longDefaultPress(_:)))
        self.defaultButton.addGestureRecognizer(longDefault)
        let longYellow = UILongPressGestureRecognizer(target: self, action: #selector(longYellowPress(_:)))
        self.yellowButton.addGestureRecognizer(longYellow)
        let longPurple = UILongPressGestureRecognizer(target: self, action: #selector(longPurplePress(_:)))
        self.purpleButton.addGestureRecognizer(longPurple)
        let longBlue = UILongPressGestureRecognizer(target: self, action: #selector(longBluePress(_:)))
        self.blueButton.addGestureRecognizer(longBlue)
        let longGreen = UILongPressGestureRecognizer(target: self, action: #selector(longGreenPress(_:)))
        self.greenButton.addGestureRecognizer(longGreen)
    }
    
    @objc func longRedPress( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let red = #imageLiteral(resourceName: "RedPage")
            pageColorString = "red"
            delegate?.pageColor(image : red, style: "long")
            if ((self.delegate?.currentProfile) != nil){
                self.delegate?.addAllColorsToDB(color: self.pageColorString!)
            }
            self.dismiss(animated: true, completion: nil)
            print("long red tapped")
        }
    }
    
    @objc func longDefaultPress( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let defaultPage = #imageLiteral(resourceName: "page")
            self.pageColorString = "default"
            self.delegate?.pageColor(image : defaultPage, style: "long")
            if pageColorString != nil{
                self.delegate?.addAllColorsToDB(color: self.pageColorString!)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func longYellowPress( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let yellow = #imageLiteral(resourceName: "YellowPage")
            self.pageColorString = "yellow"
            self.delegate?.pageColor(image : yellow, style: "long")
            if ((self.delegate?.currentProfile) != nil){
                self.delegate?.addAllColorsToDB(color: self.pageColorString!)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func longPurplePress( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let purple = #imageLiteral(resourceName: "PurplePage")
            pageColorString = "purple"
            self.delegate?.pageColor(image : purple, style: "long")
            if ((self.delegate?.currentProfile) != nil){
                self.delegate?.addAllColorsToDB(color: self.pageColorString!)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func longBluePress( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let blue = #imageLiteral(resourceName: "BluePage")
            self.pageColorString = "blue"
            self.delegate?.pageColor(image : blue, style: "long")
            if ((self.delegate?.currentProfile) != nil){
                self.delegate?.addAllColorsToDB(color: self.pageColorString!)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func longGreenPress( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let green = #imageLiteral(resourceName: "GreenPage")
            self.pageColorString = "green"
            self.delegate?.pageColor(image : green, style: "long")
            if ((self.delegate?.currentProfile) != nil){
                let profile = self.delegate?.currentProfile!
                addPageColorDatabase(profile: profile!, text: pageColorString!)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func blueButton(_ sender: Any) {
        let blueOne = #imageLiteral(resourceName: "spiralNotebook")
        self.delegate?.bookColor(imageOne: blueOne, cover: "coffee")
    }
    
    @IBAction func purpleRain(_ sender: Any) {
        let purpleOne = #imageLiteral(resourceName: "graphicBook1 copy2")
        self.delegate?.bookColor(imageOne: purpleOne, cover: "brown")
    }
    
    @IBAction func blackButton(_ sender: Any) {
        let blackOne = #imageLiteral(resourceName: "brownBook")
        self.delegate?.bookColor(imageOne: blackOne, cover: "black")
    }
    /*
     -----
     Pae color Functions
     -----
     */
    @IBAction func redButton(_ sender: Any) {
        let red = #imageLiteral(resourceName: "RedPage")
        self.pageColorString = "red"
        self.delegate?.pageColor(image : red, style: "tap")
        if ((self.delegate?.currentProfile) != nil){
            let profile = self.delegate?.currentProfile!
            self.addPageColorDatabase(profile: profile!, text: pageColorString!)
        }
    }
    @IBAction func blueColor(_ sender: Any) {
        let blue = #imageLiteral(resourceName: "BluePage")
        self.pageColorString = "blue"
        self.delegate?.pageColor(image : blue, style: "tap")
        if ((self.delegate?.currentProfile) != nil){
            let profile = self.delegate?.currentProfile!
            self.addPageColorDatabase(profile: profile!, text: pageColorString!)
        }
    }
    
    @IBAction func greenColor(_ sender: Any) {
        let green = #imageLiteral(resourceName: "GreenPage")
        self.pageColorString = "green"
        self.delegate?.pageColor(image : green, style: "tap")
        if ((self.delegate?.currentProfile) != nil){
            let profile = self.delegate?.currentProfile!
            self.addPageColorDatabase(profile: profile!, text: pageColorString!)
        }
    }
    
    @IBAction func purpleColor(_ sender: Any) {
        let purple = #imageLiteral(resourceName: "PurplePage")
        self.pageColorString = "purple"
        self.delegate?.pageColor(image : purple, style: "tap")
        if ((self.delegate?.currentProfile) != nil){
            let profile = self.delegate?.currentProfile!
            self.addPageColorDatabase(profile: profile!, text: pageColorString!)
        }
    }
    
    @IBAction func yellowPage(_ sender: Any) {
        let yellow = #imageLiteral(resourceName: "YellowPage")
        pageColorString = "yellow"
        self.delegate?.pageColor(image : yellow, style: "tap")
        if ((self.delegate?.currentProfile) != nil){
            let profile = self.delegate?.currentProfile!
            self.addPageColorDatabase(profile: profile!, text: pageColorString!)
        }
    }
    
    @IBAction func DefaultPage(_ sender: Any) {
        let plain = #imageLiteral(resourceName: "page")
        self.pageColorString = "default"
        self.delegate?.pageColor(image : plain, style: "tap")
        if((self.delegate?.currentProfile) != nil){
            let profile = self.delegate?.currentProfile!
            addPageColorDatabase(profile: profile!, text: pageColorString!)
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
    
    func addAllColorDB(text: String){
        self.delegate?.addAllColorsToDB(color: text)
    }
}
