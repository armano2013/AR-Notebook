//
//  textViewController.swift
//  ARNotebook
//
//  Created by Denise Green on 10/16/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit


class textViewController: UIViewController,UITextFieldDelegate, UINavigationControllerDelegate, UITextViewDelegate {

    
    @IBOutlet weak var userTextInput: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
         userTextInput.delegate = self as? UITextFieldDelegate
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this ends the key boards
        self.view.endEditing(true)
    }
    
    
    func textFieldShouldReturn(_ text: UITextField) -> Bool{
        userTextInput.resignFirstResponder()
        return true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
