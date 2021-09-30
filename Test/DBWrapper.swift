//
//  DBWrapper.swift
//  Test
//
//  Created by wyy on 2021/9/26.
//

import UIKit


//MARK: --  数据库定义普通字段 和 json和model互转
@propertyWrapper
class DBJSON<T> {
    var key:String
    var table:String?
    
    init(_ key: String){
        self.key = key
    }
    init(_ table:String,_ key: String){
        self.key = key
        self.table = table
        DBSQL.setUpTableAndKeys(table,key)

    }
    var defaultValue:T?
    var wrappedValue: T?{
        
        get {return defaultValue}
        set {defaultValue = newValue}
    }
    var projectedValue:DBJSON?{
        get{return self}
        set{}
    }
    
    func getJson() -> [String:Any]?{
        if let value = defaultValue {
            return [key:value]
        }
        return nil
    }
    func setJson(_ json:[String:Any]?){
        defaultValue = json?[key] as? T
    }
}
//MARK: --  动态参数

@dynamicMemberLookup
class DBParams {
    var params = [String: Any]()
    subscript<T>(dynamicMember member: String)  -> T? where T: Any {
        get { params[member] as? T }
        set { params[member] = newValue }
    }
}


//MARK: --  数据库增，删，改，查

@propertyWrapper
class DBInsert{
    private var table:String
    init(_ table:String){
        self.table = table
    }
    var wrappedValue: DBInsert{
        get {return self}
        set {}
    }
    func run(_ data:[JsonProtocol]) -> Bool{
        return DBSQL.insert(table, data)
    }
    
}
@propertyWrapper
class DBUpate:DBParams{
    var table:String
    var type:JsonProtocol.Type
    init(_ table:String,_ type:JsonProtocol.Type){
        self.table = table
        self.type = type
    }
    
    var wrappedValue: DBUpate{
        get {return self}
        set {}
    }
    func run(_ data:[JsonProtocol]) -> Bool{
        return DBSQL.update(table, data, params)
    }
}

@propertyWrapper
class DBDelete:DBParams{
    var table:String
    init(_ table:String){
        self.table = table
    }
    var wrappedValue: DBDelete{
        get {return self}
        set {}
    }
    func run(_ data:[JsonProtocol]) -> Bool{
        return DBSQL.delete(table, params)
    }
}

@propertyWrapper
class DBDeleteAll:DBParams{
    var table:String
    init(_ table:String){
        self.table = table
    }
    var wrappedValue: DBDeleteAll{
        get {return self}
        set {}
    }
    func run(_ data:[JsonProtocol]) -> Bool{
        return DBSQL.deleteAll(table)
    }
}
@propertyWrapper
class DBSelect<T>:DBParams{
    private var table:String
    private var type:JsonProtocol.Type
    
    init(_ table:String,_ type:JsonProtocol.Type){
        self.table = table
        self.type = type
    }
    private var result:T?
    var wrappedValue: T?{
        get {
            if result == nil {
                if let list = DBSQL.select(table, type, params) {
                    result = list as? T
                }
            }
            return result
        }
        set {result = nil}
    }
    
    var projectedValue:DBSelect{
        get{return self}
        set{}
    }

}

@propertyWrapper
class DBSelectAll<T>{
    private var table:String
    private var type:JsonProtocol.Type
    init(_ table:String,_ type:JsonProtocol.Type){
        self.table = table
        self.type = type
    }
    var result:T?
    var wrappedValue: T?{
        get {
            if result == nil {
                if let list = DBSQL.selectAll(table, type) {
                    result = list as? T
                }
            }
            return result
        }
        set {
            result = nil
        }
    }

    
}

@propertyWrapper
class DBDrop{
    private var table:String
    init(_ table:String){
        self.table = table
    }
    var wrappedValue: Bool{
        get {
            return DBSQL.drop(self.table)
        }
        set {}
    }
}

