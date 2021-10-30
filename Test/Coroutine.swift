//
//  Coroutine.swift
//  Test
//
//  Created by wyy on 2021/10/9.
//

import UIKit
typealias cb = ()->Void


class Coroutine {
    
  
    let queue1 = OperationQueue()
    
   
    @DBServer("Test_user")
    var server:DBServer
   
    
    func  path(re:AnyKeyPath){
        
    }
    
    func run(){
        queue1.maxConcurrentOperationCount = 10
      
       
        for i in 1...1000000
        {


            queue1.addOperation  {

              Thread.sleep(forTimeInterval: 1.0)
                let user = self.server.selectOne(Test_user.self) {
                    return $0.all()
                }
                print("线程\(Thread.current)---\(i)---\(user?.name)")

            }

        }
                    
    }
   
   
   

}

