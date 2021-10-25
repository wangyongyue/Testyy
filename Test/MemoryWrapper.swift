//
//  CacheWrapper.swift
//  Test
//
//  Created by wyy on 2021/9/26.
//

import UIKit


/*
 简单存储
 */
@propertyWrapper
public struct Userdefault<T> {
    private let key:String
    private var defaultValue:T?
    
    /*
     初始化指定key
     */
    public init(_ key: String){
        self.key = key
    }
    
    /*
     初始化指定key
     指定默认值
     */
    public init(_ key: String, _ defaultValue: T){
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T?{
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


/*
 内存数据缓冲
 */
@propertyWrapper
public class Memory{
    private let cacheTable = MemoryManager()
    public var wrappedValue:Memory{
        get {return self}
        set {}
    }
    public init(){}
}



public extension Memory {
    
    /*
     查询单个数据
     参数：
     type      数据类型
     condition 条件语句
     */
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
    
    /*
     查询数据
     参数：
     type      数据类型
     condition 条件语句
     */
    func select<T>(_ type:T.Type,_ condition:(T)->Any) -> [T]?{
        if let an = analysisType(type,condition) {
            if let items = toModel(an.0, cacheTable.selectFromCache(an.1)) {
                return items as? [T]
            }
        }
        return nil
    }
    
    /*
     查询全部数据
     参数：
     type      数据类型
     */
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
    
    /*
     删除数据
     参数：
     type      数据类型
     condition 条件语句
     */
    @discardableResult
    func delete<T>(_ type:T.Type,_ condition:(T)->Any) -> Bool{
        if let an = analysisType(type,condition) {
            return cacheTable.deleteFromCache(an.1)
        }
        return false
    }
    
    
    /*
     新增数据
     参数：
     data      数据内容
     */
    @discardableResult
    func insert(_ data:[JsonProtocol]) -> Bool{
        if data.count == 0 {
            return false
        }
        let array = toJson(data)
        return cacheTable.insertFromCache(array)
    }
    
    
    /*
     更新数据
     参数：
     type      数据类型
     condition 条件语句
     data      更新数据内容
     */
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

/*
 内存数据管理类
 */
class MemoryManager{
    
    private var cacheTable = [Any]()
    
}
extension MemoryManager {
    
    /*
     查询单个数据
     参数：
     type      数据类型
     condition 条件语句
     */
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
    
    /*
     查询数据
     参数：
     type      数据类型
     condition 条件语句
     */
    func selectFromCache(_ condition:String) -> [Any]?{
        if cacheTable.isEmpty {return nil}
        if var limit = expressionLimit(condition) {
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
        }else{
            var array = [Any]()
            for cache in cacheTable {
                if let item = cache as? [String:Any]{
                    if expression(item, condition) {
                        array.append(item)
                    }
                }
            }
            if array.count > 0 {
                return array
            }
        }
        
       return nil
    
    }
    
    /*
     新增数据
     参数：
     data      数据内容
     */
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
    
    /*
     更新数据
     参数：
     type      数据类型
     condition 条件语句
     data      更新数据内容
     */
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
    
    /*
     删除数据
     参数：
     type      数据类型
     condition 条件语句
     */
    @discardableResult
    func deleteFromCache(_ condition:String) -> Bool{
        if cacheTable.isEmpty {return false}
        if var limit = expressionLimit(condition) {
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
        }else {
            var i:Int = 0
            for cache in cacheTable {
                if let item = cache as? [String:Any]{
                    if expression(item, condition) {
                        cacheTable.remove(at: i)
                        i -= 1
                    }
                }
                i += 1
            }
        }
        
       return true
    }
}
