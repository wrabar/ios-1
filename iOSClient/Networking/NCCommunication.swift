//
//  NCCommunication.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 03/10/2019.
//  Copyright © 2019 TWS. All rights reserved.
//

import Foundation
import Alamofire

class NCCommunication: NSObject {
    
    
    func readFolder(path: String, user: String, password: String) {
        
        var url: URLConvertible
        var parameters = Parameters()
        var headers: HTTPHeaders = [.authorization(username: user, password: password)]
        
        // URL
        do {
            try url = path.asURL()
        } catch _ {
            return
        }
        
        // Parameters
        parameters["x"] = "s"
        
        // Headers
        headers["x"] = "X"
        
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).responseData { (data) in
            //
        }
    }
}
