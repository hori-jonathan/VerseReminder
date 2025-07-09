import SwiftUI

struct BibleBook: Identifiable, Equatable {
    let id: String           // e.g., "GEN"
    let name: String         // e.g., "Genesis"
    let chapters: Int        // number of chapters
    let order: Int           // for sorting
}

struct BookCategory: Identifiable {
    let id: String
    let name: String
    let books: [BibleBook]
}

let oldTestamentCategories: [BookCategory] = [
    BookCategory(id: "pentateuch", name: "Pentateuch", books: [
        BibleBook(id: "GEN", name: "Genesis", chapters: 50, order: 1),
        BibleBook(id: "EXO", name: "Exodus", chapters: 40, order: 2),
        BibleBook(id: "LEV", name: "Leviticus", chapters: 27, order: 3),
        BibleBook(id: "NUM", name: "Numbers", chapters: 36, order: 4),
        BibleBook(id: "DEU", name: "Deuteronomy", chapters: 34, order: 5)
    ]),
    BookCategory(id: "historical", name: "Historical Books", books: [
        BibleBook(id: "JOS", name: "Joshua", chapters: 24, order: 6),
        BibleBook(id: "JDG", name: "Judges", chapters: 21, order: 7),
        BibleBook(id: "RUT", name: "Ruth", chapters: 4, order: 8),
        BibleBook(id: "1SA", name: "1 Samuel", chapters: 31, order: 9),
        BibleBook(id: "2SA", name: "2 Samuel", chapters: 24, order: 10),
        BibleBook(id: "1KI", name: "1 Kings", chapters: 22, order: 11),
        BibleBook(id: "2KI", name: "2 Kings", chapters: 25, order: 12),
        BibleBook(id: "1CH", name: "1 Chronicles", chapters: 29, order: 13),
        BibleBook(id: "2CH", name: "2 Chronicles", chapters: 36, order: 14),
        BibleBook(id: "EZR", name: "Ezra", chapters: 10, order: 15),
        BibleBook(id: "NEH", name: "Nehemiah", chapters: 13, order: 16),
        BibleBook(id: "EST", name: "Esther", chapters: 10, order: 17)
    ]),
    BookCategory(id: "wisdom", name: "Wisdom Books", books: [
        BibleBook(id: "JOB", name: "Job", chapters: 42, order: 18),
        BibleBook(id: "PSA", name: "Psalms", chapters: 150, order: 19),
        BibleBook(id: "PRO", name: "Proverbs", chapters: 31, order: 20),
        BibleBook(id: "ECC", name: "Ecclesiastes", chapters: 12, order: 21),
        BibleBook(id: "SNG", name: "Song of Solomon", chapters: 8, order: 22)
    ]),
    BookCategory(id: "major-prophets", name: "Major Prophets", books: [
        BibleBook(id: "ISA", name: "Isaiah", chapters: 66, order: 23),
        BibleBook(id: "JER", name: "Jeremiah", chapters: 52, order: 24),
        BibleBook(id: "LAM", name: "Lamentations", chapters: 5, order: 25),
        BibleBook(id: "EZK", name: "Ezekiel", chapters: 48, order: 26),
        BibleBook(id: "DAN", name: "Daniel", chapters: 12, order: 27)
    ]),
    BookCategory(id: "minor-prophets", name: "Minor Prophets", books: [
        BibleBook(id: "HOS", name: "Hosea", chapters: 14, order: 28),
        BibleBook(id: "JOL", name: "Joel", chapters: 3, order: 29),
        BibleBook(id: "AMO", name: "Amos", chapters: 9, order: 30),
        BibleBook(id: "OBA", name: "Obadiah", chapters: 1, order: 31),
        BibleBook(id: "JON", name: "Jonah", chapters: 4, order: 32),
        BibleBook(id: "MIC", name: "Micah", chapters: 7, order: 33),
        BibleBook(id: "NAM", name: "Nahum", chapters: 3, order: 34),
        BibleBook(id: "HAB", name: "Habakkuk", chapters: 3, order: 35),
        BibleBook(id: "ZEP", name: "Zephaniah", chapters: 3, order: 36),
        BibleBook(id: "HAG", name: "Haggai", chapters: 2, order: 37),
        BibleBook(id: "ZEC", name: "Zechariah", chapters: 14, order: 38),
        BibleBook(id: "MAL", name: "Malachi", chapters: 4, order: 39)
    ])
]

let newTestamentCategories: [BookCategory] = [
    BookCategory(id: "gospels", name: "Gospels", books: [
        BibleBook(id: "MAT", name: "Matthew", chapters: 28, order: 40),
        BibleBook(id: "MRK", name: "Mark", chapters: 16, order: 41),
        BibleBook(id: "LUK", name: "Luke", chapters: 24, order: 42),
        BibleBook(id: "JHN", name: "John", chapters: 21, order: 43)
    ]),
    BookCategory(id: "history", name: "History", books: [
        BibleBook(id: "ACT", name: "Acts", chapters: 28, order: 44)
    ]),
    BookCategory(id: "pauline", name: "Pauline Epistles", books: [
        BibleBook(id: "ROM", name: "Romans", chapters: 16, order: 45),
        BibleBook(id: "1CO", name: "1 Corinthians", chapters: 16, order: 46),
        BibleBook(id: "2CO", name: "2 Corinthians", chapters: 13, order: 47),
        BibleBook(id: "GAL", name: "Galatians", chapters: 6, order: 48),
        BibleBook(id: "EPH", name: "Ephesians", chapters: 6, order: 49),
        BibleBook(id: "PHP", name: "Philippians", chapters: 4, order: 50),
        BibleBook(id: "COL", name: "Colossians", chapters: 4, order: 51),
        BibleBook(id: "1TH", name: "1 Thessalonians", chapters: 5, order: 52),
        BibleBook(id: "2TH", name: "2 Thessalonians", chapters: 3, order: 53),
        BibleBook(id: "1TI", name: "1 Timothy", chapters: 6, order: 54),
        BibleBook(id: "2TI", name: "2 Timothy", chapters: 4, order: 55),
        BibleBook(id: "TIT", name: "Titus", chapters: 3, order: 56),
        BibleBook(id: "PHM", name: "Philemon", chapters: 1, order: 57)
    ]),
    BookCategory(id: "general", name: "General Epistles", books: [
        BibleBook(id: "HEB", name: "Hebrews", chapters: 13, order: 58),
        BibleBook(id: "JAS", name: "James", chapters: 5, order: 59),
        BibleBook(id: "1PE", name: "1 Peter", chapters: 5, order: 60),
        BibleBook(id: "2PE", name: "2 Peter", chapters: 3, order: 61),
        BibleBook(id: "1JN", name: "1 John", chapters: 5, order: 62),
        BibleBook(id: "2JN", name: "2 John", chapters: 1, order: 63),
        BibleBook(id: "3JN", name: "3 John", chapters: 1, order: 64),
        BibleBook(id: "JUD", name: "Jude", chapters: 1, order: 65)
    ]),
    BookCategory(id: "revelation", name: "Revelation", books: [
        BibleBook(id: "REV", name: "Revelation", chapters: 22, order: 66)
    ])
]
