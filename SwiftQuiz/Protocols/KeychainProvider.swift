import Foundation

protocol KeychainProvider {
    func store(key: String, service: String, data: Data) throws
    func update(key: String, service: String, data: Data) throws
    func retrieve(key: String, service: String) throws -> Data
    func delete(key: String, service: String) throws
    func storeOrUpdate(key: String, service: String, data: Data) throws
    func storeAPIKey(_ apiKey: String, for serviceName: String) throws
    func retrieveAPIKey(for serviceName: String) throws -> String
    func deleteAPIKey(for serviceName: String) throws
}
