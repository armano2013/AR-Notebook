//
//  buttonClass.swift
//  ARNotebook
//
//  Created by AR Notebook on 10/15/17.
//  Copyright © 2017 AR Notebook. All rights reserved.
//


import UIKit

@IBDesignable class buttonClass: UIButton {
    
    @IBInspectable var cornerRadius : CGFloat = 0{
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
}
