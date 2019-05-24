import UIKit

var str = "Hello, playground"


let a1 = ["A", "B", "C", "D"]
let a2 = ["A", "C", "D", "E"]

let listOfPatches = patch(from: a1, to: a2)

var debugString = ""

for p in listOfPatches {
    switch p {
    case .insertion(let index, let element):
        debugString += "[insert: \(index),\(element)]"
    case .deletion(let index):
        debugString += "[delete: \(index)]"
    }
}

debugString

