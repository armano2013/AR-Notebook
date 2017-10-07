//
//  ViewController.swift
//  catYearsV2
//
//  Created by Artur Bushi on 10/6/17.
//  Copyright © 2017 Artur Bushi. All rights reserved.
//

import UIKit
import SQLite

class ViewController: UIViewController {
    var database: Connection!
    
    let yearsTable = Table("years")
    let id = Expression<Int>("id")
    let originalYear = Expression<String>("originalYear")
    let catYear = Expression<String>("catYear")
    
    @IBAction func createTable() {
        print ("CREATE TAPPED")
        
        let createTable = self.yearsTable.create { (table) in
            table.column(self.id, primaryKey: true)
            table.column(self.originalYear)
            table.column(self.catYear)
        }
        do{
            try self.database.run(createTable)
            print ("Created Table")
        } catch {
            print(error)
        }
    }
    
    @IBAction func listEntries() {
        print ("LIST ENTRIES")
        
        do {
            let years = try self.database.prepare(self.yearsTable)
            for year in years{
                print("ID: \(year[self.id]), Original Year: \(year[self.originalYear]), Cat Year: \(year[self.catYear])")
            }
            
        } catch {
            print(error)
        }
    }
    
    @IBAction func updateYear() {
        print ("UPDATE ENTRY")
        
        let alert = UIAlertController(title: "Update Year", message: nil, preferredStyle: .alert)
        alert.addTextField { (tf) in tf.placeholder = "Year ID"}
        alert.addTextField { (tf) in tf.placeholder = "Original Year"}
        let action = UIAlertAction(title: "Submit", style: .default) { (_) in
            guard let yearIdString = alert.textFields?.first?.text,
                let yearId = Int(yearIdString),
                let originalYear = alert.textFields?.last?.text
                else {return }
            print(yearIdString)
            print(originalYear)
            
            let year = self.yearsTable.filter(self.id == yearId)
            let updateYear = year.update(self.originalYear <- originalYear)
            do {
                try self.database.run(updateYear)
            } catch {
                print(error)
            }
            
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func deleteYear() {
        print ("delete ENTRY")
        
        let alert = UIAlertController(title: "Update Year", message: nil, preferredStyle: .alert)
        alert.addTextField { (tf) in tf.placeholder = "Year ID"}
        let action = UIAlertAction(title: "Submit", style: .default) { (_) in
            guard let yearIdString = alert.textFields?.first?.text,
                let yearId = Int(yearIdString)
                else {return }
            print(yearIdString)
            
            let year = self.yearsTable.filter(self.id == yearId)
            let deleteYear = year.delete()
            do {
                try self.database.run(deleteYear)
            } catch {
                print(error)
            }
            
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func deleteAll(_ sender: Any) {
        let year = self.yearsTable
        let deleteAll = year.drop(ifExists: true)
        
        do {
            try self.database.run(deleteAll)
        } catch{
            print (error)
        }
    }
    
    @IBOutlet weak var ageTextField: UITextField!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var cat: UIImageView!
    @IBAction func getAge(_ sender: Any) {
        
        
        if let age = ageTextField.text {
            if let ageAsNumber = Int(age) {
                let catAge = ageAsNumber * 7
                resultLabel.text = "Your cat is " + String(catAge) + " in cat years!"
                
                let insertOriginal = self.yearsTable.insert(self.originalYear <- age, self.catYear <- String(catAge))
                
                do {
                    try self.database.run(insertOriginal)
                    print ("Inserted Years")
                } catch {
                    print (error)
                }
            }
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("years").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

