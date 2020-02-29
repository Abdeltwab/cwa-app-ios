//
//  SettingsView.swift
//  Kurzwahl2020
//
//  Created by Andreas Vogel on 12.01.20.
//  Copyright © 2020 Vogel, Andreas. All rights reserved.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var model : kurzwahlModel
    @EnvironmentObject var navigation: NavigationStack
    
    
    var body: some View {
        NavigationView {
            VStack{
                Form {
                    Section(header: Text("Font Size")) {
                        Stepper(value: $model.fontSize, in: 12...64) {
                            Text("Size: \(model.getFontSizeAsInt())")
                        } //.labelsHidden
                    }.padding(.leading, 2.0)
                    Button(action: {
                        self.navigation.advance(NavigationItem(
                    view: AnyView(AboutView()))) }) {
                        Text("About")
                    }.buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        self.navigation.advance(NavigationItem(
                    view: AnyView(AskForAccessToContactsView()))) }) {
                        Text("Help")
                    }.buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        self.navigation.advance(NavigationItem(
                    view: AnyView(PrivacyView()))) }) {
                        Text("Privacy Statement")
                    }.buttonStyle(PlainButtonStyle())
                    
                    
                }.navigationBarTitle(Text("Settings"))
            }
        }
    }
    
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(model: globalDataModel)
    }
}


