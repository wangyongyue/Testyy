//
//  CacheWrapper.swift
//  Test
//
//  Created by wyy on 2021/9/26.
//

import UIKit

//MARK: --  简单存储
@propertyWrapper
class Userdefault<T> {
    let key:String
    var defaultValue:T?
    init(_ key: String){
        self.key = key
    }
    init(_ key: String, _ defaultValue: T){
        self.key = key
        self.defaultValue = defaultValue
    }
    var wrappedValue: T?{
        get {
            if defaultValue == nil {
                defaultValue = UserDefaults.standard.object(forKey: key) as? T
            }
            return defaultValue
        }
        set {
            if let value = newValue {
                UserDefaults.standard.setValue(value, forKey: key)
                defaultValue = nil
            }else{
                UserDefaults.standard.removeObject(forKey: key)
            }
            
        }
    }
    
}

@propertyWrapper
class Memory<T> {
    let key:String
    let type:(JsonProtocol.Type)?
    var defaultValue:T?
    
    init(_ key: String){
        self.key = key
        self.type = nil
    }
    init(_ key: String, _ type: JsonProtocol.Type){
        self.key = key
        self.type = type
    }

    var wrappedValue: T?{
        get {
            if defaultValue == nil {
                if let ty = type {
                    defaultValue = KVMemory.instance.get(key, ty)
                }else{
                    defaultValue = KVMemory.instance.get(key)
                }
            }
            return defaultValue
        }
        set {
            if let value = newValue {
                KVMemory.instance.set(key, value)
                defaultValue = nil
            }
            
        }
    }
    var projectedValue:Memory{
        get{return self}
        set{}
    }
    
}
//数据缓存，内存中
class KVMemory {
    
    static let instance = KVMemory()
    private var hashTable:[AnyHashable:Any]
    init() {
        hashTable = [AnyHashable:Any]()
    }
    func set<T>(_ key:AnyHashable,_ value:T){
        var temp:Any?
        if value is JsonProtocol {
            
            if let v = value as? JsonProtocol {
                temp = v.toJson()
            }
        }else if value is [JsonProtocol] {
            
            if let v = value as? [JsonProtocol] {
                var list = [Any]()
                for item in v {
                    if let json = item.toJson(){
                        list.append(json)
                    }
                }
                temp = list
            }
        }else if value is Date{
            
            if let v = value as? Date{
                temp = v.timeIntervalSince1970
            }
        }else{
            
            temp = value
        }
        if let te = temp{
            hashTable.updateValue(te, forKey: key)
        }
    }
    func get<T>(_ key:AnyHashable,_ type:JsonProtocol.Type) ->T?{
        
        let value = hashTable[key]
        if value is [Any] {
            return toModelArray(value as? [Any],type) as? T
        }
        return type.init(value as? [String:Any]) as? T
    }
    
    
    func get<T>(_ key:AnyHashable) ->T?{
        let value = hashTable[key]
        if T.self is Date.Type {
            if value is Double {
                if let v = value as? Double {
                    return Date(timeIntervalSince1970: v)  as? T
                }
            }
        }
        return value as? T
    }
    
}

