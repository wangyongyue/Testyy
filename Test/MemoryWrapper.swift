//
//  CacheWrapper.swift
//  Test
//
//  Created by wyy on 2021/9/26.
//

import UIKit

//MARK: --  简单存储
@propertyWrapper
struct Userdefault<T> {
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
            return UserDefaults.standard.object(forKey: key) as? T
        }
        set {
            if let value = newValue {
                UserDefaults.standard.setValue(value, forKey: key)
            }
            
        }
    }
    
}

@propertyWrapper
class Memory{
    private var cacheTable = MemoryManager()
    var wrappedValue:Memory{
        get {return self}
        set {}
    }
    
    
}

//接口
extension Memory {
    
    
    func selectOne<T>(_ type:T.Type,_ condition:(T)->Any) -> T?{
        if let an = analysisType(type,condition) {
            if let item = cacheTable.selectOneFromCache(an.1) {
                if let item = toModel(an.0, [item]){
                    return item.first as? T
                }
            }
        
        }
       return nil
    }
    
    func select<T>(_ type:T.Type,_ condition:(T)->Any) -> [T]?{
        if let an = analysisType(type,condition) {
            if let items = toModel(an.0, cacheTable.selectFromCache(an.1)) {
                return items as? [T]
            }
        }
        return nil
    }
    func selectAll<T>(_ type:T.Type) -> [T]?{
        
         if let t = type as? JsonProtocol.Type {
            if let items = toModel(t, cacheTable.selectFromCache("")) {
                if items.count > 0{
                    return items as? [T]
                }
            }

        }
        
        return nil
    }
    
    @discardableResult
    func delete<T>(_ type:T.Type,_ condition:(T)->Any) -> Bool{
        if let an = analysisType(type,condition) {
            return cacheTable.deleteFromCache(an.1)
        }
        return false
    }
    
    @discardableResult
    func insert(_ data:[JsonProtocol]) -> Bool{
        if data.count == 0 {
            return false
        }
        let array = toJson(data)
        return cacheTable.insertFromCache(array)
    }
    
    @discardableResult
    func update<T>(_ type:T.Type,_ condition:(T)->Any,_ data:JsonProtocol) -> Bool{
        
        if let an = analysisType(type,condition) {
            if let json = data.toJson() {
                return cacheTable.updateFromCache(an.1, json)
            }
        }
        return false
    }
    
    
   
}

//内存数据管理类
class MemoryManager{
    
    private var cacheTable = [Any]()
    
}
extension MemoryManager {
    
    func selectOneFromCache(_ condition:String) -> Any?{
        if cacheTable.isEmpty {return nil}
        for cache in cacheTable {
            if let item = cache as? [String:Any]{
                if expression(item, condition) {
                    return item
                }
            }
        }
       return nil
    }
    func selectFromCache(_ condition:String) -> [Any]?{
        if cacheTable.isEmpty {return nil}
        var limit = expressionLimit(condition)
        var array = [Any]()
        for cache in cacheTable {
            if let item = cache as? [String:Any]{
                if expression(item, condition) {
                    if limit > 0 {
                        array.append(item)
                        limit -= 1
                    }
                    
                }
            }
        }
        if array.count > 0 {
            return array
        }
       return nil
    
    }
    
    @discardableResult
    func insertFromCache(_ data:[Any]) -> Bool{
        if data.count == 0 {
            return true
        }
        for item in data {
            cacheTable.append(item)
        }
        return true
    }
    
    @discardableResult
    func updateFromCache(_ condition:String,_ data:[String:Any]) -> Bool{
        if cacheTable.isEmpty {return false}
        var i:Int = 0
        for cache in cacheTable {
            if let item = cache as? [String:Any]{
                if expression(item, condition) {
                    var newItem = item
                    for (key,value) in data {
                        newItem.updateValue(value, forKey:key)
                    }
                    cacheTable[i] = newItem

                }
            }
            i += 1
        }
        
       return true
    }
    
    @discardableResult
    func deleteFromCache(_ condition:String) -> Bool{
        if cacheTable.isEmpty {return false}
        var limit = expressionLimit(condition)
        var i:Int = 0
        for cache in cacheTable {
            if let item = cache as? [String:Any]{
                if expression(item, condition) {
                    if limit > 0 {
                        cacheTable.remove(at: i)
                        i -= 1
                        limit -= 1
                    }
                }
            }
            i += 1
        }
        
       return true
    }
}
