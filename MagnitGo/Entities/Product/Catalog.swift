import Foundation

/// Demo catalogue. In production this is the store's price list, fetched for the
/// store the shopper is standing in.
enum Catalog {
    static let pieces: [Product] = [
        Product(id: "4780000000017", nameUz: "Sut 3,2%, 1 l", nameRu: "Молоко 3,2%, 1 л", price: 14_990, photo: "milk",
                aboutUz: "Pasterizatsiyalangan sigir suti, yog‘liligi 3,2%. Ochilgandan keyin 0…+6 °C da 3 kungacha saqlang.",
                aboutRu: "Пастеризованное коровье молоко жирностью 3,2%. После вскрытия храните при 0…+6 °C до 3 дней."),
        Product(id: "4780000000024", nameUz: "Buxanka non", nameRu: "Хлеб «Буханка»", price: 4_500, photo: "bread",
                aboutUz: "Bug‘doy unidan har kuni pishiriladigan non. Xona haroratida 3 kungacha saqlanadi.",
                aboutRu: "Пшеничный хлеб ежедневной выпечки. Хранится при комнатной температуре до 3 дней."),
        Product(id: "4780000000031", nameUz: "Tuxum C1, 10 dona", nameRu: "Яйца С1, 10 шт", price: 16_990, photo: "eggs",
                aboutUz: "Birinchi toifali tovuq tuxumi, har biri 55–65 g. Sovutgichda saqlang.",
                aboutRu: "Куриные яйца первой категории, 55–65 г каждое. Храните в холодильнике."),
        Product(id: "4780000000048", nameUz: "Apelsin sharbati, 1 l", nameRu: "Сок апельсиновый, 1 л", price: 22_990, marked: true, photo: "juice",
                aboutUz: "Apelsin sharbati, shakar qo‘shilmagan. Ochilgandan keyin sovutgichda 2 kungacha saqlang.",
                aboutRu: "Апельсиновый сок без добавления сахара. После вскрытия храните в холодильнике до 2 дней."),
        Product(id: "4780000000055", nameUz: "Gazsiz suv, 1,5 l", nameRu: "Вода без газа, 1,5 л", price: 5_990, marked: true, photo: "water",
                aboutUz: "Gazsiz ichimlik suvi. Quyosh nuridan uzoqda saqlang.",
                aboutRu: "Питьевая негазированная вода. Храните вдали от солнечного света."),
        Product(id: "4780000000062", nameUz: "Sutli shokolad, 90 g", nameRu: "Шоколад молочный, 90 г", price: 18_990, photo: "chocolate",
                aboutUz: "Sutli shokolad, kakao kamida 30%. Tarkibida sut va soya bor.",
                aboutRu: "Молочный шоколад, какао не менее 30%. Содержит молоко и сою."),
        Product(id: "4780000000079", nameUz: "Golland pishlog'i, 200 g", nameRu: "Сыр голландский, 200 г", price: 32_990, photo: "cheese",
                aboutUz: "Yarim qattiq pishloq, yog‘liligi 45%. Sovutgichda, o‘ralgan holda saqlang.",
                aboutRu: "Полутвёрдый сыр жирностью 45%. Храните в холодильнике в упаковке."),
        Product(id: "4780000000086", nameUz: "Makaron, 400 g", nameRu: "Макароны, 400 г", price: 9_990, photo: "pasta",
                aboutUz: "Qattiq bug‘doy navlaridan makaron. 8–10 daqiqa qaynatiladi.",
                aboutRu: "Макароны из твёрдых сортов пшеницы. Варить 8–10 минут."),
        Product(id: "4780000000093", nameUz: "Eruvchan qahva, 95 g", nameRu: "Кофе растворимый, 95 г", price: 54_990, photo: "coffee",
                aboutUz: "Sublimatsiyalangan eruvchan qahva. Quruq joyda, yopiq idishda saqlang.",
                aboutRu: "Сублимированный растворимый кофе. Храните в сухом месте, в закрытой банке."),
    ]

    static let weighted: [Product] = [
        Product(id: "00017", nameUz: "Banan", nameRu: "Бананы", price: 21_990, weighted: true, photo: "banana",
                aboutUz: "Tarozida tortiladi: narxi 1 kg uchun. Tarozi yorlig‘ini skanerlang.",
                aboutRu: "Взвешивается на весах: цена за 1 кг. Отсканируйте этикетку с весов."),
        Product(id: "00023", nameUz: "Qizil olma", nameRu: "Яблоки красные", price: 16_990, weighted: true, photo: "apple",
                aboutUz: "Tarozida tortiladi: narxi 1 kg uchun. Tarozi yorlig‘ini skanerlang.",
                aboutRu: "Взвешивается на весах: цена за 1 кг. Отсканируйте этикетку с весов."),
        Product(id: "00031", nameUz: "Pomidor", nameRu: "Помидоры", price: 24_990, weighted: true, photo: "tomato",
                aboutUz: "Tarozida tortiladi: narxi 1 kg uchun. Tarozi yorlig‘ini skanerlang.",
                aboutRu: "Взвешивается на весах: цена за 1 кг. Отсканируйте этикетку с весов."),
    ]

    /// Pack details by product id. Demo data: typical values for each kind of product,
    /// not read off a real pack. In production they come with the price list.
    static let facts: [String: ProductFacts] = [
        // Milk 3.2%
        "4780000000017": ProductFacts(
            nutrition: Nutrition(kcal: 58, protein: 2.9, fat: 3.2, carbs: 4.7), perMl: true,
            ingredientsUz: "Normallashtirilgan sigir suti", ingredientsRu: "Молоко коровье нормализованное",
            shelfLifeUz: "7 kun, 0…+6 °C da", shelfLifeRu: "7 суток при 0…+6 °C",
            countryUz: "O‘zbekiston", countryRu: "Узбекистан"),
        // Bread
        "4780000000024": ProductFacts(
            nutrition: Nutrition(kcal: 242, protein: 8.1, fat: 1.0, carbs: 48.8),
            ingredientsUz: "Bug‘doy uni, suv, xamirturush, tuz", ingredientsRu: "Мука пшеничная, вода, дрожжи, соль",
            shelfLifeUz: "3 kun", shelfLifeRu: "3 суток",
            countryUz: "O‘zbekiston", countryRu: "Узбекистан"),
        // Eggs
        "4780000000031": ProductFacts(
            nutrition: Nutrition(kcal: 157, protein: 12.7, fat: 11.5, carbs: 0.7),
            ingredientsUz: "Tovuq tuxumi", ingredientsRu: "Яйцо куриное",
            shelfLifeUz: "25 kun, 0…+20 °C da", shelfLifeRu: "25 суток при 0…+20 °C",
            countryUz: "O‘zbekiston", countryRu: "Узбекистан"),
        // Orange juice
        "4780000000048": ProductFacts(
            nutrition: Nutrition(kcal: 45, protein: 0.7, fat: 0.2, carbs: 10.0), perMl: true,
            ingredientsUz: "Konsentratdan tiklangan apelsin sharbati", ingredientsRu: "Сок апельсиновый восстановленный",
            shelfLifeUz: "12 oy; ochilgandan keyin 2 kun", shelfLifeRu: "12 месяцев; после вскрытия 2 суток",
            countryUz: "O‘zbekiston", countryRu: "Узбекистан"),
        // Still water
        "4780000000055": ProductFacts(
            nutrition: Nutrition(kcal: 0, protein: 0, fat: 0, carbs: 0), perMl: true,
            ingredientsUz: "Ichimlik suvi", ingredientsRu: "Вода питьевая",
            shelfLifeUz: "12 oy", shelfLifeRu: "12 месяцев",
            countryUz: "O‘zbekiston", countryRu: "Узбекистан"),
        // Milk chocolate
        "4780000000062": ProductFacts(
            nutrition: Nutrition(kcal: 535, protein: 7.6, fat: 29.7, carbs: 59.4),
            ingredientsUz: "Shakar, kakao moyi, quruq sut, kakao massasi, emulgator (soya lesitini), vanilin",
            ingredientsRu: "Сахар, какао-масло, молоко сухое, какао тёртое, эмульгатор (лецитин соевый), ванилин",
            shelfLifeUz: "12 oy, +15…+21 °C da", shelfLifeRu: "12 месяцев при +15…+21 °C",
            countryUz: "Rossiya", countryRu: "Россия"),
        // Dutch cheese
        "4780000000079": ProductFacts(
            nutrition: Nutrition(kcal: 352, protein: 26.0, fat: 26.8, carbs: 0),
            ingredientsUz: "Pasterizatsiyalangan sut, tuz, sut achitqisi, shirdon fermenti, kalsiy xlorid",
            ingredientsRu: "Молоко пастеризованное, соль, закваска, молокосвёртывающий фермент, хлорид кальция",
            shelfLifeUz: "60 kun, 0…+6 °C da", shelfLifeRu: "60 суток при 0…+6 °C",
            countryUz: "Belarus", countryRu: "Беларусь"),
        // Pasta
        "4780000000086": ProductFacts(
            nutrition: Nutrition(kcal: 344, protein: 10.4, fat: 1.1, carbs: 71.5),
            ingredientsUz: "Qattiq bug‘doy navlaridan yorma, suv", ingredientsRu: "Крупка из твёрдых сортов пшеницы, вода",
            shelfLifeUz: "24 oy", shelfLifeRu: "24 месяца",
            countryUz: "O‘zbekiston", countryRu: "Узбекистан"),
        // Instant coffee
        "4780000000093": ProductFacts(
            nutrition: Nutrition(kcal: 76, protein: 15.0, fat: 0.5, carbs: 3.0),
            ingredientsUz: "Tabiiy eruvchan qahva", ingredientsRu: "Кофе натуральный растворимый",
            shelfLifeUz: "24 oy", shelfLifeRu: "24 месяца",
            countryUz: "Germaniya", countryRu: "Германия"),
        // Bananas
        "00017": ProductFacts(
            nutrition: Nutrition(kcal: 96, protein: 1.5, fat: 0.5, carbs: 21.0),
            shelfLifeUz: "Xona haroratida 5–7 kun", shelfLifeRu: "5–7 суток при комнатной температуре",
            countryUz: "Ekvador", countryRu: "Эквадор"),
        // Apples
        "00023": ProductFacts(
            nutrition: Nutrition(kcal: 47, protein: 0.4, fat: 0.4, carbs: 9.8),
            shelfLifeUz: "Sovutgichda 1 oygacha", shelfLifeRu: "В холодильнике до 1 месяца",
            countryUz: "O‘zbekiston", countryRu: "Узбекистан"),
        // Tomatoes
        "00031": ProductFacts(
            nutrition: Nutrition(kcal: 20, protein: 1.1, fat: 0.2, carbs: 3.8),
            shelfLifeUz: "Xona haroratida 5 kungacha", shelfLifeRu: "До 5 суток при комнатной температуре",
            countryUz: "O‘zbekiston", countryRu: "Узбекистан"),
    ]

    /// What the demo buttons "scan" where there is no camera. Scale labels carry the
    /// weight; for marked drinks `demoCode` turns the entry into a fresh marking code.
    static let demoShelf: [String] = [
        "4780000000017",
        scaleLabel(plu: "00017", grams: 842),
        "4780000000055",
        "4780000000024",
        "4780000000048",
        scaleLabel(plu: "00031", grams: 615),
        "4780000000031",
        "4780000000079",
        "4780000000062",
        scaleLabel(plu: "00023", grams: 1_204),
        "4780000000093",
        "4780000000086",
    ]

    /// With real products in hand during a demo, map any unknown retail barcode or
    /// marking code onto the demo catalogue so every scan lands. Turn off once a real
    /// price list is wired in.
    static let mapsUnknownBarcodesForDemo = true

    /// Scale labels use the in-store EAN-13 range: `21` + PLU (5) + grams (5) + check digit.
    static func scaleLabel(plu: String, grams: Int) -> String {
        let body = "21" + plu + String(format: "%05d", grams)
        return body + String(checkDigit(body))
    }

    /// The code a demo button sends. Each press on a marked drink is a different
    /// bottle, so it gets its own serial.
    static func demoCode(_ entry: String) -> String {
        guard let product = pieces.first(where: { $0.id == entry }), product.marked else { return entry }
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789")
        let serial = String((0..<13).map { _ in alphabet.randomElement() ?? "A" })
        let check = String((0..<4).map { _ in alphabet.randomElement() ?? "A" })
        return "010" + entry + "21" + serial + String(MarkingCode.separator) + "93" + check
    }

    static func resolve(_ raw: String) -> ScannedItem? {
        // A marking code first: it also starts with digits, but is not a barcode.
        if let mark = MarkingCode(raw) {
            if let product = pieces.first(where: { $0.id == mark.ean13 }) {
                return ScannedItem(product: product, mark: mark.raw)
            }
            if mapsUnknownBarcodesForDemo {
                let drinks = pieces.filter(\.marked)
                let sum = mark.gtin.compactMap(\.wholeNumberValue).reduce(0, +)
                return ScannedItem(product: drinks[sum % drinks.count], mark: mark.raw)
            }
            return nil
        }

        let code = raw.filter(\.isNumber)

        if code.count == 13, code.hasPrefix("21") {
            let chars = Array(code)
            let plu = String(chars[2..<7])
            let grams = Int(String(chars[7..<12])) ?? 0
            if grams > 0, let product = weighted.first(where: { $0.id == plu }) {
                return ScannedItem(product: product, grams: grams)
            }
            return nil
        }

        if let product = pieces.first(where: { $0.id == code }) {
            return ScannedItem(product: product)
        }

        if mapsUnknownBarcodesForDemo, [8, 12, 13].contains(code.count) {
            // Unknown barcodes land on unmarked goods only, so a real product in hand
            // never dead-ends on "scan the marking code".
            let plain = pieces.filter { !$0.marked }
            let sum = code.compactMap(\.wholeNumberValue).reduce(0, +)
            return ScannedItem(product: plain[sum % plain.count])
        }
        return nil
    }

    private static func checkDigit(_ body: String) -> Int {
        let digits = body.compactMap(\.wholeNumberValue)
        let sum = digits.enumerated().reduce(0) { $0 + $1.element * ($1.offset.isMultiple(of: 2) ? 1 : 3) }
        return (10 - sum % 10) % 10
    }
}
