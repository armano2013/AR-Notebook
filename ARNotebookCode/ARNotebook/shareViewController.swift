//
//  shareViewController.swift
//  ARNotebook
//
//  Created by AR Notebook on 10/15/17.
//  Copyright © 2017 AR Notebook. All rights reserved.
//


import UIKit
import ARKit
import Firebase
import FirebaseDatabase

protocol shareBookDelegate {
    func retrieveShareContent(id : String)
}

class shareViewController: UIViewController {
    
    /*
     -----
     Global Variables
     -----
     */
    var notebookID: String = ""
    var accessType: Bool = false
    let DYNAMIC_LINK_DOMAIN = "h3qpv.app.goo.gl"
    var longLink: URL?
    var shortLink: URL?
    var delegate : shareBookDelegate?
    @IBOutlet weak var accessLabel: UILabel!
    /*
     -----
     Generic Set Up
     -----
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        var text = accessLabel.text
        if accessType {
            text! += "Write"
            accessLabel.text = text
        }
        else {
            text! += "Read Only"
            accessLabel.text = text
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func dismissShare(){
        if let retrieveVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "retrieve") as? retrieveViewController {
            self.navigationController?.pushViewController(retrieveVC, animated: true)
            performSegue(withIdentifier: "retrieveBooks", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "retrieveBooks"
        {
            let retrieveVC = segue.destination as? retrieveViewController
            retrieveVC?.cameFromShare = true
            retrieveVC?.accessToWrite = self.accessType
            retrieveVC?.sharedNotebookID = self.notebookID
            retrieveVC?.delegate?.retrievedFlag = true
            retrieveVC?.prevVC = self
            retrieveVC?.notebookID = self.notebookID
        }
    }
   
    
    /*
     -----
     Create Link to the current notebook
     -----
     */
    func setShareParams(arr: [String]){
        notebookID =  arr[0]
        accessType = Bool(arr[1])!
    }
    func buildLinkOptions(access: Bool, id: String){
        self.notebookID = id
        self.accessType = access
        let link = "https://www.arnotebook.com/" + notebookID + "/" + String(accessType)
        buildFDLLink(link: link)
    }
    @objc func buildFDLLink(link: String) {
        
        guard let link = URL(string: link) else { return }
        let components = DynamicLinkComponents(link: link, domain: DYNAMIC_LINK_DOMAIN)
        
        // iOS params
        let bundleID = "WSU.ARNotebook"
        let iOSParams = DynamicLinkIOSParameters(bundleID: bundleID)
        iOSParams.appStoreID = "1009116743"
        components.iOSParameters = iOSParams
        
        
        
        longLink = components.url
        
        let options = DynamicLinkComponentsOptions()
        options.pathLength = .unguessable
        components.options = options

    }
    
    func returnShareLink() -> String {
        return (self.longLink?.absoluteString ?? "")
    }
    
}
