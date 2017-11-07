import UIKit
import Firebase

protocol retrieveDelegate {
    func addContent(numPages: Int, content: [String])
}
class retrieveViewController: UIViewController {
    
    /*
     -----
     Global Variables
     -----
     */
    var ref: DatabaseReference!
    var pageContent = [String]()
    var delegate : retrieveDelegate?
    var pageNum : Int = 1
    
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
    }
    @IBAction func selectNotebookID() {
        retrievePreviousNotebookWithID(id: "7585393408")
    }
    func retrievePreviousNotebookWithID(id: String){
        ref.child("notebooks").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            let enumPages = snapshot.children
            self.pageNum = Int(snapshot.childrenCount)
            while let pages = enumPages.nextObject() as? DataSnapshot {
                let enumContent = pages.children
                while let content = enumContent.nextObject() as? DataSnapshot {
                    let contentVal = content.value as! String
                    print(contentVal)
                    self.pageContent.append(contentVal)
                }
            }
            self.delegate?.addContent(numPages: self.pageNum, content: self.pageContent)
        })
    }
}
