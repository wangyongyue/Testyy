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
    static func == (r:DBJSON,x:String) -> DBJSON{
        
        r.condition = "\(r.key) = '\(x)'"
        return r
    }
    static func == (r:DBJSON,x:Double) -> DBJSON{
        
        r.condition = "\(r.key) = '\(x)'"
        return r
    }
    static func || (r:DBJSON,x:DBJSON) -> DBJSON{
        
        r.condition = "\(r.condition) or \(x.condition)"
        return r
    }
    static func && (r:DBJSON,x:DBJSON) -> DBJSON{
        
        r.condition = "\(r.condition) and \(x.condition)"
        return r
    }
    
    static func > (r:DBJSON,x:Double) -> DBJSON{
        
        r.condition = "\(r.key) > '\(x)'"
        return r
    }
    static func < (r:DBJSON,x:Double) -> DBJSON{
        
        r.condition = "\(r.key) < '\(x)'"
        return r
    }
    static func >= (r:DBJSON,x:Double) -> DBJSON{
        
        r.condition = "\(r.key) >= '\(x)'"
        return r
    }
    static func <= (r:DBJSON,x:Double) -> DBJSON{
        
        r.condition = "\(r.key) <= '\(x)'"
        return r
    }
    func limit(_ x:Int) -> DBJSON {
        self.condition = self.condition + " limit \(x)"
        return self
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
        //初始化时更新数据库
        DBSQL.commit()
    }
   
    var wrappedValue:DBServer{
        get {return self}
        set {}
    }
    
}

//接口
extension DBServer {
    
    func selectOne<T>(_ type:T.Type,_ condition:(T)->Any) -> T?{
        if let an = analysisType(type,condition) {
        
            if let item = toModel(an.0, DBSQL.select(table, an.1)){
                return item.first as? T
            }
        }
       return nil
    }
    
    func select<T>(_ type:T.Type,_ condition:(T)->Any) -> [T]?{
        if let an = analysisType(type,condition) {
            
            if let items = toModel(an.0,DBSQL.select(table, an.1)) {
                return items as? [T]
            }
        }
        return nil
    }
    
    func selectAll<T>(_ type:T.Type) -> [T]?{
         if let t = type as? JsonProtocol.Type {
            
            if let items = toModel(t, DBSQL.select(table, "")) {
                return items as? [T]
            }
        }
        
        return nil
    }
    
    @discardableResult
    func delete<T>(_ type:T.Type,_ condition:(T)->Any) -> Bool{
        if let an = analysisType(type,condition) {
            return DBSQL.delete(table, an.1)
        }
        return false
    }
    
    @discardableResult
    func insert(_ data:[JsonProtocol]) -> Bool{
        let array = toJson(data)
        return DBSQL.insert(table, array)
    }
    
    @discardableResult
    func update<T>(_ type:T.Type,_ condition:(T)->Any,_ data:JsonProtocol) -> Bool{
        
        if let an = analysisType(type,condition) {
            if let json = data.toJson() {
                return DBSQL.update(table, json, an.1)
            }
        }
        return false
    }
    
    func commit() {
        DBSQL.commit()
    }
    
}

func  analysisType<T>(_ t:T.Type,_ condition:(T)->Any) -> (JsonProtocol.Type,String)? {
    if let t1 = t as? JsonProtocol.Type {
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
        }else{
            return (t1,"")
        }
    }
    return nil
}


func toJson(_ data:[JsonProtocol]) -> [Any] {
    var array = [Any]()
    for item in data {
        if let js = item.toJson() {
            array.append(js)
        }
    }
    return array
}
func toModel(_ type:JsonProtocol.Type,_ data:[Any]?) -> [JsonProtocol]?{
    if let items = data {
        var array = [JsonProtocol]()
        for item in items {
            if let js = item as? [String:Any] {
                array.append(type.init(js))
            }
        }
        return array
    }
    return nil
}


//表达式解析
func expressionLimit(_ condition:String) -> Int{
    
    let strs = condition.components(separatedBy: " ")
    for str in strs {
        if str == "limit" {
            if let limit = Int(strs.last!){
                return limit
            }
        }
    }
    return 999999
}
func expression(_ json:[String:Any],_ condition:String) -> Bool{
    if condition.count == 0 {
        return true
    }
    let pa = json
    let strs = condition.components(separatedBy: " ")
    var array = [String]()
    for str in strs {
        if str == "limit" {
            break
        }
        array.append(str.replacingOccurrences(of: " ", with: ""))
    }
    var stack = [String]()
    while array.count > 0 {
        let firt = array[0]
        stack.append(firt)
        array.removeFirst()
        if stack.count > 2 && stack[1] == "="{
            if let p =  pa[stack[0]] {
                let p1 = "\(p)"
                let p2 = stack[2].replacingOccurrences(of: "\'", with: "")
                if  stack[1] == "=" {
                    if p1 == p2 {
                        stack.removeAll()
                        stack.append("yes")
                    }else {
                        stack.removeAll()
                        stack.append("no")
                    }
                }else if stack[1] == ">" {
                    if let v1 = Double(p1) ,let v2 = Double(p2){
                        if v1 > v2 {
                            stack.removeAll()
                            stack.append("yes")
                        }else {
                            stack.removeAll()
                            stack.append("no")
                        }
                        
                    }
                }else if stack[1] == "<" {
                    if let v1 = Double(p1) ,let v2 = Double(p2){
                        if v1 < v2 {
                            stack.removeAll()
                            stack.append("yes")
                        }else {
                            stack.removeAll()
                            stack.append("no")
                        }
                        
                    }
                }else if stack[1] == "<=" {
                    if let v1 = Double(p1) ,let v2 = Double(p2){
                        if v1 <= v2 {
                            stack.removeAll()
                            stack.append("yes")
                        }else {
                            stack.removeAll()
                            stack.append("no")
                        }
                        
                    }
                }else if stack[1] == ">=" {
                    if let v1 = Double(p1) ,let v2 = Double(p2){
                        if v1 >= v2 {
                            stack.removeAll()
                            stack.append("yes")
                        }else {
                            stack.removeAll()
                            stack.append("no")
                        }
                        
                    }
                }
                
            }else{
                print("no")
            }
        }
        if stack.count > 1 && stack[1] == "or" {
            if stack[0] == "yes" {
                print("yes")
                return true
            }else {
                stack.removeAll()
            }
        }
        if stack.count > 1 && stack[1] == "and" {
            if stack[0] == "no" {
                print("no")
                return false
            }else {
                stack.removeAll()
            }
        }
        if stack.count == 1 && array.count == 0{
            if stack[0] == "yes" {
                print("yes")
                return true
            }else if stack[0] == "no"{
                print("no")
                return false
            }
        }
    }
    
    
    return false
}
