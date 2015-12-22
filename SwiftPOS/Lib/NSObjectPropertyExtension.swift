//
//  NSObjectPropertyExtension.swift
//  SwiftPOS
//
//  Created by 刘通超 on 15/12/21.
//  Copyright © 2015年 刘通超. All rights reserved.
//

import Foundation

extension NSObject{
    
    /**
     获取对象对于的属性值，无对于的属性则返回NIL
     
     - parameter property: 要获取值的属性
     
     - returns: 属性的值
     */
    func getValueOfProperty(property:String)->AnyObject?{
        let allPropertys = self.getAllPropertys()
        if(allPropertys.contains(property)){
            return self.valueForKey(property)

        }else{
            return nil
        }
    }
    
    /**
     设置对象属性的值
     
     - parameter property: 属性
     - parameter value:    值
     
     - returns: 是否设置成功
     */
    func setValueOfProperty(property:String,value:AnyObject)->Bool{
        let allPropertys = self.getAllPropertys()
        if(allPropertys.contains(property)){
            self.setValue(value, forKey: property)
            return true
            
        }else{
            return false
        }
    }
    
    /**
     获取对象的所有属性名称
     
     - returns: 属性名称数组
     */
    func getAllPropertys()->[String]{
        
        var result = [String]()
        let count = UnsafeMutablePointer<UInt32>.alloc(0)
        let buff = class_copyPropertyList(object_getClass(self), count)
        let countInt = Int(count[0])
        
        for(var i=0;i<countInt;i++){
            let temp = buff[i]
            let tempPro = property_getName(temp)
            let proper = String.init(UTF8String: tempPro)
            result.append(proper!)
            
        }
        
        return result
    }
}
