//
//  NicooAssetResourceLoader.swift
//  NicooPlayer
//
//  Created by 小星星 on 2018/9/29.
//

import UIKit
import AVFoundation
import MobileCoreServices

/// 给播放器实现的代理：
public protocol NicooLoaderUrlConnectionDelegate: class {
    
    func didFinishLoadingWithTask(task: NicooVideoRequestTask)
    func didFailLoadingWithTask(task: NicooVideoRequestTask, errorCode: Int)
}



/// 播放器的数据请求代理对象
class NicooAssetResourceLoader: NSObject {
    
    /// 所有请求集合
    public var pendingRequests = [AVAssetResourceLoadingRequest]()   //  存播放器请求的数据的
    
    public weak var delegate: NicooLoaderUrlConnectionDelegate?
    
    public var task: NicooVideoRequestTask?
    
}

// MARK: - Open Api

extension NicooAssetResourceLoader {
    
    /**
     获取相应协议头的URL
     
     - parameter scheme: 协议头（默认为streaming）
     - parameter url:    待转换URL
     */
    public func getURL(forScheme scheme: String = "streaming", url: URL?) -> URL? {
        guard let url = url else {return nil}
        let component = NSURLComponents(url: url as URL, resolvingAgainstBaseURL: false)
        component?.scheme = scheme
        return component?.url
    }
    
    public func cancel() {
        //  1. 结束task下载任务
        task?.cancle()
        task = nil
        //  2. 停止数据请求
        for request in pendingRequests {
            request.finishLoading()
        }
    }
}

// MARK: - Privited Funcs

extension NicooAssetResourceLoader {
    
    private func configLoadingRequest(loadingRequest: AVAssetResourceLoadingRequest) {
        
        guard let interceptedURL = loadingRequest.request.url else {return}
        let range = NSMakeRange(Int(loadingRequest.dataRequest?.currentOffset ?? 0),Int.max)
        if let task = task {
            if task.downLoadingOffset > 0 { //  如果该请求正在加载...
                processPendingRequests()
            }
            //  处理往回拖 & 拖到的位置大于已缓存位置的情况
            let loadLastRequest = range.location < task.offSet //   往回拖
            let tmpResourceIsNotEnoughToLoad = task.offSet + task.downLoadingOffset + 1024 * 300 < range.location  //  拖到的位置过大，比已缓存的位置还大300
            if loadLastRequest || tmpResourceIsNotEnoughToLoad {
                self.task!.setUrl(url: interceptedURL as NSURL, offSet: range.location)
            }
        } else {
            task = NicooVideoRequestTask()
            task?.delegate = self
            task?.setUrl(url: interceptedURL as NSURL, offSet: 0)
        }

    }
    
    private func processPendingRequests() {
        var completedRequests = [AVAssetResourceLoadingRequest] ()   // 请求完成的集
        //  每次下载一块数据都是一次请求，把这些请求放到数组，遍历数组
        for loadingRequest in pendingRequests {
            if loadingRequest.contentInformationRequest != nil {
                fillInContentInformation(contentInfoRequest: loadingRequest.contentInformationRequest!)
            }
            if loadingRequest.dataRequest != nil {
                // 判断此次请求的数据是否处理完全
                let respondCompletely = respondWithDataForRequest(dataRequest: loadingRequest.dataRequest!)
                if respondCompletely {
                    // 如果完整，把此次请求放进 请求完成的数组
                    completedRequests.append(loadingRequest)
                    loadingRequest.finishLoading()
                }
            }
            //  剔除掉已经完成了的请求
            pendingRequests = pendingRequests.filter({ (request) -> Bool in
                return !completedRequests.contains(request)
            })
        }
    }
    
    private func fillInContentInformation(contentInfoRequest: AVAssetResourceLoadingContentInformationRequest) {
        guard let task = task else {return}
        let mimeType = task.mimeType
        let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType! as CFString, nil)?.takeRetainedValue()
        contentInfoRequest.isByteRangeAccessSupported = true
        contentInfoRequest.contentType = CFBridgingRetain(contentType) as? String
        contentInfoRequest.contentLength = Int64(task.videoLength)
    }
    
    private func respondWithDataForRequest(dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        guard let task = self.task else {
            return false
        }
        var starOffset = dataRequest.requestedOffset
        if dataRequest.currentOffset != 0 {
            starOffset = dataRequest.currentOffset
        }
        if task.offSet + task.downLoadingOffset < Int(starOffset) {
          
            return false
        }
        if Int(starOffset) < task.offSet {
            return false
        }
        
        //  取出来缓存文件
        var fileData: NSData? = nil
        fileData = NSData(contentsOfFile: VideoFilePath.tempPath)
        //  可以拿到的从startOffset之后的长度
        let unreadBytes = task.downLoadingOffset - (Int(starOffset) - task.offSet)
        //  应该能拿到的字节数
        let numberOfBytesToRespondWith = min(dataRequest.requestedLength, unreadBytes)
        //  应该从本地拿的数据范围
        let fetchRange = NSMakeRange(Int(starOffset) - task.offSet, numberOfBytesToRespondWith)
        //  拿到响应数据
        guard let responseData = fileData?.subdata(with: fetchRange) else {return false}
        //  响应请求
        dataRequest.respond(with: responseData)
        //  请求结束位置
        let endOffset = starOffset + Int64(dataRequest.requestedLength)
        //  是否获取到完整数据
        let didRespondFully = task.offSet + task.downLoadingOffset >= Int(endOffset)
        
        return didRespondFully
        
        
    }
}


// MARK: - AVAssetResourceLoaderDelegate

extension NicooAssetResourceLoader: AVAssetResourceLoaderDelegate {
    
    /**
     *  必须返回Yes，如果返回NO，则resourceLoader将会加载出现故障的数据
     *  这里会出现很多个loadingRequest请求， 需要为每一次请求作出处理
     *  @param resourceLoader 资源管理器
     *  @param loadingRequest 每一小块数据的请求
     *
     */
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        pendingRequests.append(loadingRequest)
        configLoadingRequest(loadingRequest: loadingRequest)
       return true
    }
    
    // 取消加载，移除请求
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        guard let index = pendingRequests.index(of:loadingRequest) else {return}
        pendingRequests.remove(at: index)
    }
    
}

// MARK: - NicooVideoRequestTaskDelegate

extension NicooAssetResourceLoader: NicooVideoRequestTaskDelegate {
    
    func didReceiveVideoDataWithTask(task: NicooVideoRequestTask) {
        processPendingRequests()
    }
    
    func didReceiveVideoLengthWithTask(task: NicooVideoRequestTask, videoLength: Int, mimeType: String) {
        
    }
    
    func didFinishLoadingWithTask(task: NicooVideoRequestTask) {
        
        delegate?.didFinishLoadingWithTask(task: task)
    }
    
    func didFailLoadingWithTask(task: NicooVideoRequestTask, errorCode: Int) {
        delegate?.didFailLoadingWithTask(task: task, errorCode: errorCode)
        
    }
}
