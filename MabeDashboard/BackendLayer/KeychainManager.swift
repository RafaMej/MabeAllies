internal import Foundation
import CryptoKit
import Security

struct KeychainManager {
    static func dek(paraDocumento id: String) throws -> SymmetricKey {
        let cuenta = "mabe.rrhh.dek.\(id)"
        let query: [String: Any] = [
            kSecClass as String:          kSecClassGenericPassword,
            kSecAttrAccount as String:    cuenta,
            kSecReturnData as String:     true,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        var resultado: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &resultado)
        if status == errSecSuccess, let data = resultado as? Data {
            return SymmetricKey(data: data)
        }
        let nuevaLlave = SymmetricKey(size: .bits256)
        let llaveData = nuevaLlave.withUnsafeBytes { Data($0) }
        let insertar: [String: Any] = [
            kSecClass as String:          kSecClassGenericPassword,
            kSecAttrAccount as String:    cuenta,
            kSecValueData as String:      llaveData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let insertStatus = SecItemAdd(insertar as CFDictionary, nil)
        guard insertStatus == errSecSuccess else {
            throw KeychainError.noSePudoGuardar(insertStatus)
        }
        return nuevaLlave
    }

    static func eliminar(documentoID: String) {
        let cuenta = "mabe.rrhh.dek.\(documentoID)"
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: cuenta]
        SecItemDelete(query as CFDictionary)
    }
}
