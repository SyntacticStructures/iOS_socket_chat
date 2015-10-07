//
//  ViewController.swift
//  chat_socket
//
//  Created by Computer on 10/7/15.
//  Copyright © 2015 Computer. All rights reserved.
//


//TO DO:  delete function on iOS is finickey. It doesn't always know whether it's message is it's own. also i need a quick way to hide the keyboard.


import UIKit
class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var infoTextLabel: UILabel!
    @IBOutlet weak var chatTextField: UITextField!
    @IBOutlet weak var chatTable: UITableView!
    
    let socket = SocketIOClient(socketURL: "192.168.1.242:8000")
    var userId: String?
    var userName: String?
    var messages = Array<[String:String]>()
//    alert dialoge
    override func viewDidLoad() {
        super.viewDidLoad()
        var alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title:"OK", style:UIAlertActionStyle.Default){(ACTION) in
        }
        self.presentViewController(alert, animated: true, completion: nil)
        chatTable.dataSource = self
        self.userId = randomStringWithLength(10) as String
        socket.connect()
        socket.on("connect") { data, ack in
            print("iOS::WE ARE USING SOCKETS!")
        }
        socket.on("chat_response") {data, ack in
            var newMessage = [String:String]()
            let content = data[0]["content"] as! String
            let name = data[0]["name"] as! String
            let message_id = data[0]["message_id"] as! String
            let id = data[0]["id"] as! String
            newMessage["content"] = content
            newMessage["name"] = name
            newMessage["id"] = id
            newMessage["message_id"] = message_id
            if newMessage["id"]! == self.userId! {
                print("yes")
                newMessage["ownedByMe"] = "yes"
            } else {
                print("no")
                newMessage["ownedByMe"] = "no"
            }
            print("chekcing here")
            print(newMessage["ownedByMe"])
            self.messages.append(newMessage)
            self.chatTable.reloadData()
        }
        socket.on("delete_message") { data, ack in
//            loop checks by message_id whether whether we have something to delete and deletes it. It ends with a table reload.
            for var index = 0; index < self.messages.count; ++index {
                if String(self.messages[index]["message_id"]!) == String(data[0]["message_id"]!!) {
                    self.messages.removeAtIndex(0)
                    self.chatTable.reloadData()
                }
            }
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell") as! MessageCell
        let message = self.messages[indexPath.row]
        cell.messageTextLabel.text = message["content"]
        self.messages[indexPath.row]["index"] = String([indexPath.row])
        cell.nameTextLabel.text = message["name"]
        print(message)
        if message["ownedByMe"] == "no" {
            print("we don't thing it's yours")
            cell.deleteButton.hidden = true
        }
        return cell
    }
    @IBAction func chatButtonPressed(sender: UIButton) {
        if (self.userName != nil) {
            var dictionaryToPasss = [String:String]()
            dictionaryToPasss["content"] = chatTextField.text!
            dictionaryToPasss["id"] = self.userId!
            dictionaryToPasss["message_id"] = randomStringWithLength(10) as String
            dictionaryToPasss["name"] = self.userName!
            socket.emit("message_sent", dictionaryToPasss);
        } else {
            showAlert()
        }
    }
    @IBAction func deleteButtonPressed(sender: AnyObject) {
        let button = sender as! UIButton
        let view = button.superview!
        let cell = view.superview as! MessageCell
        let indexPath = self.chatTable.indexPathForCell(cell)!
        socket.emit("message_deleted", self.messages[indexPath.row])
    }
    
    func showAlert(){
        var alertController:UIAlertController?
        alertController = UIAlertController(title: "Username",
            message: "You need a username to chat",
            preferredStyle: .Alert)
        
        alertController!.addTextFieldWithConfigurationHandler(
            {(textField: UITextField!) in
                textField.placeholder = "Enter something"
        })
        
        let action = UIAlertAction(title: "Submit",
            style: UIAlertActionStyle.Default,
            handler: {[weak self]
                (paramAction:UIAlertAction!) in
                if let textFields = alertController?.textFields{
                    let theTextFields = textFields as [UITextField]
                    let enteredText = theTextFields[0].text
                    if (enteredText != nil) {
                        self?.userName = enteredText!
                    }
                }
            })
        
        alertController?.addAction(action)
        self.presentViewController(alertController!,
            animated: true,
            completion: nil)
    }
    func randomStringWithLength (len : Int) -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString
    }
}
