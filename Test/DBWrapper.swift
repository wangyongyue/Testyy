//
//  DBWrapper.swift
//  Test
//
//  Created by wyy on 2021/9/26.
//

import UIKit


/*
 运算符重载
 condition 进行字符串拼接
 */
public extension DBJSON {
    
    static func == (r:DBJSON,x:String) -> DBJSON<String>{
        let nr = DBJSON<String>(r.table,r.key)
        nr.condition = "\(nr.key) = '\(x)'"
        return nr
    }
    static func == (r:DBJSON,x:Double) -> DBJSON<String>{
        let nr = DBJSON<String>(r.table,r.key)
        nr.condition = "\(nr.key) = '\(x)'"
        return nr
    }
    static func || (r:DBJSON,x:DBJSON) -> DBJSON{
        
        r.condition = "\(r.condition) or \(x.condition)"
        return r
    }
    static func && (r:DBJSON,x:DBJSON) -> DBJSON{
        
        r.condition = "\(r.condition) and \(x.condition)"
        return r
    }
    
    static func > (r:DBJSON,x:Double) -> DBJSON<String>{
        let nr = DBJSON<String>(r.table,r.key)
        nr.condition = "\(nr.key) > '\(x)'"
        return nr
    }
    static func < (r:DBJSON,x:Double) -> DBJSON<String>{
        let nr = DBJSON<String>(r.table,r.key)
        nr.condition = "\(nr.key) < '\(x)'"
        return nr
    }
    static func >= (r:DBJSON,x:Double) -> DBJSON<String>{
        let nr = DBJSON<String>(r.table,r.key)
        nr.condition = "\(nr.key) >= '\(x)'"
        return nr
        
    }
    static func <= (r:DBJSON,x:Double) -> DBJSON<String>{
        let nr = DBJSON<String>(r.table,r.key)
        nr.condition = "\(nr.key) <= '\(x)'"
        return nr
    }
    func limit(_ x:Int) -> DBJSON {
        self.condition = self.condition + " limit \(x)"
        return self
    }
    
}
/*
 扩展协议JsonProtocol
 limit 可以单独使用
 */
public extension JsonProtocol {
    func limit(_ x:Int) -> DBJSON<String> {
        let dj = DBJSON<String>("db","test")
        dj.condition = "limit \(x)"
        return dj
    }
    func all() -> DBJSON<String> {
        let dj = DBJSON<String>("db","test")
        dj.condition = ""
        return dj
    }
}


/*
 @propertyWrapper 属性包装器，可以重写包装属性的setter,getter方法
 属性：
 key       定义数据库字段 | 转json字段值
 table     数据库表名
 condition 条件语句拼接
 */
@propertyWrapper
public class DBJSON<T> {
    private var key:String
    private var table:String
    public var condition:String = ""

    public init(_ table:String,_ key: String){
        self.key = key
        self.table = table
        
        /*
         新建表，和新增数据表字段
         */
        DBSQL.setUpTableAndKeys(table,key)

    }
    /*
     值
     */
   private var defaultValue:T?
    
    /*
     setter ,getter 执行快
     必须实现
     */
    public  var wrappedValue: T?{
        
        get {return defaultValue}
        set {defaultValue = newValue}
    }
    
    /*
     映射
     可以通过 $ 美元符号访问
     */
    public var projectedValue:DBJSON{
        get{return self}
        set{}
    }
    
    /*
     返回当前key,和defaultValue
     */
    public func getJson() -> [String:Any]?{
        if let value = defaultValue {
            return [key:value]
        }
        return nil
    }
    
    /*
     通过json赋值
     */
    public func setJson(_ json:[String:Any]?){
        if let value = json?[key] as? T {
            defaultValue = value
        }else {
            if let value = json?[key]{
                if T.self is Double.Type {
                    defaultValue = Double("\(value)") as? T
                }else
                if T.self is Float.Type {
                    defaultValue = Float("\(value)") as? T
                }else
                if T.self is Int.Type {
                    defaultValue = Int("\(value)") as? T
                }else
                if T.self is String.Type {
                    defaultValue = "\(value)" as? T
                }
               
            }
        }
    }
}



/*
 自定义属性包装器类
 */
@propertyWrapper
public class DBServer{
    /*
     表名
     必填
     */
    private var table:String
    
    public init(_ table:String){
        self.table = table

        /*
         初始化时更新数据库sql
         */
        DBSQL.commit()
    }
   
    /*
     返回当前类实例，方便使用
     */
    public var wrappedValue:DBServer{
        get {return self}
        set {}
    }
    
}

/*
 扩展 DBServer
 提供增删改查接口
 */
public extension DBServer {
    
    /*
     查询单个数据
     参数：
     type      数据类型
     condition 条件语句
     */
    func selectOne<T>(_ type:T.Type,_ condition:(T)->DBJSON<String>) -> T?{
        if let an = analysisType(type,condition) {
        
            if let item = toModel(an.0, DBSQL.select(table, an.1)){
                return item.first as? T
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
    func select<T>(_ type:T.Type,_ condition:(T)->DBJSON<String>) -> [T]?{
        if let an = analysisType(type,condition) {
            
            if let items = toModel(an.0,DBSQL.select(table, an.1)) {
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
            
            if let items = toModel(t, DBSQL.select(table, "")) {
                return items as? [T]
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
    func delete<T>(_ type:T.Type,_ condition:(T)->DBJSON<String>) -> Bool{
        if let an = analysisType(type,condition) {
            return DBSQL.delete(table, an.1)
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
        let array = toJson(data)
        return DBSQL.insert(table, array)
    }
    
    /*
     更新数据
     参数：
     type      数据类型
     condition 条件语句
     data      更新数据内容
     */
    @discardableResult
    func update<T>(_ type:T.Type,_ condition:(T)->DBJSON<String>,_ data:JsonProtocol) -> Bool{
        
        if let an = analysisType(type,condition) {
            if let json = data.toJson() {
                return DBSQL.update(table, json, an.1)
            }
        }
        return false
    }
    
    /*
     提交执行缓存sql
     */
    func commit() {
        DBSQL.commit()
    }
    
    
}
/*
 解析泛型，和条件语句
 参数：
 t      数据类型
 condition 条件闭包，返回类型判断解析
 */
func analysisType<T>(_ t:T.Type,_ condition:(T)->DBJSON<String>) -> (JsonProtocol.Type,String)? {
    if let t1 = t as? JsonProtocol.Type {
        let ob = t1.init([:])
        let co  = condition(ob as! T)
        return (t1,co.condition)
    }
    return nil
}

/*
 model数据转json
 参数：
 data  数据内容
 */
func toJson(_ data:[JsonProtocol]) -> [Any] {
    var array = [Any]()
    for item in data {
        if let js = item.toJson() {
            array.append(js)
        }
    }
    return array
}

/*
 json数据转model
 参数：
 type  数据类型
 data  数据内容
 */
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



/*
 表达式解析,提取limit
 参数：
 condition  条件语句
 */
func expressionLimit(_ condition:String) -> Int?{
    
    let strs = condition.components(separatedBy: " ")
    for str in strs {
        if str == "limit" {
            if let limit = Int(strs.last!){
                return limit
            }
        }
    }
    return nil
}
/*
 表达式解析 三元式
 参数：
 condition  条件语句
 json       匹配数据
 */
func expression(_ json:[String:Any],_ condition:String) -> Bool{
    if condition.count == 0 {
        return true
    }
    let pa = json
    
    /*
     通过空格分词
     */
    let strs = condition.components(separatedBy: " ")
    
    /*
     筛选生成新的分词数组
     */
    var array = [String]()
    for str in strs {
        
        /*
         limit 之后不再插入array
         */
        if str == "limit" {
            break
        }
        array.append(str.replacingOccurrences(of: " ", with: ""))
    }
    
    /*
     执行栈空间
     */
    var stack = [String]()
    
    /*
     循环分析分词数组
     */
    while array.count > 0 {
        
        /*
         从分词数组拿出收割数据放入执行栈
         并从array中删除
         */
        let firt = array[0]
        stack.append(firt)
        array.removeFirst()
        
        /*
         如果执行栈中有三个数据，判断是不是三元式
         得出结果 yes/no 清除栈空间，把结果推入栈底
         */
        if stack.count > 2 {
            if let p =  pa[stack[0]] {
                let p1 = "\(p)"
                let p2 = stack[2].replacingOccurrences(of: "\'", with: "")
                
                /*
                 判断运算符进行判断
                 */
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
                DBLog("no")
            }
        }
        
        /*
         判断或运算
         */
        if stack.count > 1 && stack[1] == "or" {
            if stack[0] == "yes" {
                DBLog("yes")
                return true
            }else {
                stack.removeAll()
            }
            
        }
        
        /*
         判断与运算
         */
        if stack.count > 1 && stack[1] == "and" {
            if stack[0] == "no" {
                DBLog("no")
                return false
            }else {
                stack.removeAll()
            }
        }
        
        /*
         如果分词数据没有数据，拿到执行栈栈底结果，返回
         */
        if stack.count == 1 && array.count == 0{
            if stack[0] == "yes" {
                DBLog("yes")
                return true
            }else if stack[0] == "no"{
                DBLog("no")
                return false
            }
        }
        
    }
    
    
    return false
}

/*
 打印函数
 */
func DBLog( _ item: Any, file : String = #file, lineNum : Int = #line) {
    #if DEBUG
         let fileName = (file as NSString).lastPathComponent
         print("fileName:\(fileName) lineNum:\(lineNum) \(item)")
    #endif
}

