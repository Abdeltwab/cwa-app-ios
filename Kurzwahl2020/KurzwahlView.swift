//
//  KurzwahlView.swift
//  Kurzwahl2020
//
//  Created by Vogel, Andreas on 30.10.19.
//  Copyright © 2019 Vogel, Andreas. All rights reserved.
//

import SwiftUI
import QGrid

//let hsize: CGFloat = 150
//let vsize: CGFloat = 80
let bordersize: CGFloat = 1
let fontsize: CGFloat = 26

let hsize: CGFloat = ( UIScreen.main.bounds.width / 2 ) - 2

// iPhone11
let screenheight: CGFloat = (UIScreen.main.bounds.height - 95 ) - 5 * 2
// iPhone SE: no Spacer()
//let screenheight: CGFloat = (UIScreen.main.bounds.height - 21 ) - 5 * 2
var vsize = screenheight / 6

struct KurzwahlView: View {
    var body: some View {
        GeometryReader { geometry in
        VStack () {
            Spacer()
            QGrid(Storage.people,
                  columns: 2,
                  vSpacing: 2,
                  hSpacing: 2,
                  vPadding: 0,
                  hPadding: 0 )
            //{ GridCell(person: $0, height: vsize, width: hsize) }
            { GridCell(person: $0, height: geometry.size.height / 6 - 4, width: hsize) }
            Spacer()
        }
        //.padding([.top], 50)
        //.edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct KurzwahlView_Previews: PreviewProvider {
    static var previews: some View {
        KurzwahlView()
    }
}


struct GridCell: View {
    var person: Person
    var height: CGFloat
    var width: CGFloat
    
    var body: some View {
        VStack {
            Text(person.firstName + " " + person.lastName)
                .font(.system(size: fontsize))
                .frame(width: width, height: height, alignment: .center)
                //.border(Color.gray, width: bordersize)
                .background(Color.blue)
            }.cornerRadius(5)
    }
}
