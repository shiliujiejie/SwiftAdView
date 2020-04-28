//
//  NicooVideoRequestTask.swift
//  NicooPlayer
//
//  Created by 小星星 on 2018/9/29.
//

import UIKit


/// 视频缓存文件沙河地址
public struct VideoFilePath {
    static let videoDicPath: String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last! + "/streamVideo"  //  缓冲文件夹
    static let tempPath: String = videoDicPath + "/temp.mp4"    //  缓冲文件路径 - 非持久化文件路径 - 当前逻辑下，有且只有一个缓冲文件
    
}

/// 视频加载请求代理
public protocol NicooVideoRequestTaskDelegate: class {
    
    func didReceiveVideoLengthWithTask(task: NicooVideoRequestTask, videoLength: Int, mimeType: String)
    func didReceiveVideoDataWithTask(task: NicooVideoRequestTask)
    func didFinishLoadingWithTask(task: NicooVideoRequestTask)
    func didFailLoadingWithTask(task: NicooVideoRequestTask, errorCode: Int)
    
}

public extension NicooVideoRequestTaskDelegate {
    func didReceiveVideoLengthWithTask(task: NicooVideoRequestTask, videoLength: Int, mimeType: String){}
    func didReceiveVideoDataWithTask(task: NicooVideoRequestTask){}
    func didFinishLoadingWithTask(task: NicooVideoRequestTask){}
    func didFailLoadingWithTask(task: NicooVideoRequestTask, errorCode: Int){}
}

/// 用于向服务器拉去视频数据
open class NicooVideoRequestTask: NSObject {
    
    public var url: NSURL?
    public var offSet: Int = 0
    public var videoLength: Int = 0
    public var downLoadingOffset: Int = 0
    public var mimeType: String?
    public var isFinishLoad: Bool = false
    public weak var delegate: NicooVideoRequestTaskDelegate?
    
    private var connection: NSURLConnection?
    private var tasks: [NSURLConnection] = [NSURLConnection]()
    private var once: Bool = false
    private var fileHandle: FileHandle?
    
  
    internal override init() {
        super.init()
        initialTmpFile()
        
    }
    
    private func initialTmpFile() {
        do { try FileManager.default.createDirectory(atPath: VideoFilePath.videoDicPath, withIntermediateDirectories: true, attributes: nil) } catch { print("creat dic false -- error:\(error)") }
        if FileManager.default.fileExists(atPath: VideoFilePath.tempPath) {
            try! FileManager.default.removeItem(atPath: VideoFilePath.tempPath)
        }
        FileManager.default.createFile(atPath: VideoFilePath.tempPath, contents: nil, attributes: nil)
    }

}

// MARK: - OpenApi

extension NicooVideoRequestTask {
    
    open func setUrl(url: NSURL, offSet: Int) {
        func initialTmpFile() {
            try! FileManager.default.removeItem(atPath: VideoFilePath.tempPath)
            FileManager.default.createFile(atPath: VideoFilePath.tempPath, contents: nil, attributes: nil)
        }
        self.url = url
        self.offSet = offSet
         //如果建立第二次请求，先移除原来的文件，在创建新的
        if self.tasks.count >= 1 {
           initialTmpFile()
        }
        self.downLoadingOffset = 0
        //  把stream://xxx的头换成http://的头
        let actualURLComponents = NSURLComponents(url: url as URL, resolvingAgainstBaseURL: false)
        actualURLComponents?.scheme = "http"
        guard let URL = actualURLComponents?.url else {return}
        
        
        
        let mutableRequest = NSMutableURLRequest(url: URL, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 20.0)
        if offSet > 0 && self.videoLength > 0 {
            mutableRequest.addValue(String(format: "bytes=%ld-%ld", offSet, self.videoLength - 1), forHTTPHeaderField: "Range")
        }
        connection?.cancel()
        
        connection = NSURLConnection.init(request: mutableRequest as URLRequest, delegate: self, startImmediately: false)
        connection?.setDelegateQueue(OperationQueue.main)
        connection?.start()
        
        
        
    }
    
    open func cancle() {
        connection?.cancel()
    }
    
    open func continueLoading() {
        if self.url == nil { return }
        once = true
        guard let actualUrlComponents = NSURLComponents(url: self.url! as URL, resolvingAgainstBaseURL: false) else {
            return
        }
        actualUrlComponents.scheme = "http"
        guard let actualUrl = actualUrlComponents.url else {
            return
        }
        
        let mutableRequest = NSMutableURLRequest.init(url: actualUrl, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        if offSet > 0 && self.videoLength > 0 {
            mutableRequest.addValue(String(format: "bytes=%ld-%ld", downLoadingOffset, self.videoLength - 1), forHTTPHeaderField: "Range")
        }
        connection?.cancel()
        
        connection = NSURLConnection.init(request: mutableRequest as URLRequest, delegate: self, startImmediately: false)
        connection?.setDelegateQueue(OperationQueue.main)
        connection?.start()
    }
    
    /// 清除数据，取消视频请求
    open func clearData() {
        connection?.cancel()
        if FileManager.default.fileExists(atPath: VideoFilePath.tempPath) {
            try! FileManager.default.removeItem(atPath: VideoFilePath.tempPath)
        }
    }
    
}

// MARK: - NSURLConnectionData Delegate

extension NicooVideoRequestTask: NSURLConnectionDataDelegate {
    
    public func connection(_ connection: NSURLConnection, didReceive data: Data) {
        fileHandle?.seekToEndOfFile()
        fileHandle?.write(data as Data)
        downLoadingOffset += data.count
        delegate?.didReceiveVideoDataWithTask(task: self)
    }
    
    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
       
        isFinishLoad = false
        guard response is HTTPURLResponse else {return}
        //  解析头部数据
        let httpResponse = response as! HTTPURLResponse
        let dic = httpResponse.allHeaderFields
        let content = dic["Content-Range"] as? String
        let array = content?.components(separatedBy: "/")
        let length = array?.last
        //  拿到真实长度
        var videoLength = 0
        if Int(length ?? "0") == 0 {
            videoLength = Int(httpResponse.expectedContentLength)
        } else {
            videoLength = Int(length!)!
        }
        
        self.videoLength = Int(videoLength)
        //TODO: 此处需要修改为真实数据格式 - 从字典中取
        self.mimeType = "video/mp4"
        //  回调
        delegate?.didReceiveVideoLengthWithTask(task: self, videoLength: Int(videoLength), mimeType: mimeType!)
        //  连接加入到任务数组中
        tasks.append(connection)
        //  初始化文件传输句柄
        fileHandle = FileHandle.init(forWritingAtPath: VideoFilePath.tempPath)
        
    }
    
    public func connectionDidFinishLoading(_ connection: NSURLConnection) {
        
        // 这里可以做数据持久化，
        func tmpPersistence() {
//            let fileName = url?.lastPathComponent
//            let movePath = VideoFilePath.videoDicPath + "/\(fileName ?? "undefine.mp4")"
//            _ = try? FileManager.default.removeItem(atPath: movePath)
//
//            var isSuccessful = true
//            do { try FileManager.default.copyItem(atPath: VideoFilePath.tempPath, toPath: movePath) } catch {
//                isSuccessful = false
//                print("tmp文件持久化失败")
//            }
//            if isSuccessful {
//                print("持久化文件成功！路径 - \(movePath)")
//            }
        }
        
        if tasks.count < 2 {
            isFinishLoad = true
            // tmpPersistence()
        }
        delegate?.didFinishLoadingWithTask(task: self)
    }
    
    //网络中断：-1005
    //无网络连接：-1009
    //请求超时：-1001
    //服务器内部错误：-1004
    //找不到服务器：-1003
    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
       
        if error._code == -1001 && !once {   //  超时，1秒后重连一次
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("重连一次")
                self.continueLoading()
            }
        }
        if error._code == -1009 {
            print("无网络连接")
        }
        delegate?.didFailLoadingWithTask(task: self, errorCode: error._code)
        
        print("Error.code = \((error as NSError).code)")
    }
    
}
