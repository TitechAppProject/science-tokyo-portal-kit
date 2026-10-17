import Foundation

/// WebAuthn の attestationObject / COSE key をエンコードするための
/// 最小限のCBORエンコーダ。
/// 必要な構造 (map / array / integer / text / byte string) のみを扱う。
enum CBOREncoder {
    enum Value {
        case unsignedInt(UInt64)
        case negativeInt(Int64)
        case byteString(Data)
        case textString(String)
        case array([Value])
        case map([(Value, Value)])
    }

    static func encode(_ value: Value) -> Data {
        var data = Data()
        encode(value, into: &data)
        return data
    }

    private static func encode(_ value: Value, into data: inout Data) {
        switch value {
        case .unsignedInt(let uint):
            appendUnsignedInteger(uint, majorType: 0, into: &data)
        case .negativeInt(let int):
            appendUnsignedInteger(UInt64(-1 - int), majorType: 1, into: &data)
        case .byteString(let bytes):
            appendUnsignedInteger(UInt64(bytes.count), majorType: 2, into: &data)
            data.append(bytes)
        case .textString(let text):
            let utf8 = Data(text.utf8)
            appendUnsignedInteger(UInt64(utf8.count), majorType: 3, into: &data)
            data.append(utf8)
        case .array(let array):
            appendUnsignedInteger(UInt64(array.count), majorType: 4, into: &data)
            array.forEach { encode($0, into: &data) }
        case .map(let map):
            appendUnsignedInteger(UInt64(map.count), majorType: 5, into: &data)
            for (key, val) in map {
                encode(key, into: &data)
                encode(val, into: &data)
            }
        }
    }

    private static func appendUnsignedInteger(_ value: UInt64, majorType: UInt8, into data: inout Data) {
        let major: UInt8 = majorType << 5
        switch value {
        case 0...23:
            data.append(major | UInt8(value))
        case 24...255:
            data.append(major | 24)
            data.append(UInt8(value))
        case 256...65535:
            data.append(major | 25)
            appendBytes(UInt16(value), into: &data)
        case 65536...4_294_967_295:
            data.append(major | 26)
            appendBytes(UInt32(value), into: &data)
        default:
            data.append(major | 27)
            appendBytes(UInt64(value), into: &data)
        }
    }

    private static func appendBytes<T: FixedWidthInteger>(_ value: T, into data: inout Data) {
        var bigEndian = value.bigEndian
        withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
    }
}
