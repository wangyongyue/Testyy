//
//  JsonWrapper.swift
//  Test
//
//  Created by wyy on 2021/9/26.
//

import UIKit


protocol JsonProtocol {
    init(_ data:[String:Any]?)
    func toJson() -> [String:Any]?
}
func mergeMap(_ m:[String:Any]?...) -> [String:Any]? {
    var dic = [String:Any]()
    for item in m{
        if let it = item {
            for (k,v) in it {
                dic[k] = v
            }
        }
    }
    return dic
}



