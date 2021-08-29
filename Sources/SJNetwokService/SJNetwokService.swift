//
//  SJNetwokService.swift
//
//
//  Created by sabrina on 2021/5/3.
//

import Foundation
import Alamofire
import SJUtil

public class NetworkService : NSObject {
    
    public override init() {
        super.init()
    }
    
    private func getHttpMethod(method:HttpMethod) -> Alamofire.HTTPMethod {
        var m: Alamofire.HTTPMethod = .get
        switch method {
        case .post:
            m = .post
        case .put:
            m = .put
        case .patch:
            m = .patch
        case .delete:
            m = .delete
        default:
            m = .get
        }
        return m
    }
}

extension NetworkService : NetworkProtocol {
    public func request(_ url: URL, method: HttpMethod, parameters: [String : Any]?, timeoutInterval: TimeInterval, encoding: ParametersEncoding?, headers: [String : String]?, completion: @escaping (Results<Json>) -> Void) {
        let m = getHttpMethod(method: method)
        
        var e:ParameterEncoding = URLEncoding.default
        if let encoding = encoding {
            switch encoding {
            case .UrlEnconing:
                e = URLEncoding.queryString
            case .BodyEncoding:
                e = URLEncoding.httpBody
            default:
                e = URLEncoding.default
            }
        }
        
        var originalRequest: URLRequest?
        do {
            let httpHeaders:HTTPHeaders = HTTPHeaders(headers ?? [:])
            originalRequest = try URLRequest(url: url, method: m, headers: httpHeaders)
            var encodeURLRequest = try e.encode(originalRequest!, with: parameters)
            encodeURLRequest.timeoutInterval = timeoutInterval
            
            AF.request(encodeURLRequest)
                .validate(statusCode: 200..<400)
                .responseJSON { response in
                    switch response.result {
                    case let .success(value):
                        if let result = Json(json: value) {
                            completion(.success(result))
                        }
                    case let .failure(err):
                        completion(.error(err))
                    }
            }
        }catch{
            completion(.error(error))
        }
    }
    
    public func requestWithAuth(_ url: URL, method: HttpMethod, parameters: [String : Any]?, headers: [String : String]?, userName: String, userPassword: String, completion: @escaping (Results<Json>) -> Void) {
        let m: HTTPMethod = getHttpMethod(method: method)
        
        if let dict = parameters {
            AF.request(url, method: m, parameters: dict)
                .authenticate(username: userName, password: userPassword)
                .responseJSON { (response) in
                    if let value = response.data, let result = Json(json: value) {
                        completion(.success(result))
                    }else{
                        guard let err = response.error else { print(response); return }
                        completion(.error(err))
                    }
                }
        }
    }
    
    public func requestWithUploadFileNotInBody(_ url: URL, method: HttpMethod, parameters: [String : Any]?, mData: Data, mimeType: MimeType, fileName: String, timeoutInterval: TimeInterval, encoding: ParametersEncoding?, headers: [String : String]?, completion: @escaping (Results<Json>) -> Void) {
//        let m: HTTPMethod = getHttpMethod(method: method)
//
//        var e = URLEncoding.default
//        if let encoding = encoding {
//            switch encoding {
//            case .UrlEnconing:
//                e = URLEncoding.queryString
//            case .BodyEncoding:
//                e = URLEncoding.httpBody
//            default:
//                e = URLEncoding.default
//            }
//        }
        
        Log.error("Not implemented yet!")
    }
    
    public func requestWithUploadFileInBody(_ url: URL, method: HttpMethod, parameters: [String : Any]?, mData: Data, mimeType: MimeType, fileName: String, timeoutInterval: TimeInterval, encoding: ParametersEncoding?, headers: [String : String]?, completion: @escaping (Results<Json>) -> Void) {
        Log.error("Not implemented yet!")
    }
    
    public func requestWithUploadFilesInBody(_ url: URL, method: HttpMethod, parameters: [String : Any]?, files: [Data], fileExtension: String, mimeType: MimeType, timeoutInterval: TimeInterval, encoding: ParametersEncoding?, headers: [String : String]?, completion: @escaping (Results<Json>) -> Void) {
        Log.error("Not implemented yet!")
    }
    
    public func requestImage(_ url: URL, completed: @escaping ((Data?) -> Void), failure: @escaping ((Error) -> Void)) {
        let destination:DownloadRequest.Destination = { _,_ in
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileURL = documentURL?.appendingPathComponent("tmp.png")
            return (fileURL!, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(url, interceptor: nil, to: destination).response { (response) in
            guard let err = response.error else {
                if let imagePath = response.fileURL, let imgData = try? Data(contentsOf: imagePath) {
                    completed(imgData)
                }
                return
            }
            failure(err)
        }
    }
}
