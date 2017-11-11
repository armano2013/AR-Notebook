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
    var accessType: String = ""


    /*
     -----
     Generic Set Up
     -----
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
        accessType = arr[1]
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
