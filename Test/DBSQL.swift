//
//  DBSQL.swift
//  Test
//
//  Created by wyy on 2021/9/14.
//

import UIKit
import SQLite3
let sql_queue = DispatchQueue(label: "com.sql.queue") //同步队列
class DBSQL {
    private var db:OpaquePointer?
    private static let instance = DBSQL()
    let lock = NSLock()

    init() {
        open()
    }
    
}
// 缓存数据库表和字段
extension DBSQL {
    
    static func setUpTableAndKeys(_ table:String,_ key:String){
        
        if let keys = UserDefaults.standard.array(forKey: table) as? [String]{
            var isHave = false
            for item in keys {
                if key == item{
                    isHave = true
                }
            }
            if isHave == false && alter(table, key){
                var list = keys
                list.append(key)
                sql_queue.sync {
                    UserDefaults.standard.setValue(list, forKey: table)
                }
            }
        }else{
            if create(table) {
                sql_queue.sync {
                    UserDefaults.standard.setValue(["t_id"], forKey: table)
                }
            }
        }
        
    }
    
}
// 数据库表的操作
extension DBSQL {
    
   static func create(_ tableName:String) -> Bool {
        var res = false
        sql_queue.sync {

            let sql = "create table if not exists \(tableName) (t_id integer)"
            res = instance.exec(sql)
        }
        return res
    }
    
    static func alter(_ tableName:String,_ key:String) -> Bool {
        var res = false
        sql_queue.sync {

            let q_sql = "SELECT * from sqlite_master where name = '\(tableName)' and sql like '%\(key)%'"
            if instance.queryCount(q_sql) >= 1 {
                res = true
            }
            let sql = "alter table \(tableName) add \(key) text"
            res = instance.exec(sql)
        }
        return res
    }
    
    
    
    
}
// 对外公共接口
extension DBSQL{
    
    static func drop(_ tableName:String) -> Bool {
        
        var res = false
        sql_queue.sync {

            //删除本地缓存表
            UserDefaults.standard.removeObject(forKey: tableName)

            let sql = "drop table \(tableName)"
            res = instance.exec(sql)
        }
        return res
    }
    static func paramsToKeysAndValues(_ params:[String:Any]) -> (keys:[String],values:[Any]){
        
        var keys = [String]()
        var values = [Any]()
        for (k,v) in params{
            keys.append(k)
            values.append(v)
        }
        return (keys,values)
    }
    static func delete(_ tableName:String,_ params:[String:Any]) -> Bool {
        var res = false
        sql_queue.sync {
            res = instance.deleteJson(tableName, keys: paramsToKeysAndValues(params).keys, values: paramsToKeysAndValues(params).values)
        }
        return res
    }
    static func deleteAll(_ tableName:String) -> Bool {
        var res = false
        sql_queue.sync {
            res = instance.deleteAllJson(tableName)
        }
        return res
    }
    static func insert(_ tableName:String,_ data:[JsonProtocol]) -> Bool {
        
        var res = false
        sql_queue.sync {
            for item in data {
                if let json = item.toJson() {
                    res = instance.insertJson(tableName, json)
                }
            }
        }
        return res
    }
    
    static func update(_ tableName:String,_ data:[JsonProtocol],_ params:[String:Any]) -> Bool {
        
        var res = false
        sql_queue.sync {
            for item in data {
                if let json = item.toJson() {
                    res = instance.updateJson(tableName, paramsToKeysAndValues(params).keys, paramsToKeysAndValues(params).values,json)
                }
            }
        }
        return res
    }
    
    static func selectAll(_ tableName:String,_ type:JsonProtocol.Type) -> [JsonProtocol]?{
        var res:[JsonProtocol]?
        sql_queue.sync {
            res = instance.getList(instance.selectAllJson(tableName), type)
        }
        return res
    }
    
    static func select(_ tableName:String,_ type:JsonProtocol.Type,_ params:[String:Any]) -> [JsonProtocol]?{
        var res:[JsonProtocol]?
        sql_queue.sync {
            res = instance.getList(instance.selectJson(tableName, type, paramsToKeysAndValues(params).keys, paramsToKeysAndValues(params).values), type)
        }
        return res
    }
    
    
}
//sql 接口
extension DBSQL {
    static func execSql(_ sql:String,values:[Any]) -> Bool{
        return instance.exec(instance.replaceSql(Sql: sql, values: values))
    }
    static func querySql(_ sql:String,values:[Any]) -> [Any]? {
        return instance.query(instance.replaceSql(Sql: sql, values: values))
    }
}


fileprivate extension DBSQL {
    func deleteAllJson(_ tableName:String) -> Bool {
        
        let sql = "delete from \(tableName)"
        return exec(sql)
    }
    func deleteJson(_ tableName:String,keys:[String],values:[Any]) -> Bool {
        
        
        if keys.count != values.count {return false}
        var kv = ""
        for i in 0..<keys.count {
            if kv.count == 0{
                kv = keys[i] + " = " + "'\(values[i])'"
            }else{
                kv = kv + " and " + keys[i] + "'\(values[i])'"
            }
        }
        let sql = "delete from \(tableName) where \(kv)"
        return exec(sql)
    }
    func insertJson(_ tableName:String,_ json:[String:Any]) -> Bool {
        var keys = ""
        var values = ""
        for (k,v) in json {
            if keys.count == 0{
                keys = "\(k)"
            }else {
                keys = keys + "," + "'\(k)'"
            }
            
            if values.count == 0{
                values = "\(v)"
            }else {
                values = values + "," + "'\(v)'"
            }
            
        }
        let sql = "insert into \(tableName) (\(keys)) values (\(values))"
        return exec(sql)
    }
    
    func updateJson(_ tableName:String,_ keys:[String],_ values:[Any],_ json:[String:Any]) -> Bool {
        
        var condition = ""
        for i in 0..<keys.count {
            if i < values.count {
                if condition.count == 0{
                    condition = keys[i] + " = " + "'\(values[i])'"
                }else{
                    condition = condition + " and " + keys[i] + "'\(values[i])'"
                }
            }
            
        }
        if condition.count > 0 {
            var kv = ""
            for (k,v) in json {
                if kv.count == 0{
                    kv = "\(k) = '\(v)'"
                }else {
                    kv = kv + ", " + "\(k) = '\(v)'"
                }
            }
            let sql = "update \(tableName) set \(kv) where \(condition)"
            return exec(sql)
        }
        return false
    }
    
    func selectJson(_ tableName:String,_ type:JsonProtocol.Type,_ keys:[String],_ values:[Any]) -> [Any]? {
        
        var condition = ""
        for i in 0..<keys.count {
            if condition.count == 0{
                condition = keys[i] + " = " + "'\(values[i])'"
            }else{
                condition = condition + " and " + keys[i] + "'\(values[i])'"
            }
        }
        let sql = "select * from \(tableName)  where \(condition)"
        return query(sql)
    }
    func selectAllJson(_ tableName:String) -> [Any]? {
        let sql = "select * from \(tableName)"
        return query(sql)
    }
    
    
    func getList(_ data:[Any]?,_ type:JsonProtocol.Type) -> [JsonProtocol]?{
        var list = [JsonProtocol]()
        if let jsonData = data {
            for item in jsonData {
                let model = type.init(item as? [String:Any])
                list.append(model)
            }
        }
        if list.count == 0 {
            return nil
        }
        return list
    }
    
}

fileprivate extension DBSQL {
    func replaceSql(Sql:String,values:[Any]) -> String {
        var newSql = ""
        var c = 0
        for i in Sql {
            if String(i) == "?" && c < values.count {
                newSql = newSql + "'\(values[c])'"
                c += 1
            }
        }
        return newSql
    }
}



//MARK: - 创建数据库，增删改查
fileprivate extension DBSQL {
    
    func open() -> Bool {
        let filePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        print(filePath)
        let file = filePath + "/test.sqlite"
        let cfile = file.cString(using: String.Encoding.utf8)
        let state = sqlite3_open(cfile, &db)
        if state != SQLITE_OK {
            print("打开数据库失败")
            return false
        }
        return true
    }
    func exec(_ sql:String) -> Bool{
        
        let csql = sql.cString(using: String.Encoding.utf8)
         
        if sqlite3_exec(db, csql, nil, nil, nil) == SQLITE_OK {
            print("执行成功")
            return true
        }
        print("执行失败")
        return false
    }
    
    func query(_ sql:String) -> [Any]? {
        var statement:OpaquePointer? = nil
        let csql = sql.cString(using: String.Encoding.utf8)
        if sqlite3_prepare(db, csql, -1, &statement, nil) != SQLITE_OK {
            print("未准备好")
            return nil
        }
        var temArr = [Any]()
        while sqlite3_step(statement) == SQLITE_ROW {
            
            let columns = sqlite3_column_count(statement)
            var row = [String:Any]()
                            
            for i in 0..<columns {
                let type = sqlite3_column_type(statement, i)
                let chars = UnsafePointer<CChar>(sqlite3_column_name(statement, i))
                let name =  String.init(cString: chars!, encoding: String.Encoding.utf8)

                if sqlite3_column_text(statement, i) != nil ,let n = name{
                    let value = String.init(cString: sqlite3_column_text(statement, i))
                    row.updateValue(value, forKey: n)
                    if let n = name{
                        print("准备好 \(n):\(value)")
                    }
                    
                }
                
            }
            temArr.append(row)

        }
        
        return temArr
        
    }

    func queryValue(_ sql:String) -> Any? {
        var statement:OpaquePointer? = nil
        let csql = sql.cString(using: String.Encoding.utf8)
        if sqlite3_prepare(db, csql, -1, &statement, nil) != SQLITE_OK {
            print("未准备好")
            return nil
        }
        var value:Any?
        while sqlite3_step(statement) == SQLITE_ROW {
            
            let columns = sqlite3_column_count(statement)
                            
            for i in 0..<columns {
                let type = sqlite3_column_type(statement, i)
                let chars = UnsafePointer<CChar>(sqlite3_column_name(statement, i))
                let name =  String.init(cString: chars!, encoding: String.Encoding.utf8)

                if sqlite3_column_text(statement, i) != nil ,let n = name{
                    value = String.init(cString: sqlite3_column_text(statement, i))
                    print("准备好\(value)")
                }
                
            }

        }
        return value
        
    }
    func queryCount(_ sql:String) -> Int {
        var statement:OpaquePointer? = nil
        let csql = sql.cString(using: String.Encoding.utf8)
        if sqlite3_prepare(db, csql, -1, &statement, nil) != SQLITE_OK {
            print("未准备好")
            return 0
        }
        var value:Int = 0
        while sqlite3_step(statement) == SQLITE_ROW {
            
            value += 1

        }
        return value
        
    }
    
}

