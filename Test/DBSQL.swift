//
//  DBSQL.swift
//  Test
//
//  Created by wyy on 2021/9/14.
//

import UIKit
import SQLite3
let sql_queue = DispatchQueue(label: "com.sql.queue") //同步队列
let sql_log_key = "sql_log_key"
class DBSQL {
    private var db:OpaquePointer?
    private static let instance = DBSQL()
    let lock = NSLock()

    init() {
       let isOpen =  open()
        if isOpen {
            print("数据库打开")
        }
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
        let sql = "create table if not exists \(tableName) (t_id integer)"
        res = instance.exec(sql)
        return res
    }
    
    static func alter(_ tableName:String,_ key:String) -> Bool {
        var res = false
        let q_sql = "SELECT * from sqlite_master where name = '\(tableName)' and sql like '%\(key)%'"
        if instance.queryCount(q_sql) >= 1 {
            res = true
        }
        let sql = "alter table \(tableName) add \(key) text"
        res = instance.exec(sql)
        return res
    }
    
    
    
    
}
// 对外公共接口
extension DBSQL{
    
    static func drop(_ tableName:String) -> Bool {
        
        var res = false
        //删除本地缓存表
        UserDefaults.standard.removeObject(forKey: tableName)
        let sql = "drop table \(tableName)"
        res = instance.exec(sql)
        return res
    }
    
    static func delete(_ tableName:String,_ condition:String) -> Bool {
        var res = false
        sql_queue.sync {
            res = instance.deleteJson(tableName, condition)
        }
        return res
    }
    
    static func insert(_ tableName:String,_ data:[Any]) -> Bool {
        if data.count == 0 {
            return true
        }
        var res = false
        sql_queue.sync {
            
            for item in data {
                if let json = item as? [String:Any] {
                    res = instance.insertJson(tableName, json)
                }
            }
        }
        
        return res
    }
    
    static func update(_ tableName:String,_ data:[String:Any],_ condition:String) -> Bool {
        var res = false
        sql_queue.sync {
            res = instance.updateJson(tableName,data,condition)
        }
        return res
    }
    
   
    static func select(_ tableName:String,_ condition:String) -> [Any]?{
        var res:[Any]?
        sql_queue.sync {
            res = instance.selectJson(tableName,condition)
        }
        return res
    }
    
    static func commit(){
        instance.execLogSQL()
    }
    
}

fileprivate extension DBSQL{
    
    func saveLogSQL(_ sql:String) {
        print(sql)
        if sql.count > 0 {
            if let array = UserDefaults.standard.array(forKey: sql_log_key) as? [String] {
                var list = array
                if list.count >= 10 {
                    beginTransaction()
                    for sql in list {
                        exec(sql)
                    }
                    commitTransaction()
                    list.removeAll()
                }
                list.append(sql)
                
                UserDefaults.standard.setValue(list, forKey: sql_log_key)
            }else {
                UserDefaults.standard.setValue([sql], forKey: sql_log_key)
            }
        }
        
        
    }
    func execLogSQL() {
        
        sql_queue.sync {
            if let array = UserDefaults.standard.array(forKey: sql_log_key) as? [String] {
                
                beginTransaction()
                for sql in array {
                    exec(sql)
                }
                commitTransaction()
                UserDefaults.standard.removeObject(forKey: sql_log_key)
            }
        }
    }
    
}


//MARK: - 方法
fileprivate extension DBSQL {
    /// 开启事务
    func beginTransaction() {
        sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
    }
    /// 提交事务
    func commitTransaction() {
        sqlite3_exec(db, "COMMIT TRANSACTION;", nil, nil, nil)
    }
   
    
    func deleteJson(_ tableName:String,_ condition:String) -> Bool {
        let sql = deleteSQL(tableName, condition)
        saveLogSQL(sql)
        return true
    }
    
    func insertJson(_ tableName:String,_ json:[String:Any]) -> Bool {
        
        let sql = insertSQL(tableName, json)
        saveLogSQL(sql)
        return true
    }
    
    func updateJson(_ tableName:String,_ json:[String:Any],_ condition:String) -> Bool {
        
        let sql = updateSQL(tableName, json, condition)
        saveLogSQL(sql)
        return true
    }
    
    
    func selectJson(_ tableName:String,_ condition:String) -> [Any]? {
        
        if condition.count > 0 {
            let sql = "select * from \(tableName)  where \(condition)"
            return query(sql)
        }
        let sql = "select * from \(tableName)"
        return query(sql)
        
    }
    
    
}
//MARK: - SQL接口
fileprivate extension DBSQL{
        
    func deleteSQL(_ tableName:String,_ condition:String) -> String {
        if condition.count > 0 {
            let sql = "delete from \(tableName) where \(condition)"
            return sql
        }
        let sql = "delete from \(tableName)"
        return sql
    }
    
    func insertSQL(_ tableName:String,_ json:[String:Any]) -> String {
        if json.isEmpty {
            return ""
        }
        var keys = ""
        var values = ""
        for (k,v) in json {
            if keys.count == 0{
                keys = "\(k)"
            }else {
                keys = keys + "," + "'\(k)'"
            }
            
            if values.count == 0{
                values = "'\(v)'"
            }else {
                values = values + "," + "'\(v)'"
            }
            
        }
        let sql = "insert into \(tableName) (\(keys)) values (\(values))"
        return sql
    }
    
    func updateSQL(_ tableName:String,_ json:[String:Any],_ condition:String) -> String {
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
            return sql
        }
        return ""
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
        var err: UnsafeMutablePointer<Int8>? = nil
        let csql = sql.cString(using: String.Encoding.utf8)
        if sqlite3_exec(db, csql, nil, nil, &err) == SQLITE_OK {
            print("执行成功")
            return true
        }
        print("执行失败error\(String(validatingUTF8:sqlite3_errmsg(db)))")
        return false
    }
    
    func query(_ sql:String) -> [Any]? {
        print("准备好 sql--\(sql)")
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
        
        if let st = statement {
            sqlite3_finalize(st)
        }

        
        return temArr
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

