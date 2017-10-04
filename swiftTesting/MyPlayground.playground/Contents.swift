//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
let name = "Artur"
let age = 22
print("My name is \(name) and I am \(age) years old")
var a: Double = 5.76
var b: Int = 8

let c = a * Double(b)
print(c)

var array = [3.87, 7.1, 8.9]
array.remove(at: 1)
array.append(array[0] * array[1])

let menu = ["pizza": 10.99, "ice cream": 4.99,"salad": 7.99]
print ("The total cost of my meal is  \(menu["pizza"]! + menu["ice cream"]!)")


let username = "user1"
let password = "pass"
if username == "user" && password == "pass"{
    print ("Welcome \(username)")
} else if username == "user"{
    print ("Password Incorrect")
}else if password == "pass"{
    print ("Incorrect Username")
}else if username != "user" && password != "pass"{
    print("Both username and password incorrect")
}
