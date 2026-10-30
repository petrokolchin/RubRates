import Foundation

/// Образцы ответа `XML_dynamic.asp`: XML в кодировке windows-1251, числа с запятой.
enum SampleHistoryResponses {
    struct Record {
        let date: String
        var nominal = 1
        let value: String?
    }

    static func xml(_ records: [Record]) -> Data {
        let body = records.map { record in
            let value = record.value.map { "<Value>\($0)</Value>" } ?? ""
            return """
            <Record Date="\(record.date)" Id="R01235"><Nominal>\(record.nominal)</Nominal>\(value)\
            <VunitRate>0</VunitRate></Record>
            """
        }.joined()
        let text = """
        <?xml version="1.0" encoding="windows-1251"?><ValCurs ID="R01235" DateRange1="16.10.2026" \
        DateRange2="30.10.2026" name="Foreign Currency Market Dynamic">\(body)</ValCurs>
        """
        return text.data(using: .windowsCP1251)!
    }

    /// Три рабочих дня USD (значения ЦБ от 16–20.10.2026).
    static let usdThreeDays = xml([
        Record(date: "16.10.2026", value: "83,7600"),
        Record(date: "17.10.2026", value: "83,6177"),
        Record(date: "20.10.2026", value: "82,8504"),
    ])
}
