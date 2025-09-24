import CoreData

@MainActor
protocol APIKeyProvider {
    func createAPIKey(name: String, key: String) throws -> APIKey
    func updateAPIKey(_ apiKey: APIKey, newKey: String) throws
    func getAPIKey(for apiKey: APIKey) throws -> String
    func deleteAPIKey(_ apiKey: APIKey) throws
    func getAllAPIKeys() -> [APIKey]
    func getAPIKey(named: String) -> APIKey?
}
