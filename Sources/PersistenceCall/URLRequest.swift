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
