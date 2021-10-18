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
        
        json_run()
    }
   
   
  
    private func json_run(){
        let j = WJSON(["name":12,"age":"yyds"])
        
        print("json--",j.name.int)
        print("json--"+j.age.string)
        
        print("===============")

     
        let t = Test_user(["name":"12312313123"])
        let t1 = Test_user(t.toJson())
        print("地址为: \(Unmanaged<AnyObject>.passUnretained(t as! AnyObject).toOpaque())")
        print("地址为: \(Unmanaged<AnyObject>.passUnretained(t1 as! AnyObject).toOpaque())")
        print("===============")

   
        cache = t
        print(cache?.name)
        print("===============")
              
//        usersInsert.run([t])
    

        t.name = "wwww"
        usesmee = [t,t1]
       
        print(usesmee?.first?.name)
        print("===============")
        
//        server.insert([t])

        
        let user = server.selectOne(Test_user.self) {
            return $0.$name == "wwww"
        }
        
        print(user?.name)
        
        let pa = ["name":"wwww","age":"w"]
        var array = ["name","=","wwww","and","age","=","wwww"]
        var stack = [String]()
        while array.count > 0 {
            let p = array[0]
            stack.append(p)
            array.removeFirst()
            if stack.count > 2 && stack[1] == "="{
                if let p =  pa[stack[0]] {
                    if  stack[1] == "="  && p == stack[2]{
                        
                        stack.removeAll()
                        stack.append("yes")
                    }else{
                        stack.removeAll()
                        stack.append("no")
                        
                    }
                }else{
                    print("no")
                    return
                }
            }
            if stack.count > 1 && stack[1] == "or" {
                if stack[0] == "yes" {
                    print("yes")
                    return
                }else {
                    stack.removeAll()
                }
            }
            if stack.count > 1 && stack[1] == "and" {
                if stack[0] == "no" {
                    print("no")
                    return
                }else {
                    stack.removeAll()
                }
            }
            if stack.count == 1 && array.count == 0{
                if stack[0] == "yes" {
                    print("yes")
                    return
                }else if stack[0] == "no"{
                    print("no")
                    return
                }
            }
        }

//        co.run()

//        GCDTest4()

    }
    
    let co = Coroutine()
    
    @DBServer("Test_user")
    var server:DBServer
    
    @Memory("users",Test_user.self)
    var usesmee:[Test_user]?
    
    
    @Memory("sdfsdf")
    var strinssss:[Int]?
    
    @Memory("ca",Test_user.self)
    var cache:Test_user?
    
    
    
    func GCDTest4() {
        let group = DispatchGroup.init()
        //剩余10个车位
        let semaphore = DispatchSemaphore.init(value: 10)
        for i in 1...100 {
            
            //来了一辆车，信号量减1
            let result = semaphore.wait(timeout: .distantFuture)
            if result == .success {
                DispatchQueue.global().async(group: group, execute: {
                    print("队列执行\(i)--\(Thread.current)")
                    //模拟执行任务时间
                    sleep(3)

                    //延迟3s后,走了一辆车，信号量+1
                    semaphore.signal()
                })
                
               
            }
        }
        group.wait()
            
    }

   

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
        
        return mergeMap($name.getJson(),$age.getJson())
    }
    
}




@dynamicMemberLookup
struct Lens<T> {
  let getter: () -> T
  let setter: (T) -> Void

  var value: T {
    get {
      return getter()
    }
    nonmutating set {
      setter(newValue)
    }
  }

  subscript<U>(dynamicMember keyPath: WritableKeyPath<T, U>) -> Lens<U> {
    return Lens<U>(
        getter: { self.value[keyPath: keyPath] },
        setter: { self.value[keyPath: keyPath] = $0 })
  }
}

protocol P1 {
    func run()
}
protocol P2 {
    func jump()
}
extension P1{
    func run(){
        print("p1")
    }
}
extension P2{
    func jump(){
        print("p2")
    }
}
class People:P1,P2 {
   
}

@discardableResult
public func GKTConfig<Object>(_ object: Object, _ config: (Object) throws -> Void) rethrows -> Object{
    try config(object)
    return object
}

@dynamicCallable
struct ToyCall {
    func dynamicallyCall<T>(withArguments:[T]){
        print("1")
        print(withArguments);

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
