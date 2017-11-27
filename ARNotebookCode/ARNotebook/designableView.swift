//
//  designableView.swift
//  ARNotebook
//
//  Created by Denise Green on 10/16/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit

@IBDesignable class designableView: UIView {
    
    @IBInspectable var cornerRadius : CGFloat = 0{
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
