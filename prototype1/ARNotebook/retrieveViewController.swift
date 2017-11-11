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
}

class retrieveViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    /*
     -----
     Global Variables
     -----
     */
    var ref: DatabaseReference!
    //var pageContent = [String]()
    var delegate : retrieveDelegate?
    var pageNum : Int = 1
    var notebookIDArray = [String]()
    var pageObjArray = [Page]()
    var notebookArray = [String]()
    var retrievedNotebookID: Int!
    /*
     struct Page {
        var content=[String]()
     }*/

    
    
    /*
     -----
     Generic Set Up
     -----
     */
    
    override func viewDidLoad() {
        ref = Database.database().reference()
        getList()
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
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /*override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
     self.view.isHidden = true
     }*/
    
    func getList() {
        ref.child("users").child((Auth.auth().currentUser?.uid)!+"/notebooks").observeSingleEvent(of: .value) { (snapshot) in
            let notebooksChildren = snapshot.children
            while let ids = notebooksChildren.nextObject() as? DataSnapshot{
                let notebookcontent = ids.children
                let nbID = ids.key as! String
                print(nbID)
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

    func retrievePreviousNotebookWithID(id: String){
        ref.child("notebooks").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            if snapshot.exists(){
                let enumPages = snapshot.children
                self.pageNum = Int(snapshot.childrenCount)
                while let pages = enumPages.nextObject() as? DataSnapshot {
                    let enumContent = pages.children
                    print(pages.key)
                    if(pages.key != "name") {
                        var pageContent = [String]()
                        while let content = enumContent.nextObject() as? DataSnapshot {
                            let contentVal = content.value as! String
                            pageContent.append(contentVal)
                        }
                        let newPage = Page(content: pageContent)
                        self.pageObjArray.append(newPage)
                    }
                }
                if(!self.pageObjArray.isEmpty){
                    self.delegate?.addContent(id: id, pageObjs: self.pageObjArray)
                }
                else{
                    let alertController = UIAlertController(title: "Error", message: "The Notebook you are trying to view has no content.", preferredStyle: UIAlertControllerStyle.alert)
                    let cancelAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
                    }
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
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
        retrievePreviousNotebookWithID(id: self.notebookIDArray[indexPath.row])
    }
    
    /* func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
     retrievePreviousNotebookWithID(id: self.notebookArray[indexPath.row])
     }*/
    
    /*func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     this is code for deleting the table view cell. Could be a cleaner way of deleting entire notebooks
     }*/
}
