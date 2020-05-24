/*

Copyright 2019 Marcus Deuß

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/


//
//  MenuController.swift
//  Inventory
//
//  Created by Marcus Deuß on 09.04.20.
//  Copyright © 2020 Marcus Deuß. All rights reserved.
//

import UIKit

class MenuController{
    
    // macCatalyst: Create menu
    #if targetEnvironment(macCatalyst)
    
    /* Create UIMenu objects and use them to construct the menus and submenus your app displays. You provide menus for your app when it runs on macOS, and key command elements in those menus also appear in the discoverability HUD on iPad when the user presses the command key. You also use menus to display contextual actions in response to specific interactions with one of your views. Every menu has a title, an optional image, and an optional set of child elements. When the user selects an element from the menu, the system executes the code that you provide.
     */
    
    struct CommandPListKeys {
        static let ArrowsKeyIdentifier = "id"   // Arrow command-keys
        static let PaperIdentifierKey = "paper" // paper style commands
        static let ToolsIdentifierKey = "tool"  // Tool commands
    }
    
    
    init(with builder: UIMenuBuilder) {
        // First remove the menus in the menu bar you don't want, in our case the Format menu.
        // The format menu doesn't make sense
        builder.remove(menu: .format)
        builder.remove(menu: .edit)
        builder.remove(menu: .help)
        
        //builder.insertSibling(MenuController.preferencesMenu(), afterMenu: .about)
        
   
        
    }
/*
    class func preferencesMenu() -> UIMenu {
        // Create the preferences/about menu entries with command-p
        
        let prefCommand = UIKeyCommand(title: NSLocalizedString("Preferences", comment: "Preferences"),
                                        image: nil,
                                        action: #selector(AppDelegate.preferencesMenu),
                                        input: "T",
                                        modifierFlags: .command,
                                        propertyList: nil)
        
        return UIMenu(title: "",
                      image: nil,
                      identifier: UIMenu.Identifier("de.marcus-deuss.menus.preferences"),
                      options: [.displayInline],
                      children: [prefCommand])
    }
  */
    

    
    #endif
    
}
