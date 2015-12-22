//
//  Pos8583Factory.swift
//  SwiftPOS
//
//  Created by 刘通超 on 15/12/17.
//  Copyright © 2015年 刘通超. All rights reserved.
//

import Foundation

class Pos8583Factory: NSObject {
    
    static let EDConfigPath = NSBundle.mainBundle().pathForResource("IsoConfig", ofType: "plist")
    static let EDConfig = NSDictionary.init(contentsOfFile: EDConfigPath!)
    private static var tempMess = ""
    
    /**
     由PosMessage对象打包报文
     
     - parameter posMessage: 含报文信息的对象
     
     - returns: 报文数据
     */
    class func pack8583MessageWitPosMessage(posMessage :PosMessage)->NSData?{
        if posMessage.TPDU.isEmpty{
            print("TPDU缺失！")
            return nil
        }
        if posMessage.mesHead.isEmpty{
            print("报文头缺失！")
            return nil
        }
        if posMessage.tradeType.isEmpty{
            print("交易类型缺失！")
            return nil
        }
        let bitMap = getBitmapFromePosMess(posMessage)
        if(bitMap.isEmpty){
            print("所有域值缺失！")
            return nil
        }
        
        let content = create8583ContentWithMsg(posMessage)
        
        let data = pack8583MessageWithTPDU(posMessage.TPDU, messageHead: posMessage.mesHead, tradeType: posMessage.tradeType, bitmap: bitMap, messageContent: content)
        
        return data
    }
    
    /**
     解析报文 到PosMessage 对象里
     
     - parameter messStr: 报文数据
     
     - returns: 报文数据对象
     */
    class func analyse8583MessageWithMessStr(messStr:String)->PosMessage{
        let posMess = PosMessage()
        tempMess = messStr
        
        if messStr.length % 2 != 0{
            print("解析报文失败:报文长度错误，应为偶数")
            return posMess
        }
        
        posMess.TPDU = tempMess.substringToIndex(tempMess.startIndex.advancedBy(10))
        tempMess = tempMess.substringFromIndex(tempMess.startIndex.advancedBy(10))
        
        posMess.mesHead = tempMess.substringToIndex(tempMess.startIndex.advancedBy(12))
        tempMess = tempMess.substringFromIndex(tempMess.startIndex.advancedBy(12))
        
        posMess.tradeType = tempMess.substringToIndex(tempMess.startIndex.advancedBy(4))
        tempMess = tempMess.substringFromIndex(tempMess.startIndex.advancedBy(4))
        
        posMess.bitmap = tempMess.substringToIndex(tempMess.startIndex.advancedBy(16))
        tempMess = tempMess.substringFromIndex(tempMess.startIndex.advancedBy(16))
        
        let bitMapArr = String.analyseBitmap(bitmapStr: posMess.bitmap)
        
        for var i=0;i<bitMapArr.count;i++ {
            let element = bitMapArr[i]
            let elementName = "ED\(element)"
            
            let value = getElementValueWithElementName(elementName, content: tempMess)
            posMess.setValueOfProperty(elementName, value: value)
        }
        
        tempMess = ""
    
        return posMess
    }
    
    /**
     打包8583报文
     
     - parameter TPDU:           "6000000001"
     - parameter messageHead:    "603100310300"
     - parameter tradeType:      交易类型
     - parameter bitmap:         位图
     - parameter messageContent: 数据
     
     - returns: 报文数据
     */
    private class func pack8583MessageWithTradeType(tradeType:String, bitmap:[UInt8], messageContent:String)->NSData{
        return pack8583MessageWithTPDU("6000000001", messageHead: "603100310300", tradeType: tradeType, bitmap: bitmap, messageContent: messageContent)
    }
    
    /**
     打包8583报文
     
     - parameter TPDU:           TPDU
     - parameter messageHead:    报文头
     - parameter tradeType:      交易类型
     - parameter bitmap:         位图
     - parameter messageContent: 数据
     
     - returns: 报文数据
     */
    private class func pack8583MessageWithTPDU(TPDU:String, messageHead:String, tradeType:String, bitmap:[UInt8], messageContent:String)->NSData{
        // 数据长度(两个字符为一个字节长度): TPDU(5) + 报文头（6） + 交易类型(2) + 位图(8) + 数据长度
        let mesLength = TPDU.length/2 + messageHead.length/2 + tradeType.length/2 + 8 + messageContent.length/2
        var message = ""
        message += String.decIntToFourHexString(decNum: mesLength)
        message += TPDU
        message += messageHead
        message += tradeType
        message += String.createBitmap(bitmapArr: bitmap)
        message += messageContent
        
        return String.dataFromHexString(hexStr: message)
    }
    
    
    //MARK: 工具类
    /**
    获取位图数组
    
    - parameter posMess: 报文
    
    - returns: 位图数组
    */
    private class func getBitmapFromePosMess(posMess:PosMessage)->[UInt8] {
        
        var bitMap = [UInt8]()
        let propertys = posMess.getAllPropertys()
        
        for property in propertys{
            
            let value = posMess.getValueOfProperty(property) as! String
            
            if(property.hasPrefix("ED") && !value.isEmpty){
                let subED = property.substringFromIndex(property.startIndex.advancedBy(2))
                bitMap.append(UInt8(subED)!)
            }
        }
        
        return bitMap
    }
    
    /**
     组装报文content
     
     - parameter posMess: 报文数据
     
     - returns: 组装好的报文字符串
     */
    private class func create8583ContentWithMsg(posMess:PosMessage)->String {
        var result = ""
        let propertys = posMess.getAllPropertys()
        for(var i=0;i<propertys.count;i++){
            let property = propertys[i]
            let value = posMess.getValueOfProperty(property) as! String
            
            if(property.hasPrefix("ED") && !value.isEmpty){
                let temp = createElementWithElementName(property, elementContent: String(value))
                result += temp
            }
        }
        return result
    }
    
    /**
     组装某个域的报文内容（加入格式长度等）
     
     - parameter elementName:    域名
     - parameter elementContent: 域内容
     
     - returns: 组装好的域内容（加入格式长度等）
     */
    private class func createElementWithElementName(elementName:String, elementContent:String!)->String{
        
        var result = ""
        
        let element = EDConfig![elementName] as! NSDictionary
        let type = element["Type"] as! String
        let length = element["Length"] as! String
        
        if(type == "b"||type == "n"||type=="z"){
            if length.hasPrefix("..."){
            
                let tempLen = elementContent.length
                let contentLen = elementContent.getStringLengthWithTwoBytes()
                
                result += contentLen
                result += elementContent
                
                if(tempLen % 2 == 1){
                    result += "0"
                }
                
            }else if length.hasPrefix(".."){
                let tempLen = elementContent.length
                let contentLen = elementContent.getStringLengthWithOneBytes()
                
                result += contentLen
                result += elementContent
                
                if(tempLen % 2 == 1){
                    result += "0"
                }
            }else{
                let tempLen = elementContent.length
                let typeLen = Int(length)
                if(tempLen == typeLen){
                    result = elementContent
                }else{
                    print("数据长度有误：域\(elementName)长度为\(length)传入数据长度为\(tempLen)")
                }
            }
        }else if(type == "an"||type == "ans"){
            if length.hasPrefix("..."){
                let contentLen = elementContent.getStringLengthWithTwoBytes()
                
                result += contentLen
                result += String.ascStringFromHexString(elementContent)

            }else if length.hasPrefix(".."){
                let contentLen = elementContent.getStringLengthWithOneBytes()
                
                result += contentLen
                result += String.ascStringFromHexString(elementContent)
                
            }else{
                let tempLen = elementContent.length
                let typeLen = Int(length)
                if(tempLen == typeLen){
                    result = String.ascStringFromHexString(elementContent)
                }else{
                    print("数据长度有误：域\(elementName)长度为\(length)传入数据长度为\(tempLen)")
                }
            }
        }else if(type == "ic"){
            let tempLen = elementContent.length
            if(tempLen % 2 == 0){
                let tempStr = elementContent.substringToIndex(elementContent.startIndex.advancedBy(tempLen/2))
                let contentLen = tempStr.getStringLengthWithTwoBytes()
                
                result += contentLen
                result += elementContent
            }else{
                print("ic数据长度错误：数据长度应为偶数，传入数据长度为\(tempLen)")
            }
            
        }

        return result
    }
    
    /**
     获取相应域的内容
     
     - parameter elementName: 域名
     - parameter content:     域内容
     
     - returns: 解析出来的域内容
     */
    private class func getElementValueWithElementName(elementName:String, content:String)->String {
        var result = ""
        
        let element = EDConfig![elementName] as! NSDictionary
        let type = element["Type"] as! String
        let length = element["Length"] as! String
        
        if(type == "b"||type == "n"||type=="z"){
            if length.hasPrefix("..."){
                if content.length < 4 {
                    print("域解析出错:域\(elementName)双变长获取长度出错，content的标示长度应为4")
                    return result
                }
                let elementLen = Int(content.substringToIndex(content.startIndex.advancedBy(4)))
                let tempContent = content.substringFromIndex(content.startIndex.advancedBy(4))
                if tempContent.length < elementLen {
                    print("域解析出错:域\(elementName)content内容少于标示的长度,长度应为\(elementLen)")
                    return result
                }
                
                result = tempContent.substringToIndex(tempContent.startIndex.advancedBy(elementLen!))
                if elementLen! % 2 != 0{
                    tempMess = tempContent.substringFromIndex(tempContent.startIndex.advancedBy(elementLen!+1))
                }else{
                    tempMess = tempContent.substringFromIndex(tempContent.startIndex.advancedBy(elementLen!))
                }
                
            }else if length.hasPrefix(".."){
                if content.length < 2 {
                    print("域解析出错:域\(elementName)单变长获取长度出错，content的标示长度应为2")
                    return result
                }
                let elementLen = Int(content.substringToIndex(content.startIndex.advancedBy(2)))
                let tempContent = content.substringFromIndex(content.startIndex.advancedBy(2))
                if tempContent.length < elementLen {
                    print("域解析出错:域\(elementName)content内容少于标示的长度,长度应为\(elementLen)")
                    return result
                }
                
                result = tempContent.substringToIndex(tempContent.startIndex.advancedBy(elementLen!))
                if elementLen! % 2 != 0{
                    tempMess = tempContent.substringFromIndex(tempContent.startIndex.advancedBy(elementLen!+1))
                }else{
                    tempMess = tempContent.substringFromIndex(tempContent.startIndex.advancedBy(elementLen!))
                }
            }else{
                let typeLen = Int(length)
                if(content.length < typeLen){
                    print("域解析出错:域\(elementName)content内容少于标示的长度,长度应为\(typeLen)")

                }
                result = content.substringToIndex(content.startIndex.advancedBy(typeLen!
                    ))
                tempMess = content.substringFromIndex(content.startIndex.advancedBy(typeLen!
                    ))

            }
        }else if(type == "an"||type == "ans"){
            if length.hasPrefix("..."){
                if content.length < 4 {
                    print("域解析出错:域\(elementName)双变长获取长度出错，content的标示长度应为4")
                    return result
                }
                let elementLen = Int(content.substringToIndex(content.startIndex.advancedBy(4)))
                let tempContent = content.substringFromIndex(content.startIndex.advancedBy(4))
                if tempContent.length < 2*elementLen! {
                    print("域解析出错:域\(elementName)content内容少于标示的长度,长度应为\(2*elementLen!)")
                    return result
                }
                let temp = tempContent.substringToIndex(tempContent.startIndex.advancedBy(2*elementLen!))
                result = String.hexStringFromAscString(ascStr: temp)
                tempMess = tempContent.substringFromIndex(tempContent.startIndex.advancedBy(2*elementLen!))

                
            }else if length.hasPrefix(".."){
                if content.length < 2 {
                    print("域解析出错:域\(elementName)双变长获取长度出错，content的标示长度应为2")
                    return result
                }
                let elementLen = Int(content.substringToIndex(content.startIndex.advancedBy(2)))
                let tempContent = content.substringFromIndex(content.startIndex.advancedBy(2))
                if tempContent.length < 2*elementLen! {
                    print("域解析出错:域\(elementName)content内容少于标示的长度,长度应为\(2*elementLen!)")
                    return result
                }
                
                let temp = tempContent.substringToIndex(tempContent.startIndex.advancedBy(2*elementLen!))
                result = String.hexStringFromAscString(ascStr: temp)
                tempMess = tempContent.substringFromIndex(tempContent.startIndex.advancedBy(2*elementLen!))

            }else{
                let typeLen = Int(length)
                if(content.length < 2*typeLen!){
                    print("域解析出错:域\(elementName)content内容少于标示的长度,长度应为\(2*typeLen!)")
                    
                }
                let temp = content.substringToIndex(content.startIndex.advancedBy(2*typeLen!
                    ))
                result = String.hexStringFromAscString(ascStr: temp)

                tempMess = content.substringFromIndex(content.startIndex.advancedBy(2*typeLen!
                    ))

            }
        }else if(type == "ic"){
            if content.length < 4 {
                print("域解析出错:域\(elementName)双变长获取长度出错，content的标示长度应为4")
                return result
            }
            let elementLen = Int(content.substringToIndex(content.startIndex.advancedBy(4)))
            let tempContent = content.substringFromIndex(content.startIndex.advancedBy(4))
            if tempContent.length < 2*elementLen! {
                print("域解析出错:域\(elementName)content内容少于标示的长度,长度应为\(2*elementLen!)")
                return result
            }
            let temp = tempContent.substringToIndex(tempContent.startIndex.advancedBy(2*elementLen!))
            result = temp   
            tempMess = tempContent.substringFromIndex(tempContent.startIndex.advancedBy(2*elementLen!))

        }
        
        return result
    }
    
    
}
