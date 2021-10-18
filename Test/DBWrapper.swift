//
//  DBWrapper.swift
//  Test
//
//  Created by wyy on 2021/9/26.
//

import UIKit


//MARK: --  数据库定义普通字段 和 json和model互转
extension DBJSON {
    func run(_ a:String,_ b:Any) {
        
        print(a,b)
    }
    static func == (r:DBJSON,x:Any) -> DBJSON{
        
        r.condition = "\(r.key) = '\(x)'"
        return r
    }
    static func || (r:DBJSON,x:DBJSON) -> DBJSON{
        
        r.condition = "\(r.condition) || \(x.condition)"
        return r
    }
    
   
}

@propertyWrapper
class DBJSON<T> {
    var key:String
    var table:String?
    var condition:String = ""

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
    var projectedValue:DBJSON{
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


//MARK: --  数据库增，删，改，查


@propertyWrapper
class DBServer{
    
    private var table:String
    
    init(_ table:String){
        self.table = table
    }
    var wrappedValue:DBServer{
        get {return self}
        set {}
    }
    
    private var cacheTable = [Any]()
}
//buff
fileprivate extension DBServer {
    
    func setCacheMap(){
        
    }
}
//接口
extension DBServer {
    
    func selectOne<T>(_ type:T.Type,_ condition:(T)->Any) -> T?{
        if let an = analysisType(type,condition) {
            return DBSQL.select(table, an.0, an.1)?.first as? T
        }
       return nil
    }
    func select<T>(_ type:T.Type,_ condition:(T)->Any) -> [T]?{
        
        if let an = analysisType(type,condition) {
            return DBSQL.select(table, an.0, an.1) as? [T]
        }
        return nil
    }
    
    @discardableResult
    func insert(_ data:[JsonProtocol]) -> Bool{
        return DBSQL.insert(table, data)
    }
    
    @discardableResult
    func update<T>(_ type:T.Type,_ condition:(T)->Any,_ data:[JsonProtocol]) -> Bool{
        if let an = analysisType(type,condition) {
            return DBSQL.update(table, data, an.1)
        }
        return false
    }
    
    @discardableResult
    func delete<T>(_ type:T.Type,_ condition:(T)->Any) -> Bool{
        if let an = analysisType(type,condition) {
            return DBSQL.delete(table, an.1)
        }
        return false
    }
    
    @discardableResult
    func drop() -> Bool{
        return DBSQL.drop(table)
    }
    
    
}
fileprivate extension DBServer {
    
    func  analysisType<T>(_ t:T.Type,_ condition:(T)->Any) -> (JsonProtocol.Type,String)? {
        if let t1 = t as?  JsonProtocol.Type {
            let ob = t1.init([:])
            let co  = condition(ob as! T)
            if let c = co as? DBJSON<String> {
                print(c.condition)
                return (t1,c.condition)
            }else if let c = co as? DBJSON<Int> {
                print(c.condition)
                return (t1,c.condition)
            }else if let c = co as? DBJSON<Float> {
                print(c.condition)
                return (t1,c.condition)
            }else if let c = co as? DBJSON<Double> {
                print(c.condition)
                return (t1,c.condition)
            }
        }
        return nil
    }
}


