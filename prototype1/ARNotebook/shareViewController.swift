import UIKit
import ARKit
import Firebase
import FirebaseDatabase

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
    /*
     -----
     Generic Set Up
     -----
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Initialize the sections array
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        print(longLink?.absoluteString ?? "")
        
        let options = DynamicLinkComponentsOptions()
        options.pathLength = .unguessable
        components.options = options

    }
    
    func returnShareLink() -> String {
        return (self.longLink?.absoluteString ?? "")
    }
    
}
