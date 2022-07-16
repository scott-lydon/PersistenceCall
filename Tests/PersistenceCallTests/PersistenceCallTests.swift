import XCTest
@testable import PersistenceCall
import Foundation


final class PersistenceCallTests: XCTestCase {
    
    func test3PartsOfPersistenceDownloadTask() {
        let savedDis: String = "Save dissed"
        let data = Data(savedDis.utf8)
        
        let remindersDataURL = URL(fileURLWithPath: "Reminders", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
        try! data.write(to: remindersDataURL)
        
        URLRequest.downloadHashImgDataCache = .init()
        let localURL: URL = try! FileManager.default.with(hash: remindersDataURL.request!.deterministicHash + "downloadData")
        
        // 1. download task first run.
        XCTAssertNil(URLRequest.downloadHashImgDataCache.object(forKey: localURL.absoluteString as NSString))
        let semaphore = DispatchSemaphore(value: 0)
        var reachedClosure: Bool = false
        let downloadTask: URLSessionDownloadTask? = remindersDataURL.request?.callPersistDownloadData(
            fetchStrategy: .alwaysUseCacheIfAvailable) { fetchedData in
                XCTAssertEqual(data, fetchedData)
                reachedClosure = true
                semaphore.signal()
            }
        semaphore.wait()
        XCTAssertNotNil(downloadTask)
        XCTAssertTrue(reachedClosure)
        XCTAssertEqual(
            URLRequest.downloadHashImgDataCache.object(forKey: localURL.absoluteString as NSString)
            , NSData(data: data)
        )
        
        // 2. Download task for the second time.
        let semaphore1 = DispatchSemaphore(value: 0)
        var reachedClosure1: Bool = false
        let downloadTask1: URLSessionDownloadTask? = remindersDataURL.request?.callPersistDownloadData(
            fetchStrategy: .alwaysUseCacheIfAvailable) { fetchedData in
                XCTAssertEqual(data, fetchedData)
                reachedClosure1 = true
                semaphore1.signal()
            }
        semaphore1.wait()
        XCTAssertNil(downloadTask1)
        XCTAssertTrue(reachedClosure1)
        
        // 3. clear cache but still get the data
        
        URLRequest.downloadHashImgDataCache = .init()
        let semaphore2 = DispatchSemaphore(value: 0)
        var reachedClosure2: Bool = false
        let downloadTask2: URLSessionDownloadTask? = remindersDataURL.request?.callPersistDownloadData(
            fetchStrategy: .alwaysUseCacheIfAvailable) { fetchedData in
                XCTAssertEqual(data, fetchedData)
                reachedClosure2 = true
                semaphore2.signal()
            }
        semaphore2.wait()
        XCTAssertNil(downloadTask2)
        XCTAssertTrue(reachedClosure2)
    }
}
