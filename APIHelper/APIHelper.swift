//
//  APIHelper.swift
//  APIHelper
//
//  Created by Amish on 14/09/19.
//  Copyright © 2019 Amish. All rights reserved.
//

import UIKit

public class APIHelper {
    
    public static let sharedInstance = APIHelper()
    
    internal var apiBus:[URLRequest] = [URLRequest]()
    public typealias completionBlock = (Data?,URLResponse?,Error?) -> Void
    internal var block: completionBlock?
    internal var isDispatchingRequests: Bool = false
    
    
    public func authenticateUser(withUrl url: URL, httpMethod: HttpMethod, parameters: Data?, header: [String:String]?,completionHandler:@escaping completionBlock) {
        block = completionHandler
    }
    
    public func callWebservice(withUrl url: URL, httpMethod: HttpMethod, parameters: Data?, header: [String:String]?,completionHandler:@escaping completionBlock) {
        block = completionHandler
    }
    
}
//Adding an extension
extension APIHelper {
    
    public enum HttpMethod: String {
        case get
        case post
        
        func value() -> String {
            switch self {
            case .get:
                return "GET"
            case .post:
                return "POST"
            }
        }
    }
    
    private func callAPI(url: URL, httpMethod: HttpMethod, parameters: Data?, header: [String:String]?) {
        if Reachability.isConnectedToNetwork() {
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod.value()
            request.httpBody = parameters
            request.allHTTPHeaderFields = header
            createAndExecuteURlSession(withRequest: request)
        } else {
            block!(nil,nil,nil)
        }
    }
    //Creating URL Session
    private func createAndExecuteURlSession(withRequest request: URLRequest) {
        let session = URLSession.shared
        DispatchQueue.global(qos: .default).async {
            let dataTask: URLSessionDataTask = session.dataTask(with: request) { [weak self] (data, response, error) in
                guard let httpResponse = response as? HTTPURLResponse, let strongSelf = self else {
                    return
                }
                if httpResponse.statusCode == 401 {
                    if strongSelf.apiBus.contains(request) {
                        strongSelf.apiBus.append(request)
                    }
                    
                    if !strongSelf.isDispatchingRequests {
                        strongSelf.startDispatching()
                    }
                    
                } else {
                    strongSelf.block!(data,response,error)
                }
            }
            dataTask.resume()
        }
    }
    
    private func startDispatching() {
        if !apiBus.isEmpty {
            for request in apiBus {
                isDispatchingRequests = true
                let operation = Operation()
                let randomNum = Int.random(in: 0 ..< Int.max)
                operation.name = randomNum.description
                operation.qualityOfService = .background
                operation.completionBlock = { [weak self] in
                    self?.createAndExecuteURlSession(withRequest: request)
                }
                operation.start()
            }
            isDispatchingRequests = false
        }
    }

}
//Adding comment for testing
