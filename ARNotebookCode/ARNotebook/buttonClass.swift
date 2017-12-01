//
//  buttonClass.swift
//  ARNotebook
//
//  Created by Denise Green on 10/27/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit

@IBDesignable class buttonClass: UIButton {
    
    @IBInspectable var cornerRadius : CGFloat = 0{
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
}
