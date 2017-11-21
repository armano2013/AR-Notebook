import UIKit
import FacebookLogin
import FacebookCore
import FirebaseAuth
import FacebookCore
import FirebaseDatabase

struct Page {
    var content=[String]()
}

protocol retrieveDelegate {
    func addContent(id: String, pageObjs: [Page])
    var retrievedFlag : Bool {get set}
    var notebookID: Int {get set}
    var pageObjectArray: [Page] {get set}
}

class retrieveViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    /*
     -----
     Global Variables
     -----
     */
    
    var ref: DatabaseReference!
    var delegate : retrieveDelegate?
    var delegate2: deleteDelegate?
    var pageNum : Int = 1
    var notebookIDArray = [String]()
    var pageObjArray = [Page]()
    var notebookArray = [String]()
    var retrievedNotebookID: Int!
    var cameFromShare : Bool = false
    var sharedNotebookID : String = ""
    var accessToWrite : Bool = false
    var prevVC: shareViewController!    /*
     -----
     Generic Set Up
     -----
     */
    
    override func viewDidLoad() {
        ref = Database.database().reference()
        if(!cameFromShare) {
          getList()
        }
        else{
            prevVC.dismiss(animated: true, completion: nil)
            //self.navigationController?.pushViewController(self, animated: false)
            retrievePreviousNotebookWithID(id: sharedNotebookID)
        }

    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func logOutFacebook(_ sender: Any) {
        let manager = LoginManager()
        manager.logOut()
        do {try Auth.auth().signOut()}
        catch {
            print(error)
        }
    }
   func retrieveShareContent(id : String){
        retrievePreviousNotebookWithID(id: id)
    }

    
    func setTime(id: String){
        let now = Date()
        let format = DateFormatter()
        format.timeZone = TimeZone.current
        format.dateFormat = "MM-dd-yyyy"
        let dateString = format.string(from: now)
        self.ref.child("notebooks/\(id)").updateChildValues(["LastAccessed":dateString])
    }
    
    func getTime(id: String, completion: @escaping (String?) -> Void) {
        var date: String?
        self.ref.child("notebooks/\(id)").observeSingleEvent(of: .value) { (snapshot) in
            let notebooksChildren = snapshot.children
            while let ids = notebooksChildren.nextObject() as? DataSnapshot {
                if ids.key == "LastAccessed" {
                    date = ids.value as? String
                    completion(date!)
                }
            }
        }
    }
    
    func getList() {
        ref.child("users").child((Auth.auth().currentUser?.uid)!+"/notebooks").observeSingleEvent(of: .value) { (snapshot) in
            let notebooksChildren = snapshot.children
            while let ids = notebooksChildren.nextObject() as? DataSnapshot{
                let notebookcontent = ids.children
                let nbID = ids.key 
                self.notebookIDArray.append(nbID)
                while let content = notebookcontent.nextObject() as? DataSnapshot{
                    let name = content.value as! String
                    if !self.notebookArray.contains(name) { // only appends if a new and unique notebook is added
                        self.notebookArray.append(name)
                    }
                }
            }
        }
    }
    
    func retrievePageContent(id: String){
        ref.child("notebooks").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(){
                let enumPages = snapshot.children
                self.pageNum = Int(snapshot.childrenCount)
                while let pages = enumPages.nextObject() as? DataSnapshot {
                    let enumContent = pages.children
                    if(pages.key != "name" && pages.key != "CoverStyle" && pages.key != "LastAccessed" ) {
                        var pageContent = [String]()
                        while let content = enumContent.nextObject() as? DataSnapshot {
                            let contentVal = content.value as! String
                            if(content.key != "color"){
                                pageContent.append(contentVal)
                            }
                            else{
                                //update page struct to handle
                            }
                        }
                        let newPage = Page(content: pageContent)
                        self.pageObjArray.append(newPage)
                    }
                }
                self.delegate?.pageObjectArray = self.pageObjArray
                if(self.cameFromShare == true){
                    if let mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainViewController") as? ViewController {
                        self.navigationController?.pushViewController(mainVC, animated: false)
                        self.performSegue(withIdentifier: "showSharedNotebook", sender: self)
                    }
                }
            }
        })
    }
    
    func retrievePreviousNotebookWithID(id: String){
        ref.child("notebooks").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(){
                self.retrievePageContent(id: id)
            }
            else {
                let alertController = UIAlertController(title: "Error", message: "The Notebook you are trying to view could not be retrieved.", preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
                }
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notebookArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notebookIDCell", for: indexPath)
        cell.textLabel?.text = self.notebookArray[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.notebookID = Int(self.notebookIDArray[indexPath.row])!
        setTime(id: self.notebookIDArray[indexPath.row])
        self.delegate?.retrievedFlag = true
        retrievePreviousNotebookWithID(id: self.notebookIDArray[indexPath.row])
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.delete{
            getTime(id: self.notebookIDArray[indexPath.row]) { date in
                guard let date = date else { return } }
        }
        //this is code for deleting the table view cell. Could be a cleaner way of deleting entire notebooks
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSharedNotebook"
        {
            let mainVC = segue.destination as? ViewController
            mainVC?.retrievedFlag = true
            mainVC?.pageObjectArray = self.pageObjArray
            mainVC?.accessToWrite  = self.accessToWrite
            mainVC?.prevVC = self
            if(self.accessToWrite) {
                 mainVC?.notebookID = Int(self.sharedNotebookID)! //if the user can write update the notebookID flag so the updates are managed in DB
            }
        }
    }
 }
