import Foundation
import FootlessParser

//------------------------------------------------------------------
//name = "~~~"
//quickdialogs = (<quickdialog>)+
//quickdialog = qd <name> <name> (<section>)+ endqd //first name key, second title
//section = sec <name> (<element>)+ endsec | sec_user <name>
//element = <btn> | <lbl> | <arw> | <img> | <bool>
//btn = btn <name> <action> (<tag>)
//lbl = lbl <name> <action> (<tag>)
//arw = arw <name> <action> (<tag>)
//img = img <name> <name> <action> (<tag>) //first name title, second name filename
//txt = txt <name>
//txp = txp <name> <name> //first name title, second filename
//bool = bool <name> (<tag>)
//user = user <tag>
//
//action = url <name> | sub <name> | dismiss | none | user
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


struct ScriptedQDNCRoot {
    let key  : String
    let title: String
	let sections: [ScriptedQDNCSection]
}

enum ScriptedQDNCSection {
    case Script(title: String, elements: [ScriptedQDNCElement])
    case User(key: String)
}

//TODO: bool float
enum ScriptedQDNCElement {
	case Button(title: String, action: ScriptedQDNCAction, tag: Int)
    case Label(title: String, action: ScriptedQDNCAction, tag: Int)
    case Arrow(title: String, action: ScriptedQDNCAction, tag: Int)
    case Icon(title: String, filename: String, action: ScriptedQDNCAction, tag: Int)
    case Bool(title: String, key: String, tag: Int)
    case Text(filename: String)
    case TextPage(title: String, filename: String)
    case User(tag: Int)
}

enum ScriptedQDNCAction {
	case url(String)
	case dismiss
	case sub(String)//subDialog
    case none
    case user
}

class ScriptedQDNCParserManager {
	var wordParser: Parser<Character, [String]>!
    var qdsParser:  Parser<String, [ScriptedQDNCRoot]>!
    
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
        let url = { ScriptedQDNCAction.url($0) } <^> (strMatch("url") *> name)
        let dismiss = { _ in ScriptedQDNCAction.dismiss } <^> strMatch("dismiss")
        let none = { _ in ScriptedQDNCAction.none } <^> strMatch("none")
        let sub = { ScriptedQDNCAction.sub($0) } <^> (strMatch("sub") *> name)
        let user = { _ in ScriptedQDNCAction.user } <^> (strMatch("user"))
        let action =  url <|> dismiss <|> none <|> sub <|> user

        //------------------------------
        //element
        //------------------------------
        func makeButton(title: String, action: ScriptedQDNCAction, tag: Int) -> ScriptedQDNCElement {
            print("btn " + title)
            return ScriptedQDNCElement.Button(title: title, action: action, tag: tag)
        }
        let button = curry(makeButton) <^> (strMatch("btn") *> name) <*> action <*> tag
        func makeLabel(title: String, action: ScriptedQDNCAction, tag: Int) -> ScriptedQDNCElement {
            print("lbl " + title)
            return ScriptedQDNCElement.Label(title: title, action: action, tag: tag)
        }
        let label = curry(makeLabel) <^> (strMatch("lbl") *> name) <*> action <*> tag
        func makeArrow(title: String, action: ScriptedQDNCAction, tag: Int) -> ScriptedQDNCElement {
            print("arw " + title)
            return ScriptedQDNCElement.Arrow(title: title, action: action, tag: tag)
        }
        let arrow = curry(makeArrow) <^> (strMatch("arw") *> name) <*> action <*> tag
        func makeIcon(title: String,filename: String, action: ScriptedQDNCAction, tag: Int) -> ScriptedQDNCElement {
            print("img " + title)
            return ScriptedQDNCElement.Icon(title: title, filename: filename, action: action, tag: tag)
        }
        let icon = curry(makeIcon) <^> (strMatch("img") *> name) <*> name <*> action <*> tag
        func makeBool(title: String, key: String, tag: Int) -> ScriptedQDNCElement {
            print("bool " + title)
            return ScriptedQDNCElement.Bool(title: title,key: key, tag: tag)
        }
        let bool = curry(makeBool) <^> (strMatch("bool") *> name) <*> name <*> tag
        func makeText(filename: String) -> ScriptedQDNCElement {
            print("txt " + filename)
            return ScriptedQDNCElement.Text(filename: filename)
        }
        let text = makeText <^> (strMatch("txt") *> name)
        func makeTextPage(title: String, filename: String) -> ScriptedQDNCElement {
            print("txp " + title)
            return ScriptedQDNCElement.TextPage(title: title, filename: filename)
        }
        let textpage = curry(makeTextPage) <^> (strMatch("txp") *> name) <*> name
        func makeUserElm(tag: Int) -> ScriptedQDNCElement {
            print("user \(tag)")
            return ScriptedQDNCElement.User(tag: tag)
        }
        let userElm = makeUserElm <^> (strMatch("user") *> tag)

		let elementParser = button <|> label <|> arrow <|> icon <|> bool <|> text <|> textpage <|>  userElm

        //------------------------------
        //section
        //------------------------------
        func makeSection(title: String, elements: [ScriptedQDNCElement])->ScriptedQDNCSection {
            print("sec " + title)
            return ScriptedQDNCSection.Script(title: title, elements: elements)
        }
		let section = curry(makeSection) <^> (strMatch("sec") *> name) <*> (oneOrMore(elementParser) <* strMatch("endsec") )
        let sec_user = { ScriptedQDNCSection.User(key: $0) } <^> (strMatch("sec_user") *> name)
        let sectionParser = section <|> sec_user

        //------------------------------
        //dialog
        //------------------------------
        func makeQuickDialog(key: String, title: String, sections: [ScriptedQDNCSection])->ScriptedQDNCRoot {
            print("qd " + key + "," + title)
            return ScriptedQDNCRoot(key: key, title: title, sections: sections)
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

