import CoreData

protocol PersistenceProvider {
    var container: NSPersistentCloudKitContainer { get }
    func save()
}
