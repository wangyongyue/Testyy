//
//  WJSON.swift
//  Test
//
//  Created by wyy on 2021/9/14.
//

import UIKit
import Metal


@dynamicMemberLookup
class WJSON{
    private var orData:Any?
    private var cuData:Any?
    init(_ value:Any?) {
        if let va = value {
            toJson(va)
        }
    }
    init(_ value:String?) {
        if let va = value {
            stringToJson(va)
        }
    }
    init(_ value:Data?) {
        if let va = value {
            dataToJson(va)
        }
    }
   
    subscript(dynamicMember member:String) -> WJSON{
    
        analysis(member)
        return self
    }
    
}


//MARK: -- 转换基本数据类型
extension WJSON {
    var array:[WJSON]{
        get{
            var list = [WJSON]()
            if let data = cuData {
                if let array = data as? [Any] {
                    for item in array{
                        list.append(WJSON(item))
                    }
                }
            }
            cuData = orData
            return list
        }
    }
    var dictionary:[String:WJSON]{
        get{
            var dic = [String:WJSON]()
            if let data = cuData {
                if let da = data as? [String:Any] {
                    for (k,v) in da {
                        dic[k] = WJSON(v)
                    }
                }
            }
            cuData = orData
            return dic
        }
    }
    var string:String{
        get{
            var re = ""
            if let data = cuData {
                if let str = data as? String {
                    re = str
                }
            }
            cuData = orData
            return re
        }
    }
    var int:Int{
        get{
            var re = 0
            if let data = cuData {
                if let str = data as? Int {
                    re = str
                }
            }
            cuData = orData
            return re
        }
    }
    var float:Float{
        get{
            var re:Float = 0.0
            if let data = cuData {
                if let str = data as? Float {
                    re = str
                }
            }
            cuData = orData
            return re
        }
    }
    var double:Double{
        get{
            var re = 0.0
            if let data = cuData {
                if let str = data as? Double {
                    re = str
                }
            }
            cuData = orData
            return re
        }
    }
    var bool:Bool{
        get{
            if let data = cuData {
                if let str = data as? Bool {
                    return str
                }
            }
            cuData = orData
            return false
        }
    }
}

//MARK: -- 类型判断解析json
fileprivate extension WJSON {
    func toJson(_ data:Any){
        cuData = orData
    }
    func stringToJson(_ data:String){
        if let value = data.data(using: .utf8) {
            orData = try? JSONSerialization.jsonObject(with: value, options: .mutableContainers)
            cuData = orData
        }
    }
    func dataToJson(_ data:Data){
        orData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        
        cuData = orData
    }
    
    func analysis(_ key:String) {
        
        if let data = cuData {
            if data is [Any] {
                if let index = Int(key){
                    if let array = data as? [Any] {
                        cuData = array[index]
                    }
                }
                
            }else if data is [String:Any] {
                if let dic = data as? [String:Any] {
                    if let some = dic["some"] as? [String:Any] {
                        cuData = some[key]
                    }else{
                        cuData = dic[key]
                    }
                    
                }
            }
        }
    }
}

