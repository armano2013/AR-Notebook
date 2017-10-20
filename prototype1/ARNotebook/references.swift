//
//  references.swift
//  ARNotebook
//
//  Created by Megan Majewski on 10/20/17.
//
// This file is used to hold code we dont want to delete
//

import Foundation



//    @IBAction func addText(_ sender: Any) {
//        let page = currentPageNode
//        let text = SCNText(string: getClipboard(), extrusionDepth: 0.1)
//
//      //  text.containerFrame = CGRect(origin: .zero, size: CGSize(width: 1.4, height: 1.8))
//        text.isWrapped = true
//        let material = SCNMaterial()
//        if(pages.count % 2 == 0){
//            material.diffuse.contents = UIColor.black
//        }
//        else {
//            material.diffuse.contents = UIColor.blue
//        }
//        text.materials = [material]
//        let node = SCNNode()
//        node.geometry = text
//        node.scale = SCNVector3Make(0.01, 0.01, 0.01)
//
//        /* credit: https://stackoverflow.com/questions/44828764/arkit-placing-an-scntext-at-a-particular-point-in-front-of-the-camera
//         let (min, max) = node.boundingBox
//
//        let dx = min.x + 0.5 * (max.x - min.x)
//        let dy = min.y + 0.5 * (max.y - min.y)
//        let dz = min.z + 0.5 * (max.z - min.z)
//        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
//        */
//        node.position = SCNVector3(-0.7, 0.0, 0.05)
//        //node.eulerAngles = SCNVector3(0, 180.degreesToRadians, 0) //for some reason text is added backward
//        page?.addChildNode(node)
//    }
//    func getClipboard() -> String{
//        let pasteboard: String? = UIPasteboard.general.string
//        if let string = pasteboard {
//            return string
//            //update database here
//        }
//        return "No String Found on Clipboard"
//    }


//    @IBAction func addImage(_ sender: Any) {
//        let imagePicker = UIImagePickerController()
//        imagePicker.delegate = self
//
//        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
//        imagePicker.allowsEditing = false
//        self.present(imagePicker, animated: true)
//
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            //send picked image to the database
//            let node = SCNNode()
//            node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.001, chamferRadius: 0)
//            node.geometry?.firstMaterial?.diffuse.contents = UIImage.animatedImage(with: [pickedImage], duration: 0)
//            node.position = SCNVector3(0.1,0.1,0.1)
//            sceneView.scene.rootNode.addChildNode(node)
//        }
//        else{
//            //
//        }
//        dismiss(animated: true, completion: nil)
//    }
