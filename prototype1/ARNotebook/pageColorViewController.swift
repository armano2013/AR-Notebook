//
//  pageColorViewController.swift
//  ARNotebook
//
//  Created by Denise Green on 10/26/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit

protocol pageColorDelegate {
    func pageColor(color : UIColor)
}

class pageColorViewController: UIViewController {
    /*
     -----
     Global Variables
     -----
     */
    var delegate : pageColorDelegate?
    
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
    
    @IBAction func redButton(_ sender: Any) {
        print("page color red")
        let colorOne = UIColor.red
        delegate?.pageColor(color : colorOne)
    }
    @IBAction func blueColor(_ sender: Any) {
        print("page color blue")
        let colorOne = UIColor.blue
        delegate?.pageColor(color : colorOne)
    }
    @IBAction func greenColor(_ sender: Any) {
        print("page color green")
        let colorOne = UIColor.green
        delegate?.pageColor(color : colorOne)
    }
    
    
    /*
     -----
     Delete View Controller - Buttons
     -----
     */
 

}
// Thought about using collection View as a method heres the code

//    @IBOutlet weak var menuCell: UICollectionView!
//
//    let menuArray :[UIColor] = [UIColor.red, UIColor.blue, UIColor.brown]
//     self.menuCell.dataSource = self
//    self.menuCell.delegate = self

//       func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//            return menuArray.count
//        }
//        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "menu", for: indexPath)
//            cell.backgroundColor = self.menuArray[indexPath.row]
//
//            return cell
//        }
//       func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//            let cell = collectionView.cellForItem(at: indexPath)
//            cell?.backgroundColor = UIColor.gray
//        }
//        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//            let cell = collectionView.cellForItem(at: indexPath)
//            cell?.backgroundColor = UIColor.white
//        }
//        func dissMissview (){
//            dismiss(animated: true, completion: nil)
//        }
