import Foundation

/// Minimal protobuf wire-format writer: Android TV Remote v2 only needs varints and length-delimited fields.
struct PB {
    var data = Data()

    static func varint(_ value: UInt64) -> Data {
        var v = value, out = Data()
        while v >= 0x80 { out.append(UInt8(v & 0x7F) | 0x80); v >>= 7 }
        out.append(UInt8(v))
        return out
    }

    mutating func int(_ field: Int, _ v: Int) {
        data += PB.varint(UInt64(field << 3))
        data += PB.varint(UInt64(bitPattern: Int64(v)))
    }

    mutating func bytes(_ field: Int, _ v: Data) {
        data += PB.varint(UInt64(field << 3 | 2))
        data += PB.varint(UInt64(v.count))
        data += v
    }

    mutating func string(_ field: Int, _ s: String) { bytes(field, Data(s.utf8)) }

    mutating func msg(_ field: Int, _ build: (inout PB) -> Void) {
        var m = PB()
        build(&m)
        bytes(field, m.data)
    }

    static func build(_ f: (inout PB) -> Void) -> Data { var m = PB(); f(&m); return m.data }
}

enum PBValue { case int(UInt64), bytes(Data) }
typealias PBFields = [Int: [PBValue]]

/// Reads a varint at `i`, advancing it. Returns nil if the buffer ends mid-varint.
func readVarint(_ b: [UInt8], _ i: inout Int) -> UInt64? {
    var result: UInt64 = 0, shift: UInt64 = 0
    while i < b.count {
        let byte = b[i]; i += 1
        result |= UInt64(byte & 0x7F) << shift
        if byte & 0x80 == 0 { return result }
        shift += 7
        if shift > 63 { return nil }
    }
    return nil
}

func pbDecode(_ data: Data) -> PBFields {
    let b = [UInt8](data)
    var i = 0, out = PBFields()
    while i < b.count, let key = readVarint(b, &i) {
        let field = Int(key >> 3)
        switch key & 7 {
        case 0: guard let v = readVarint(b, &i) else { return out }; out[field, default: []].append(.int(v))
        case 2:
            guard let n = readVarint(b, &i), i + Int(n) <= b.count else { return out }
            out[field, default: []].append(.bytes(Data(b[i..<i + Int(n)]))); i += Int(n)
        case 1: i += 8
        case 5: i += 4
        default: return out
        }
    }
    return out
}

extension Dictionary where Key == Int, Value == [PBValue] {
    func int(_ f: Int) -> Int? {
        if case let .int(v)? = self[f]?.first { return Int(truncatingIfNeeded: v) }
        return nil
    }
    func msg(_ f: Int) -> PBFields? {
        if case let .bytes(d)? = self[f]?.first { return pbDecode(d) }
        return nil
    }
}
