# SwiftPos
这是一个swift版的报文组装工具


注意：
使用前请先对照IsoConfig.plist 文件中各个域对应的类型长度是否与你的相同，不同的地方修改成你需要的

用法：

生成报文：

  1、直接创建 PosMessage 对象，然后传入各个域的值。
  
  2、必传的有交易类型和各个域的值，TPDU和报文头设有默认值可不传。
  
  3、位图会根据传入的域对象自己生成然后加入报文中，不用再做特殊处理

解析报文：

  1、传入不带总报文长度的（即截取掉前面四位长度信息的）报文字符串
  
  2、解析完成后返回一个 PosMessage 对象。如果对应的域没有值，则为对应属性值为 ""

用例：

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
  
  


如有问题欢迎联系我,我会尽快完善。  QQ:413281269 -- LC
