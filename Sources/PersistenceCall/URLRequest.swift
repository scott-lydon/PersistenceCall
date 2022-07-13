//
//  URLRequest.swift
//  CallablePersist
//
//  Created by Scott Lydon on 6/14/22.
//

import Foundation
import Callable
import CommonExtensions

public extension URLRequest {


    /// Uses a semaphore and a wait time to return Data inline from a web call.
    /// - Parameters:
    ///   - fetchStrategy: alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - usleepTime: IMPORTANT: usleep() takes millionths of a second, so usleep(1000000) will sleep for 1 sec
    /// - Returns: return the Data that was exposed.
    func inlinePersistData(
        fetchStrategy: FetchStrategy,
        usleepTime: useconds_t = 200_000
    ) -> Data? {
        var returnData: Data?
        let semaphore = DispatchSemaphore(value: 0)
        callPersistData(fetchStrategy: fetchStrategy) { data in
            returnData = data
            semaphore.signal()
        }
        usleep(usleepTime)
        semaphore.wait()
        return returnData
    }


    /// Calls the api, and exposes Data
    /// - Parameters:
    ///   - fetchStrategy: alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - dataAction: exposes the Data from the web call.
    func callPersistData(
        fetchStrategy: FetchStrategy,
        _ dataAction: DataAction? = nil
    ){
        let url = try! FileManager.default.with(hash: deterministicHash + "data")
        if let availableData: Data = try? FileHandle(forReadingFrom: url).availableData,
           let payload: Payload<Data> = availableData.codable(),
           fetchStrategy.tryCache(original: payload.date, current: Date()) {
            dataAction?(payload.value)
        } else {
            self.getData { data in
                let payload: Payload<Data> = Payload(date: Date(), value: data, hash: deterministicHash + "data")
                let payloadData: Data = try! JSONEncoder().encode(payload)
                try! payloadData.write(to: url)
                dataAction?(data)
            }
        }
    }
    
    /*
     
     /// attempts to get data from a Callable resource
     /// - Parameter dataAction: access the data here.  Passes nil if could not get the data.
     public func getDownloadData(_ dataAction: DataAction? = nil) {
         sessionDownloadTask(provideData: dataAction).resume()
     }
     
     private func sessionDownloadTask(provideData: DataAction?) -> URLSessionDownloadTask {
         URLSession.shared.downloadTask(with: self) { url, response, error in
             guard let data = url?.data else {
                 errorPrint()
                 provideData?("error: \(error?.localizedDescription ?? "nil")".data(using: .utf8)!)
                 return
             }
             provideData?(data)
         }
     }
     */
    
    /// key: hash
    /// value: url from download method
    static var downloadCache: NSCache<NSString, NSString> = .init()
    
    /// Calls the api, and exposes Data
    /// - Parameters:
    ///   - fetchStrategy: alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - dataAction: exposes the Data from the web call.
    func callPersistDownloadData(
        fetchStrategy: FetchStrategy,
        _ dataAction: DataAction? = nil
    ) {
        
        // check if we saved a url for this request hash, and check if there is data at that url.
        if let urlNSString: NSString = Self.downloadCache.object(forKey: (deterministicHash + "data") as NSString),
           let url: URL = URL(string: urlNSString as String),
           let availableData = try? Data(contentsOf: url),
           let payload: Payload<Data> = availableData.codable(),
           fetchStrategy.tryCache(original: payload.date, current: Date()) {
            
            // We have the data locally already.
            dataAction?(payload.value)
        } else {
            
            // Failed to get the data must download it.
            URLSession.shared.downloadTask(with: self.url!) { url, response, error in
                guard let url = url,
                        let data = try! Data(contentsOf: url) else { return }
                let payload: Payload<Data> = Payload(date: Date(), value: data, hash: deterministicHash + "data")
                let payloadData: Data = try! JSONEncoder().encode(payload)
                try! payloadData.write(to: url)
                Self.downloadCache.setObject(
                    (url.absoluteString ?? "") as NSString,
                    forKey: (deterministicHash + "data") as NSString
                )
                dataAction?(data)
            }.resume()
        }
    }

    /// Uses a semaphore and a wait time to return Data inline from a web call.
    /// - Parameters:
    ///   - fetchStrategy: alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - usleepTime: IMPORTANT: usleep() takes millionths of a second, so usleep(1000000) will sleep for 1 sec
    /// - Returns: return the Data that was exposed.
    func inlinePersistJSON(
        fetchStrategy: FetchStrategy,
        usleepTime: useconds_t = 200_000
    ) -> [String: Any]? {
        var jsonDictionary: [String: Any]?
        let semaphore = DispatchSemaphore(value: 0)
        callPersistJSON(fetchStrategy: fetchStrategy) { data in
            jsonDictionary = data
            semaphore.signal()
        }
        usleep(usleepTime)
        semaphore.wait()
        return jsonDictionary
    }


    /// Calls the api and exposes a json dictionary.
    /// - Parameters:
    ///   - fetchStrategy:  alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - jsonAction: exposes the json dictionary from the web call.
    func callPersistJSON(
        fetchStrategy: FetchStrategy,
        _ jsonAction: DictionaryAction? = nil
    ) {
        let url = try! FileManager.default.with(hash: deterministicHash + "[String: Any]")
        if let availableData: Data = try? FileHandle(forReadingFrom: url).availableData,
           let payload: Payload<Data> = availableData.codable(),
           fetchStrategy.tryCache(original: payload.date, current: Date()) {
            jsonAction?((try? payload.value.jsonDictionary()) ?? [:])
        } else {
            self.getData { data in
                let payload: Payload<Data> = Payload(date: Date(), value: data, hash: deterministicHash + "[String: Any]")
                let payloadData: Data = try! JSONEncoder().encode(payload)
                try? payloadData.write(to: url)
                jsonAction?((try? payload.value.jsonDictionary()) ?? [:])
            }
        }
    }


    func inlinePersistCodable<T: Codable>(
        fetchStrategy: FetchStrategy,
        usleepTime: useconds_t = 200_000
    ) -> T? {
        var codable: T?
        let semaphore = DispatchSemaphore(value: 0)
        callPersistCodable(fetchStrategy: fetchStrategy) { t in
            codable = t
            semaphore.signal()
        }
        usleep(usleepTime)
        semaphore.wait()
        return codable
    }

    /// Calls the api and exposes a codable item of your choice.
    /// - Parameters:
    ///   - fetchStrategy:  alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - jsonAction: exposes the codable item from the web call.
    func callPersistCodable<T: Codable>(
        fetchStrategy: FetchStrategy,
        _ action: @escaping (T?)->Void
    ) {
        let url = try! FileManager.default.with(hash: deterministicHash + String(describing: T.self))
        if let availableData: Data = try? FileHandle(forReadingFrom: url).availableData,
           let payload: Payload<Data> = availableData.codable(),
           fetchStrategy.tryCache(original: payload.date, current: Date()) {
            if let t: T = payload.value.codable() {
                action(t)
            } else {
                action(nil)
            }
        } else {
            self.getData { data in
                let payload: Payload<Data> = Payload(date: Date(), value: data, hash: deterministicHash + String(describing: T.self))
                let payloadData: Data = try! JSONEncoder().encode(payload)
                try? payloadData.write(to: url)
                if let t: T = payload.value.codable() {
                    action(t)
                } else {
                    action(nil)
                }
            }
        }
    }

    func inlinePersistPayloadData(
        fetchStrategy: FetchStrategy,
        usleepTime: useconds_t = 200_000
    ) -> Payload<Data>? {
        var codable: Payload<Data>?
        let semaphore = DispatchSemaphore(value: 0)
        callPersistData(fetchStrategy: fetchStrategy) { (payload: Payload<Data>?) in
            codable = payload
            semaphore.signal()
        }
        usleep(usleepTime)
        semaphore.wait()
        return codable
    }


    /// Calls the api, and exposes Data nested in a Payload.  The payload provides the date that the payload was retrieved.  It also includes the hash, which is used to identify this instance.  The hash is mainly used for internal purposes.
    /// - Parameters:
    ///   - fetchStrategy: alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - dataAction: exposes the Data from the web call along with the date that it was retrieved in a Payload.
    func callPersistData(
        fetchStrategy: FetchStrategy,
        _ dataAction: ((Payload<Data>) -> Void)? = nil
    ){
        let url = try! FileManager.default.with(hash: deterministicHash + "Payload<Data>")
        if let availableData: Data = try? FileHandle(forReadingFrom: url).availableData,
           let payload: Payload<Data> = availableData.codable(),
           fetchStrategy.tryCache(original: payload.date, current: Date()) {
            dataAction?(payload)
        } else {
            self.getData { data in
                let payload: Payload<Data> = Payload(date: Date(), value: data, hash: deterministicHash + "Payload<Data>")
                let payloadData: Data = try! JSONEncoder().encode(payload)
                try! payloadData.write(to: url)
                dataAction?(payload)
            }
        }
    }

    func inlinePersistPayloadCodable<T: Codable>(
        fetchStrategy: FetchStrategy,
        usleepTime: useconds_t = 200_000
    ) -> Payload<T>? {
        var codable: Payload<T>?
        let semaphore = DispatchSemaphore(value: 0)
        callPersistCodable(fetchStrategy: fetchStrategy) { (payload: Payload<T>?) in
            codable = payload
            semaphore.signal()
        }
        usleep(usleepTime)
        semaphore.wait()
        return codable
    }

    /// Calls the api, and exposes a codable item nested in a Payload.  The payload provides the date that the payload was retrieved.  It also includes the hash, which is used to identify this instance.  The hash is mainly used for internal purposes.
    /// - Parameters:
    ///   - fetchStrategy: alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - action: exposes the codable item from the web call along with the date that it was retrieved in a Payload.
    func callPersistCodable<T: Codable>(
        fetchStrategy: FetchStrategy,
        _ action: @escaping (Payload<T>?)->Void
    ) {
        let url = try! FileManager.default.with(hash: deterministicHash + "Payload<\(String(describing: T.self))>")
        if let availableData: Data = try? FileHandle(forReadingFrom: url).availableData,
           let payload: Payload<T> = availableData.codable(),
           fetchStrategy.tryCache(original: payload.date, current: Date()) {
            action(payload)
        } else {
            self.callCodable { (t: T?) in
                if let t = t {
                    let payload: Payload<T> = Payload(date: Date(), value: t, hash: deterministicHash + "Payload<\(String(describing: T.self))>")
                    let payloadData: Data = try! JSONEncoder().encode(payload)
                    try? payloadData.write(to: url)
                    action(payload)
                } else {
                    action(nil)
                }
            }
        }
    }

    func inlinePersistPayloadCodable2<First: Codable, Second: Codable>(
        fetchStrategy: FetchStrategy,
        usleepTime: useconds_t = 200_000
    ) -> (Payload<First>?, Payload<Second>?)? {
        var payloads: (Payload<First>?, Payload<Second>?)?
        let semaphore = DispatchSemaphore(value: 0)
        callPersistCodable(fetchStrategy: fetchStrategy) {
            (payload1: Payload<First>?, payload2: Payload<Second>?) in
            payloads = (payload1, payload2)
            semaphore.signal()
        }
        usleep(usleepTime)
        semaphore.wait()
        return payloads
    }


    /// In cases where an endpoint might return 2 different codable items, this method will first check if the first was returned, and if it fails, returns the second.
    /// - Parameters:
    ///   - fetchStrategy: alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - action: exposes the first, if the first cannot be provided, the second will be attempted.
    func callPersistCodable<First: Codable, Second: Codable>(
        fetchStrategy: FetchStrategy,
        _ action: @escaping (Payload<First>?, Payload<Second>?)->Void
    ) {
        let url: URL? = try? FileManager.default.with(hash: deterministicHash + "(Payload<\(String(describing: First.self))>?, Payload<\(String(describing: Second.self))>?)")
        let availableData: Data? = url?.fileHandleData
        if let first: Payload<First> = availableData?.codable(),
           fetchStrategy.tryCache(original: first.date, current: Date()) {
            action(first, nil)
        } else if let second: Payload<Second> = availableData?.codable(),
            fetchStrategy.tryCache(original: second.date, current: Date()) {
            action(nil, second)
        } else {
            self.getData { data in
                guard let url = url else { return }
                if let first: First = data.codable() {
                    let payload: Payload<First> = Payload(date: Date(), value: first, hash: deterministicHash + "(Payload<\(String(describing: First.self))>?, Payload<\(String(describing: Second.self))>?)")
                    let payloadData: Data? = try? JSONEncoder().encode(payload)
                    try? payloadData?.write(to: url)
                    action(payload, nil)
                } else if let second: Second = data.codable() {
                    let payload: Payload<Second> = Payload(date: Date(), value: second, hash: deterministicHash + "(Payload<\(String(describing: First.self))>?, Payload<\(String(describing: Second.self))>?)")
                    let payloadData: Data? = try? JSONEncoder().encode(payload)
                    try? payloadData?.write(to: url)
                    action(nil, payload)
                }
            }
        }
    }

    func inlinePersistCodable<First: Codable, Second: Codable>(
        fetchStrategy: FetchStrategy,
        usleepTime: useconds_t = 200_000
    ) -> (First?, Second?)? {
        var payloads: (First?, Second?)?
        let semaphore = DispatchSemaphore(value: 0)
        callPersistCodable(fetchStrategy: fetchStrategy) {
            (payload1: First?, payload2: Second?) in
            payloads = (payload1, payload2)
            semaphore.signal()
        }
        usleep(usleepTime)
        semaphore.wait()
        return payloads
    }

    /// In cases where an endpoint might return 2 different codable items, this method will first check if the first was returned, and if it fails, returns the second.
    /// - Parameters:
    ///   - fetchStrategy: alwaysUseCacheIfAvailable, newCall, refreshAfter time interval.
    ///   - action: exposes the first, if the first cannot be provided, the second will be attempted.
    func callPersistCodable<First: Codable, Second: Codable>(
        fetchStrategy: FetchStrategy,
        _ action: @escaping (First?, Second?)->Void
    ) {
        let url: URL? = try? FileManager.default.with(hash: deterministicHash + "\(String(describing: First.self))?, \(String(describing: Second.self))?")
        let availableData: Data? = url?.fileHandleData
        if let first: Payload<First> = availableData?.codable(),
           fetchStrategy.tryCache(original: first.date, current: Date()) {
            action(first.value, nil)
        } else if let second: Payload<Second> = availableData?.codable(),
            fetchStrategy.tryCache(original: second.date, current: Date()) {
            action(nil, second.value)
        } else {
            self.getData { data in
                guard let url = url else { return }
                if let first: First = data.codable() {
                    let payload: Payload<First> = Payload(date: Date(), value: first, hash: deterministicHash + "\(String(describing: First.self))?, \(String(describing: Second.self))?")
                    let payloadData: Data? = try? JSONEncoder().encode(payload)
                    try? payloadData?.write(to: url)
                    action(payload.value, nil)
                } else if let second: Second = data.codable() {
                    let payload: Payload<Second> = Payload(date: Date(), value: second, hash: deterministicHash + "\(String(describing: First.self))?, \(String(describing: Second.self))?")
                    let payloadData: Data? = try? JSONEncoder().encode(payload)
                    try? payloadData?.write(to: url)
                    action(nil, payload.value)
                }
            }
        }
    }
}
