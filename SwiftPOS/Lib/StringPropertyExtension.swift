//
//  StringPropertyExtension.swift
//  SwiftPOS
//
//  Created by 刘通超 on 15/12/17.
//  Copyright © 2015年 刘通超. All rights reserved.
//

import Foundation

extension String{
    
    var length:Int{
        get{
            if(self.hasPrefix("Optional(")){
               return self.characters.count - 10
            }else{
                return self.characters.count
            }
        }
    }
    
    
}
