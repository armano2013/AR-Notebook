//
//  pageColorViewController.swift
//  ARNotebook
//
//  Created by Denise Green on 10/26/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit

protocol pageColorDelegate {
    func pageColor(image : UIImage)
    func bookColor(imageOne : UIImage)
    
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
    
    @IBAction func blueButton(_ sender: Any) {
        print("blue")
        let blueOne = #imageLiteral(resourceName: "spiral")
        delegate?.bookColor(imageOne: blueOne)
    }
    
    @IBAction func purpleRain(_ sender: Any) {
         print("purple")
        let purpleOne = #imageLiteral(resourceName: "purpleRain")
        delegate?.bookColor(imageOne:purpleOne)
    }
    
    @IBAction func blackButton(_ sender: Any) {
         print("black")
        let blackONe = #imageLiteral(resourceName: "black")
        delegate?.bookColor(imageOne: blackONe)
    }
    
    @IBAction func redButton(_ sender: Any) {
        print("page color red")
        let red = #imageLiteral(resourceName: "RedPage")
        delegate?.pageColor(image : red)
    }
    @IBAction func blueColor(_ sender: Any) {
        print("page color blue")
        let blue = #imageLiteral(resourceName: "BluePage")
        delegate?.pageColor(image : blue)
    }
    @IBAction func greenColor(_ sender: Any) {
        print("page color green")
        let green = #imageLiteral(resourceName: "GreenPage")
        delegate?.pageColor(image : green)
    }
    @IBAction func purpleColor(_ sender: Any) {
        print("page color purple")
        let purple = #imageLiteral(resourceName: "PurplePage")
        delegate?.pageColor(image : purple)
    }
    @IBAction func yellowPage(_ sender: Any) {
        print("page color yellow")
        let yellow = #imageLiteral(resourceName: "YellowPage")
        delegate?.pageColor(image : yellow)
    }
    @IBAction func DefaultPage(_ sender: Any) {
        print("page color default")
        let plain = #imageLiteral(resourceName: "page")
        delegate?.pageColor(image : plain)
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
