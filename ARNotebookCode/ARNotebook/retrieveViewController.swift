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
    func setTime(id: String)
    func deleteNotebook(book: String)
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
    var pageNum : Int = 1
    var notebookIDArray = [String]()
    var pageObjArray = [Page]()
    var notebookArray = [String]()
    var retrievedNotebookID: Int!
    var cameFromShare : Bool = false
    var sharedNotebookID : String = ""
    var accessToWrite : Bool = false
    var prevVC: shareViewController!
    var notebookID : String = "0"
    
    /*
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
            retrievePreviousNotebookWithID(id: sharedNotebookID)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let longLogOutGesture = UILongPressGestureRecognizer(target: self, action: #selector(logOutInstruction(_:)))
        self.logOutButton.addGestureRecognizer(longLogOutGesture)
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    /*
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
    */
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logOutButton: UIButton!
    
    @objc func logOutInstruction( _ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let alertController = UIAlertController(title: "", message: "Due to Facebook's Software Policies, you cannot fully log out of your Facebook account until you log out of every Facebook option on your device. This includes your web browser, other applications, and Facebook itself.", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
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
                            var contentVal = content.value as! String
                            if(content.key != "color" ){
                                if (content.key == "empty" && contentVal == "false"){
                                    continue
                                }
                                else if (content.key == "empty" && contentVal == "true"){
                                    contentVal = " "
                                    pageContent.append(contentVal)
                                }
                                else{
                                    pageContent.append(contentVal)
                                }
                            }
                            else {
                                //update page struct to handle retrieved page color
                            }
                        }
                        let newPage = Page(content: pageContent)
                        self.pageObjArray.append(newPage)
                    }
                    else {
                        //updating page struct to add in cover style
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
                let alertController = UIAlertController(title: "Error", message: "The Notebook you are trying to view could not be retrieved. The notebook may have been moved or deleted.", preferredStyle: UIAlertControllerStyle.alert)
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
        getTime(id: self.notebookIDArray[indexPath.row]) { date in
            guard let date = date else { return }
            cell.textLabel?.text = "\(self.notebookArray[indexPath.row])" + " : \(date)"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.notebookID = Int(self.notebookIDArray[indexPath.row])!
        self.delegate?.retrievedFlag = true
        retrievePreviousNotebookWithID(id: self.notebookIDArray[indexPath.row])
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete{
            self.delegate?.deleteNotebook(book: self.notebookIDArray[indexPath.row])
            self.getList()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSharedNotebook"
        {
            let mainVC = segue.destination as? ViewController
            mainVC?.retrievedFlag = true
            mainVC?.pageObjectArray = self.pageObjArray
            mainVC?.accessToWrite  = self.accessToWrite
            mainVC?.notebookID = Int(self.notebookID)!
            mainVC?.cameFromShare = true
            mainVC?.prevVC = self
            if(self.accessToWrite) {
                 mainVC?.notebookID = Int(self.sharedNotebookID)! //if the user can write update the notebookID flag so the updates are managed in DB
            }
        }
    }
 }
