//
//  Coroutine.swift
//  Test
//
//  Created by wyy on 2021/10/9.
//

import UIKit
typealias cb = ()->Void


class Coroutine {
    
    var task1 = [cb]()
    var task2 = [cb]()
    var task3 = [cb]()
    
    let queue1 = OperationQueue()
    let queue2 = OperationQueue()
    let queue3 = OperationQueue()
      
    
   
    @DBServer("Test_user")
    var server:DBServer
   
    
    func  path(re:AnyKeyPath){
        
    }
    
    func run(){
        queue1.maxConcurrentOperationCount = 1
        queue2.maxConcurrentOperationCount = 1
        queue3.maxConcurrentOperationCount = 1
        
        
       
        for i in 1...1000000
        {


            addTask {

//              Thread.sleep(forTimeInterval: 1.0)
//                let user:Test_user? = self.server.select {
//                    let u = Test_user()
//                    var co =  u.$name == "wwww"
//                    return co.condition
//                }
//
//                print("线程\(Thread.current)---\(i)---\(user?.name)")
//                print("线程\(Thread.current)---\(i)")

            }

        }
                    
    }
   
   
    func addTask(_ t:@escaping cb){
        

        var queue = queue1
        if queue2.operationCount <= queue.operationCount {
            queue = queue2
        }
        if queue3.operationCount <= queue.operationCount {
            queue = queue3
        }
        queue.addOperation(t)
        
    }
   
    

}

