//
//  ViewController.swift
//  Test
//
//  Created by edz on 2021/7/27.
//

import UIKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        run()
    }
   
   
  
    private func run(){
        let j = DMJSON(["name":12,"age":"yyds"])
        
        DBLog(j.name.int)
        DBLog("json--"+j.age.string)
        
        DBLog("===============")

     
        let t = Test_user(["name":"12312313123"])
        DBLog(t.toJson())
        DBLog("===============")

        t.name = "wwww"
        usesmee.insert([t])
        let userM = usesmee.select(Test_user.self) {
            return $0
        }
       
        DBLog(userM?.first?.name)
        DBLog("===============")
        
//        for i in 1...10 {
//            server.insert([t])
//        }
//        server.insert([t])
//
//        server.delete(Test_user.self) {
//            return $0.$name == "wwww"
//        }
        server.commit()
        let userAll = server.select(Test_user.self) {
            return $0.limit(10)
        }
        
        DBLog(userAll?.count)
            


    }
        
    @DBServer("Test_user")
    var server:DBServer
    
    @Memory()
    var usesmee:Memory
        
    
    
}
class Test_user:JsonProtocol{
    
    @DBJSON("Test_user","name")
    var name:String?
    
    @DBJSON("Test_user","age")
    var age:String?
    
    init() {}
    required init (_ data:[String:Any]?) {
        $name.setJson(data)
        $age.setJson(data)

    }
    func toJson() -> [String:Any]?{
        
        return mergeMap($name.getJson(),
                        $age.getJson())
    }
    
}






























@dynamicMemberLookup
@dynamicCallable
class JsonObject{
    private var ob = [String:Any]()
    var value = [String:Any]()
    init(_ value:[String: Any] = [:]) {
        self.value = value
    }
    func send(_ label:UILabel, key:String){
        ob[key] = label
    }
    subscript<T>(dynamicMember member:String) ->T? where T:Any{
        get{
            value[member] as? T
        }
        set{
            value[member] = newValue
            if let la = ob[member] as? UILabel{
                la.text = newValue as? String
            }
        }
    }
    func dynamicallyCall(withKeywordArguments args:KeyValuePairs<String,Any>) -> Self{
        for item in args{
            value[item.0] = item.1
        }
        return self
    }
}

@dynamicMemberLookup
class Alabel:UILabel{
    var value = [String:Any]()
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    subscript<T>(dynamicMember member:String) ->T? where T:Any{
        get{
            value[member] as? T
        }
        set{
            value[member] = newValue
        }
    }
}
@dynamicMemberLookup
enum JSON {
  case intValue(Int)
  case stringValue(String)
  case arrayValue(Array<JSON>)
  case dictionaryValue(Dictionary<String, JSON>)
 
  var stringValue: String? {
     if case .stringValue(let str) = self {
        return str
     }
     return nil
  }
 
  subscript(index: Int) -> JSON? {
     if case .arrayValue(let arr) = self {
        return index < arr.count ? arr[index] : nil
     }
     return nil
  }
 
  subscript(key: String) -> JSON? {
     if case .dictionaryValue(let dict) = self {
        return dict[key]
     }
     return nil
  }
 
  subscript(dynamicMember member: String) -> JSON? {
     if case .dictionaryValue(let dict) = self {
        return dict[member]
     }
     return nil
  }
}
