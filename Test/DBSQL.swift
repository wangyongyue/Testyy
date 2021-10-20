//
//  DBSQL.swift
//  Test
//
//  Created by wyy on 2021/9/14.
//

import UIKit
import SQLite3

/*
 一个同步队列
 */
let sql_queue = DispatchQueue(label: "com.sql.queue")

/*
 存储增，删，改 sql的key
 */
let sql_log_key = "sql_log_key"


/*
 DBSQL 是一个sqlite3 的封装类
 实现了增，删，改，查的基本功能
 */
class DBSQL {
    private var db:OpaquePointer?
    private static let instance = DBSQL()
    let lock = NSLock()

    init() {
       let isOpen =  open()
        if isOpen {
            DBLog("数据库打开")
        }
    }
    
}
/*
 缓存数据库表和字段，防止重复调用sql
 */
extension DBSQL {
    
    static func setUpTableAndKeys(_ table:String,_ key:String){
        sql_queue.sync {
            
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
                    UserDefaults.standard.setValue(list, forKey: table)
                    
                }
                
            }else{
                
                if create(table) {
                    UserDefaults.standard.setValue(["t_id"], forKey: table)

                }
            }
            
        }
    }
    
}


fileprivate extension DBSQL {
    /*
     创建表
     */
   static func create(_ tableName:String) -> Bool {
        var res = false
        let sql = "create table if not exists \(tableName) (t_id integer)"
        res = instance.exec(sql)
        return res
    }
    /*
     增加表字段
     */
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

/*
 定义DBSQL接口
 */
extension DBSQL{
    
    /*
     删除表
     */
    static func drop(_ tableName:String) -> Bool {
        
        var res = false
        /*
         删除本地缓存表
         */
        UserDefaults.standard.removeObject(forKey: tableName)
        let sql = "drop table \(tableName)"
        res = instance.exec(sql)
        return res
    }
    
    /*
     删除数据
     参数：
     tableName 表名
     condition 条件语句
     */
    static func delete(_ tableName:String,_ condition:String) -> Bool {
        var res = false
        sql_queue.sync {
            res = instance.deleteJson(tableName, condition)
        }
        return res
    }
    
    /*
     新增数据
     参数：
     tableName 表名
     data 新增数据数组
     */
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
    
    
    /*
     更新数据
     参数：
     tableName  表名
     data       更新数据内容
     condition  条件语句
     */
    static func update(_ tableName:String,_ data:[String:Any],_ condition:String) -> Bool {
        var res = false
        sql_queue.sync {
            res = instance.updateJson(tableName,data,condition)
        }
        return res
    }
    
    /*
     查询数据
     参数：
     tableName  表名
     condition  条件语句
     */
    static func select(_ tableName:String,_ condition:String) -> [Any]?{
        var res:[Any]?
        sql_queue.sync {
            res = instance.selectJson(tableName,condition)
        }
        return res
    }
    
    /*
     事务提交
     新增，更新，删除 sql语句都会先缓存到UserDefault中，commit把缓存sql当作事务一起提交
     减少IO,也可以叫延迟执行
     */
    static func commit(){
        instance.execLogSQL()
    }
    
}

fileprivate extension DBSQL{
    /*
     新增，更新，删除 sql语句保存到本地，当sql语句到达10条时执行
     */
    func saveLogSQL(_ sql:String) {
        DBLog(sql)
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
    
    /*
     执行提交缓存sql
     */
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


fileprivate extension DBSQL {
    
    /*
     开启事务
     */
    func beginTransaction() {
        sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
    }

    /*
     提交事务
     */
    func commitTransaction() {
        sqlite3_exec(db, "COMMIT TRANSACTION;", nil, nil, nil)
    }
   
    /*
     保存删除sql
     参数：
     tableName 表名
     condition 条件
     */
    func deleteJson(_ tableName:String,_ condition:String) -> Bool {
        let sql = deleteSQL(tableName, condition)
        saveLogSQL(sql)
        return true
    }
    
    /*
     保存新增sql
     参数：
     tableName 表名
     json      新增的内容数组
     */
    func insertJson(_ tableName:String,_ json:[String:Any]) -> Bool {
        
        let sql = insertSQL(tableName, json)
        saveLogSQL(sql)
        return true
    }
    
    /*
     保存更新sql
     参数：
     tableName 表名
     condition 条件
     json      更新的内容
     */
    func updateJson(_ tableName:String,_ json:[String:Any],_ condition:String) -> Bool {
        
        let sql = updateSQL(tableName, json, condition)
        saveLogSQL(sql)
        return true
    }
    
    /*
     查询数据
     参数：
     tableName 表名
     condition 条件
     */
    func selectJson(_ tableName:String,_ condition:String) -> [Any]? {
        
        if condition.count > 0 {
            let sql = "select * from \(tableName) \(isLimit(condition))"
            return query(sql)
        }
        let sql = "select * from \(tableName)"
        return query(sql)
        
    }
    
    
}

fileprivate extension DBSQL{
    
    /*
     解析条件语句
     如果已limit开头，就不拼接where语句
     参数：
     co 条件语句
     */
    func isLimit(_ co:String) -> String{
        if co.hasPrefix("limit") {
            return co
        }
        return "where \(co)"
    }
        
    /*
     生成删除sql
     参数：
     tableName 表名
     condition 条件
     */
    func deleteSQL(_ tableName:String,_ condition:String) -> String {
        if condition.count > 0 {
            let sql = "delete from \(tableName) \(isLimit(condition))"
            return sql
        }
        let sql = "delete from \(tableName)"
        return sql
    }
    
    /*
     生成新增sql
     参数：
     tableName 表名
     json      新增的内容数组
     */
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
    
    
    /*
     生成更新sql
     参数：
     tableName 表名
     condition 条件
     json      更新的内容
     */
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
            let sql = "update \(tableName) set \(kv) \(isLimit(condition))"
            return sql
        }
        return ""
    }
    
}



fileprivate extension DBSQL {
    
    /*
     打开数据库
     */
    func open() -> Bool {
        let filePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        DBLog(filePath)
        let file = filePath + "/test.sqlite"
        let cfile = file.cString(using: String.Encoding.utf8)
        let state = sqlite3_open(cfile, &db)
        if state != SQLITE_OK {
            DBLog("打开数据库失败")
            return false
        }
        
        return true
    }
    
    /*
     执行sql
     返回bool
     参数：
     sql  sql语句
     */
    func exec(_ sql:String) -> Bool{
        var err: UnsafeMutablePointer<Int8>? = nil
        let csql = sql.cString(using: String.Encoding.utf8)
        if sqlite3_exec(db, csql, nil, nil, &err) == SQLITE_OK {
            DBLog("执行成功")
            return true
        }
        DBLog("执行失败error\(String(validatingUTF8:sqlite3_errmsg(db)))")
        return false
    }
    
    /*
     查询执行sql
     返回数据data
     参数：
     sql  sql语句
     */
    func query(_ sql:String) -> [Any]? {
        DBLog("准备好 sql--\(sql)")
        var statement:OpaquePointer? = nil
        let csql = sql.cString(using: String.Encoding.utf8)
        if sqlite3_prepare(db, csql, -1, &statement, nil) != SQLITE_OK {
            DBLog("未准备好")
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
                        DBLog("准备好 \(n):\(value)")
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

    /*
     查询执行sql
     返回int
     参数：
     sql  sql语句
     */
    func queryCount(_ sql:String) -> Int {
        var statement:OpaquePointer? = nil
        let csql = sql.cString(using: String.Encoding.utf8)
        if sqlite3_prepare(db, csql, -1, &statement, nil) != SQLITE_OK {
            DBLog("未准备好")
            return 0
        }
        var value:Int = 0
        while sqlite3_step(statement) == SQLITE_ROW {
            
            value += 1

        }
        return value
        
    }
    
}

