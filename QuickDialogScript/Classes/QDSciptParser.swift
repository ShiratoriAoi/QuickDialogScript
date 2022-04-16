import Foundation
import FootlessParser

//------------------------------------------------------------------
//  BNF Form Grammar for QuickDialogScript
// 
//  <QuickDialogScript> ::= <QuickDialogs>
//
//  <QuickDialogs> ::= <QuickDialog> | <QuickDialog> <QuickDialogs>
//  <QuickDialog>  ::= "qd " <name> <sp> <name> <br> <sections> "endqd" <br> 
//                      first name is key, second one is title
//
//  <sections> ::= <section> <br> | <section> <br> <sections> 
//  <section>  ::= "sec " <name> <br> <elements> "endsec" 
//               | "sec_user" <name> <br>
//
//  <elements> ::= <element> <br> | <element> <br> <elements>
//  <element>  ::= <btn> | <lbl> | <arw> | <img> | <bool>
//
//  <btn>  ::= "btn " <name> <sp> <action> 
//           | "btn " <name> <sp> <action> <sp> <tag>
//  <lbl>  ::= "lbl " <name> <sp> <action> 
//           | "lbl " <name> <sp> <action> <sp> <tag>
//  <arw>  ::= "arw " <name> <sp> <action> 
//           | "arw " <name> <sp> <action> <sp> <tag>
//  <img>  ::= "img " <name> <sp> <name> <sp> <action> 
//           | "img " <name> <sp> <name> <sp> <action> <sp> <tag> 
//             first name is title, second one is filename
//  <txt>  ::= "txt " <name>
//  <txp>  ::= "txp " <name> <name> 
//             first name is title, second one is filename
//  <bool> ::= "bool " <name> 
//           | "bool " <name> <tag>
//  <user> ::= "user " 
//           | "user " <tag>
//
//  <action> ::= "url " <name>
//             | "sub " <name> 
//             | "dismiss " 
//             | "none " 
//             | "user "
//
//  <name>    ::= <letters>
//  <letter>  ::= "a" ~ "z" | "A" ~ "Z"
//  <letters> ::= <letter> | <letter> <letters>
//  <br>      ... <br> means line breaks
//  <sp>      ... <sp> means spaces
//  
//--------------------------------------------------------------------

precedencegroup MyGroup {
  higherThan: ApplyGroup
  associativity: right
}

infix operator ***: MyGroup


public func *** <T,A,B> (p: Parser<A,B>, q: Parser<T, [A]>) -> Parser<T, B> {
    return q >>- { q_output in
        let collection = AnyCollection(q_output)
        let result = try p.parse(collection).output
        return Parser { input in
            return (result, input)
        }
    }
}


struct QDSRoot {
    let key  : String
    let title: String
	let sections: [QDSSection]
}

enum QDSSection {
    case Script(title: String, elements: [QDSElement])
    case User(key: String)
}

//TODO: bool float
enum QDSElement {
	case Button(title: String, action: QDSAction, tag: Int)
    case Label(title: String, action: QDSAction, tag: Int)
    case Arrow(title: String, action: QDSAction, tag: Int)
    case Icon(title: String, filename: String, action: QDSAction, tag: Int)
    case Bool(title: String, key: String, tag: Int)
    case Text(filename: String)
    case TextPage(title: String, filename: String)
    case User(tag: Int)
}

enum QDSAction {
	case url(String)
	case dismiss
	case sub(String)//subDialog
    case none
    case user
}

class QDSParserManager {
	var wordParser: Parser<Character, [String]>!
    var qdsParser:  Parser<String, [QDSRoot]>!
    
    init() {
        //------------------------------
        //junbi
        //------------------------------
        let word = oneOrMore(noneOf(" \n\"")) <* zeroOrMore(oneOf(" \n"))
        let quoteWord = { (val:String) in
            return "\"" + val + "\"" } <^> (char("\"") *> zeroOrMore(noneOf("\n\"")) <* char("\"") <* zeroOrMore(oneOf(" \n")))
        let words = zeroOrMore(oneOf(" \n")) *> zeroOrMore(word <|> quoteWord)
        let strMatch: ((String)->Parser<String, String>) = { a in satisfy(expect: a, condition: { b in a==b }) }
		var name: Parser<String, String>!
        name = { String($0.dropLast().dropFirst()) } <^> satisfy(expect: "(name)", condition: { str in
            let a = str.startIndex
            let b = str.index(str.endIndex, offsetBy: -1)
            return str[a] == "\"" && str[b] == "\""
        })
        var number: Parser<String, Int>! 
        number = { Int($0)! } <^> satisfy(expect: "(tag)", condition: { str in
            if let _ = Int(str) {
                return true
            }
            return false
        })
        let tag = optional(number, otherwise: 0)

        //------------------------------
        //action
        //------------------------------
        let url = { QDSAction.url($0) } <^> (strMatch("url") *> name)
        let dismiss = { _ in QDSAction.dismiss } <^> strMatch("dismiss")
        let none = { _ in QDSAction.none } <^> strMatch("none")
        let sub = { QDSAction.sub($0) } <^> (strMatch("sub") *> name)
        let user = { _ in QDSAction.user } <^> (strMatch("user"))
        let action =  url <|> dismiss <|> none <|> sub <|> user

        //------------------------------
        //element
        //------------------------------
        func makeButton(title: String, action: QDSAction, tag: Int) -> QDSElement {
            print("btn " + title)
            return QDSElement.Button(title: title, action: action, tag: tag)
        }
        let button = curry(makeButton) <^> (strMatch("btn") *> name) <*> action <*> tag
        func makeLabel(title: String, action: QDSAction, tag: Int) -> QDSElement {
            print("lbl " + title)
            return QDSElement.Label(title: title, action: action, tag: tag)
        }
        let label = curry(makeLabel) <^> (strMatch("lbl") *> name) <*> action <*> tag
        func makeArrow(title: String, action: QDSAction, tag: Int) -> QDSElement {
            print("arw " + title)
            return QDSElement.Arrow(title: title, action: action, tag: tag)
        }
        let arrow = curry(makeArrow) <^> (strMatch("arw") *> name) <*> action <*> tag
        func makeIcon(title: String,filename: String, action: QDSAction, tag: Int) -> QDSElement {
            print("img " + title)
            return QDSElement.Icon(title: title, filename: filename, action: action, tag: tag)
        }
        let icon = curry(makeIcon) <^> (strMatch("img") *> name) <*> name <*> action <*> tag
        func makeBool(title: String, key: String, tag: Int) -> QDSElement {
            print("bool " + title)
            return QDSElement.Bool(title: title,key: key, tag: tag)
        }
        let bool = curry(makeBool) <^> (strMatch("bool") *> name) <*> name <*> tag
        func makeText(filename: String) -> QDSElement {
            print("txt " + filename)
            return QDSElement.Text(filename: filename)
        }
        let text = makeText <^> (strMatch("txt") *> name)
        func makeTextPage(title: String, filename: String) -> QDSElement {
            print("txp " + title)
            return QDSElement.TextPage(title: title, filename: filename)
        }
        let textpage = curry(makeTextPage) <^> (strMatch("txp") *> name) <*> name
        func makeUserElm(tag: Int) -> QDSElement {
            print("user \(tag)")
            return QDSElement.User(tag: tag)
        }
        let userElm = makeUserElm <^> (strMatch("user") *> tag)

		let elementParser = button <|> label <|> arrow <|> icon <|> bool <|> text <|> textpage <|>  userElm

        //------------------------------
        //section
        //------------------------------
        func makeSection(title: String, elements: [QDSElement])->QDSSection {
            print("sec " + title)
            return QDSSection.Script(title: title, elements: elements)
        }
		let section = curry(makeSection) <^> (strMatch("sec") *> name) <*> (oneOrMore(elementParser) <* strMatch("endsec") )
        let sec_user = { QDSSection.User(key: $0) } <^> (strMatch("sec_user") *> name)
        let sectionParser = section <|> sec_user

        //------------------------------
        //dialog
        //------------------------------
        func makeQuickDialog(key: String, title: String, sections: [QDSSection])->QDSRoot {
            print("qd " + key + "," + title)
            return QDSRoot(key: key, title: title, sections: sections)
        }
        let quickDialogParser = curry(makeQuickDialog) <^> (strMatch("qd") *> name) <*> name <*> (oneOrMore(sectionParser) <* strMatch("endqd"))
		
        //------------------------------
        //dialogs <- [String]
        //------------------------------
        qdsParser = oneOrMore(quickDialogParser)

        //------------------------------
        //woradParser
        //------------------------------
        wordParser = words
   }
}

