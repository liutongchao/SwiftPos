//
//  StringPosUtilTransExtension.swift
//  SwiftPOS
//
//  Created by 刘通超 on 15/12/16.
//  Copyright © 2015年 刘通超. All rights reserved.
//

import Foundation

extension String{
    
    /**
     位图转换工具 位图转换成字符串
     
     - parameter bitmapArr: 位图数组
     
     - returns: 位图字符串
     */
    static func createBitmap(bitmapArr bitmapArr:[UInt8])->String{
        
        var bitChar = [UInt8](count: 8, repeatedValue: 0)
        
        for var bit in bitmapArr {
            bit--
            bitChar[Int(bit) / 8] |= (0x80 >> (bit % 8))
        }
        
        let data = NSData.init(bytes: bitChar, length: 8)
        
        let dataStr = hexStringFromData(data: data)
        
        return dataStr
    }
    
    /**
     位图转换工具 字符串转换成位图
     
     - parameter bitmapStr: 位图字符串
     
     - returns: 位图数组
     */
    static func analyseBitmap(bitmapStr bitmapStr:String)->[UInt8]{
        let mapData = String.dataFromHexString(hexStr: bitmapStr)
        
        let dataLength = mapData.length
        let buffer = UnsafePointer<UInt8>(mapData.bytes)
        var result = [UInt8]()
        for(var i=0;i<dataLength;i++){
            for(var j=0;j<8;j++){
                let temp = buffer[i] << UInt8(j)
                if(temp&0x80 == 0x80){
                    let bit = 8*i + j + 1
                    result.append(UInt8(bit))
                }
            }
        }
        
        return result
    }

    
    //MARK: data 转换为十六进制字符串
    /**
    data 转换为十六进制字符串
    <24211D34 98FF62AF>  -->  "24211D3498FF62AF"
    
    - parameter data: 要转换的data
    
    - returns: 转换后的字符串
    */
    static func hexStringFromData(data data:NSData)->String{
        let dataLength = data.length
        let buffer = UnsafePointer<UInt8>(data.bytes)
        var result = ""
        for(var i=0;i<dataLength;i++){
            let num = Int(buffer[i]&0xff)
            result += decIntToTwoHexString(decNum: num)
        }
        return result
    }
    
    //MARK: 十六 进制字符串转换为 data
    /**
    十六 进制字符串转换为 data
    "24211D3498FF62AF"  -->  <24211D34 98FF62AF>
    - parameter hexStr: 要转换的字符串
    
    - returns: 转换后的data数据
    */
    static func dataFromHexString(hexStr hexStr:String)->NSData{
        let strLength = hexStr.utf16.count
        
        let data = NSMutableData()
        for(var index=0; index+2<=strLength; index+=2){
            let subStr = hexStr.substringWithRange(Range(start: hexStr.startIndex.advancedBy(index), end: hexStr.startIndex.advancedBy(index+2)))
            let dataInt = UnsafeMutablePointer<UInt32>.alloc(1)
            NSScanner.init(string: subStr).scanHexInt(dataInt)
            
            data.appendBytes(dataInt, length: 1)
        }
        return data
    }
    //MARK: hex字符串转为ASC码  00 --> 3030
    /**
    hex字符串转为ASC码  00 --> 3030
    
    - parameter hexString: hex字符串
    
    - returns: 转码后的ASC字符串
    */
    static func ascStringFromHexString(hexString:String)->String{
        var result = ""
        let length = hexString.utf16.count
        let buffer = hexString.cStringUsingEncoding(NSUTF8StringEncoding)
        for(var i=0;i<length;i++){

            result += decIntToTwoHexString(decNum: Int(buffer![i]))
        }
        return result
    }
    
    //MARK: ASC码转为Hex字符串  3030 --> 00
    /**
     ASC码转为Hex字符串  3030 --> 00
     
     - parameter ascStr: ASC字符串
     
     - returns: 转码后的Hex字符串
     */
    static func hexStringFromAscString(ascStr ascStr:String)->String{
        
        let dda = String.dataFromHexString(hexStr: ascStr)
        
        let result = String.init(data: dda, encoding: NSUTF8StringEncoding)
        
        return result!
    }

    /**
     获取字符串的长度，并返回单字节（两位）长度值（十进制）
     
     - returns: 单字节长度值
     */
    func getStringLengthWithOneBytes()->String{
        let length = self.length
        if(length < 10){
            return "0"+"\(length)"
        }else if(length < 100){
            return String(length)
        }else{
            print("字符串获取单字节长度值长度超限!")
            return ""
        }
    }
    
    /**
     获取字符串的长度，并返回双字节（四位）长度值（十进制）
     
     - returns: 双字节长度值
     */
    func getStringLengthWithTwoBytes()->String{
        let length = self.length
        if(length < 10){
            return "000"+"\(length)"
        }else if(length < 100){
            return "00"+"\(length)"
        }else if(length < 1000){
            return "0"+"\(length)"
        }else if(length < 10000){
            return "\(length)"
        }else{
            print("字符串获取双字节长度值长度超限!")
            return ""
        }
    }
    
    
    
    /**
     Int 十进制数转为十六进制字符串（两位）
     
     - parameter num: 十进制数字
     
     - returns: 两位十六进制字符串
     */
    static func decIntToTwoHexString(decNum num:Int)->String{
        let temp = decIntToHexString(decNum: num)
        let result = (temp.utf16.count <= 1) ? "0"+temp: temp;
        return result
    }
    
    /**
     Int 十进制数转为十六进制字符串（四位）
     
     - parameter num: 十进制数字
     
     - returns: 两位十六进制字符串
     */
    static func decIntToFourHexString(decNum num:Int)->String{
        let temp = decIntToHexString(decNum: num)
        let length = temp.utf16.count
        var result = ""
        for (var i=0;i<4-length;i++){
            result += "0"
        }
        result += temp
        
        return result
    }

    
    /**
      Int 十进制数转为十六进制字符串（两位）
     
     - parameter num: 十进制数字
     
     - returns: 十六进制字符串
     */
    private static func decIntToHexString(decNum num:Int)->String{
        let temp = String(format: "%0x", arguments: [num])
        return temp
    }
    
}
