//
//  ViewController.swift
//  SwiftPOS
//
//  Created by 刘通超 on 15/12/15.
//  Copyright © 2015年 刘通超. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.        

        let posMess = PosMessage()
        posMess.tradeType = "0200"
        posMess.ED2 = "622732240494134"
        posMess.ED3 = "000001"
        posMess.ED4 = "000000000100"
        posMess.ED35 = "0123456789012345678901234567890123456"
        posMess.ED37 = "371234123456"
        posMess.ED39 = "01"
        posMess.ED44 = "1234567"
        posMess.ED46 = "12345678"
        posMess.ED52 = "1234567890123456"
        posMess.ED55 = "12345678901234567890"
        
        let sss = Pos8583Factory.pack8583MessageWitPosMessage(posMess)
        print("posdata:\(sss)")
        
        let content = String.hexStringFromData(data: sss!)
        let model = Pos8583Factory.analyse8583MessageWithMessStr(content.substringFromIndex(content.startIndex.advancedBy(4)))
        print("model:\(model)")

    }
}



