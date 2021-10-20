//
//  DMJSON.swift
//  Test
//
//  Created by wyy on 2021/9/14.
//

import UIKit
import Metal


/*
 @dynamicMemberLookup 动态属性查找，可以像解释型语言一样，动态增加class属性
 变量 orData 是输入的最开始的数据副本
 变量 cuData 是当前解析中的数据
 DMJSON 使用链式语法解析json数据
 */
@dynamicMemberLookup
class DMJSON{
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
   
    subscript(dynamicMember member:String) -> DMJSON{
    
        analysis(member)
        return self
    }
    
}

/*
 对外接口，arrar, dic,int,float,double,string
 返回值都会默认值，不会为nil
 */

extension DMJSON {
    var array:[DMJSON]{
        get{
            var list = [DMJSON]()
            if let data = cuData {
                if let array = data as? [Any] {
                    for item in array{
                        list.append(DMJSON(item))
                    }
                }
            }
            cuData = orData
            return list
        }
    }
    var dictionary:[String:DMJSON]{
        get{
            var dic = [String:DMJSON]()
            if let data = cuData {
                if let da = data as? [String:Any] {
                    for (k,v) in da {
                        dic[k] = DMJSON(v)
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
/*
 对输入数据进行初步解析和判断
 */

fileprivate extension DMJSON {
    func toJson(_ data:Any){
        cuData = orData
    }
    
    /*
     jsonString转成json
     */
    func stringToJson(_ data:String){
        if let value = data.data(using: .utf8) {
            orData = try? JSONSerialization.jsonObject(with: value, options: .mutableContainers)
            cuData = orData
        }
    }
    
    /*
     data转成json
     */
    func dataToJson(_ data:Data){
        orData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        
        cuData = orData
    }
    
    /*
     如果当前数据是一个数组且属性值是int类型，当作下标解析
     */
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

