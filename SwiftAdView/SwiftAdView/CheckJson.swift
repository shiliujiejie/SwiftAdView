import Foundation
import Alamofire

public typealias Success = (_ data : Data)->()
public typealias Failure = (_ error : Error?)->()

class CLAPICheck: NSObject {
    //单例
    static var shared : CLAPICheck {
        struct Static {
            static let instance : CLAPICheck = CLAPICheck()
        }
        return Static.instance
    }
    
    /// GET请求
    func getRequest(
        _ urlString: String,
        params: Parameters? = nil,
        success: @escaping Success,
        failure: @escaping Failure)
    {
        request(urlString, params: params, method: .get, success, failure)
    }
    
    /// POST请求
    func postRequest(
        _ urlString: String,
        params: Parameters? = nil,
        success: @escaping Success,
        failure: @escaping Failure)
    {
        request(urlString, params: params, method: .post, success, failure)
    }
    
    //公共的私有方法
    func request(
        _ urlString: String,
        params: Parameters? = nil,
        method: HTTPMethod,
        _ success: @escaping Success,
        _ failure: @escaping Failure)
    {
        let manager = Alamofire.SessionManager.default
        manager.session.configuration.timeoutIntervalForRequest = 4
    

        manager.request(urlString, method: method, parameters:params).responseData { response in
            if let alamoError = response.result.error {
                failure(alamoError)
                return
            } else {
                let statusCode = (response.response?.statusCode)! //example : 200
               
                if statusCode == 200 {
                    success(response.data! as Data)
                } else {
                    failure(response.result.error)
                }
            }
        }
    }
}



