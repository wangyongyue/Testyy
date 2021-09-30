//
//  JsonWrapper.swift
//  Test
//
//  Created by wyy on 2021/9/26.
//

import UIKit


protocol JsonProtocol {
    init(_ data:[String:Any]?)
    func toJson() -> [String:Any]?
}
func mergeMap(_ m:[String:Any]?...) -> [String:Any]? {
    var dic = [String:Any]()
    for item in m{
        if let it = item {
            for (k,v) in it {
                dic[k] = v
            }
        }
    }
    return dic
}
func toJsonArray(_ data:[Any]?,_ type:JsonProtocol.Type) -> [Any]{
    
    var list = [Any]()
    if let jsonData = data{
        for item in jsonData {
            let model = type.init(item as? [String:Any])
            list.append(model)
        }
    }
    return list
    
}
func toModelArray(_ data:[Any]?,_ type:JsonProtocol.Type) -> [JsonProtocol]{
    
    var list = [JsonProtocol]()
    if let jsonData = data{
        for item in jsonData {
            let model = type.init(item as? [String:Any])
            list.append(model)
        }
    }
    return list
    
}



@propertyWrapper
class TOJSONArray<T>{
    
    var type:JsonProtocol.Type
    init(_ type:JsonProtocol.Type){
        self.type = type
    }
  
    var defaultValue:T?
    var wrappedValue: T?{
        
        get {return defaultValue}
        set {
            defaultValue = newValue
        }
    }
   
    var projectedValue:TOJSONArray{
        get{return self}
        set{}
    }
    func run(_ newValue:[Any]?) -> T?{
        var list = [JsonProtocol]()
        if let jsonData = newValue{
            for item in jsonData {
                let model = type.init(item as? [String:Any])
                list.append(model)
            }
        }
        defaultValue = list as? T
        return defaultValue
    }
}

@propertyWrapper
class TOModelArray<T>{
    
    var type:JsonProtocol.Type
    init(_ type:JsonProtocol.Type){
        self.type = type
    }
  
    var defaultValue:T?
    var wrappedValue: T?{
        
        get {return defaultValue}
        set {
            defaultValue = newValue
        }
    }
    var projectedValue:TOModelArray{
        get{return self}
        set{}
    }
    func run(_ newValue:[JsonProtocol]?) -> T?{
        var list = [Any]()
        if let jsonData = newValue{
            for item in jsonData {
                let model = item.toJson()
                list.append(model)
            }
        }
        defaultValue = list  as? T
        return defaultValue
    }
   
}



