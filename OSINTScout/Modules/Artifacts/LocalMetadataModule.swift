import Foundation
import ImageIO
import UniformTypeIdentifiers

struct LocalMetadataModule: OSINTModule {
    let id = "artifacts.metadata"
    let title = "EXIF/Metadata"
    let description = "Анализ локальных файлов"
    let category = "Артефакты"
    let isFreeTier = true

    func supports(_ entity: Entity) -> Bool {
        false
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        throw AppError.validation("Модуль работает только с локальными файлами")
    }

    func extractMetadata(from url: URL, ethicalMode: Bool) throws -> ModuleResult {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        var artifacts: [Artifact] = []
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, options) {
            if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                for (key, value) in properties {
                    artifacts.append(Artifact(title: key, value: "\(value)", isSensitive: ethicalMode))
                }
            }
        }
        let summary = artifacts.isEmpty ? "Метаданные не найдены" : "Извлечено \(artifacts.count) метаданных"
        return ModuleResult(moduleID: id, moduleName: title, entity: url.lastPathComponent, summary: summary, artifacts: artifacts, sourceLinks: [], raw: [:])
    }
}
