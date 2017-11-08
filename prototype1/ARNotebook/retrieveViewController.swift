import UIKit
import FacebookLogin
import FacebookCore
import FirebaseAuth
import FacebookCore
import FirebaseDatabase

protocol retrieveDelegate {
    func addContent(numPages: Int, content: [String])
}

class retrieveViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    /*
     -----
     Global Variables
     -----
     */
    var ref: DatabaseReference!
    var pageContent = [String]()
    var delegate : retrieveDelegate?
    var pageNum : Int = 1
    var notebookArray =  [String]()
    var retrievedNotebookID: Int!
    
    /*keeping this here to use for templates later
     
    struct Page {
        //template id
        //color
    }
     */
    
    
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
        super.viewDidAppear( animated )
        tableView.reloadData()
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
    func getList() {
        ref.child("users").child((Auth.auth().currentUser?.uid)!).observeSingleEvent(of: .value) { (snapshot) in
            let notebooksChildren = snapshot.children
            while let ids = notebooksChildren.nextObject() as? DataSnapshot{
                let notebookcontent = ids.children
                while let content = notebookcontent.nextObject() as? DataSnapshot{
                    let ID = content.value as! Int
                    if !self.notebookArray.contains(String(ID)) { // only appends if a new and unique notebook is added
                        self.notebookArray.append(String(ID))
                    }
                }
            }
        }
    }
    
    @IBAction func selectNotebookID() {
        retrievePreviousNotebookWithID(id: "7585394688")
    }
    func retrievePreviousNotebookWithID(id: String){
        ref.child("notebooks").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            let enumPages = snapshot.children
            self.pageNum = Int(snapshot.childrenCount)
            while let pages = enumPages.nextObject() as? DataSnapshot {
                let enumContent = pages.children
                while let content = enumContent.nextObject() as? DataSnapshot {
                    let contentVal = content.value as! String
                    self.pageContent.append(contentVal)
                }
            }
            self.delegate?.addContent(numPages: self.pageNum, content: self.pageContent)
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
        cell.accessoryType = .detailDisclosureButton
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        retrievePreviousNotebookWithID(id: self.notebookArray[indexPath.row])
    }
    /*func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        this is code for deleting the table view cell. Could be a cleaner way of deleting entire notebooks
    }*/
}
