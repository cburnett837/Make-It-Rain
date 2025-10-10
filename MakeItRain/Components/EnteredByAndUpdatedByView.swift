//
//  EnteredByAndUpdatedByView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/1/25.
//

import SwiftUI

struct EnteredByAndUpdatedByView: View {
    var enteredBy: CBUser
    var updatedBy: CBUser
    var enteredDate: Date
    var updatedDate: Date
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(.gray)
                .frame(width: 26)
                        
            VStack(alignment: .leading) {
                Text("Created")
                Text("Updated")
            }
            //.frame(maxWidth: .infinity)
            .font(.caption)
            .foregroundColor(.gray)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text(enteredDate.string(to: .monthDayYearHrMinAmPm))
                Text(updatedDate.string(to: .monthDayYearHrMinAmPm))
            }
            //.frame(maxWidth: .infinity)
            .font(.caption)
            .foregroundColor(.gray)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text(enteredBy.name.isEmpty ? "N/A" : enteredBy.name)
                Text(updatedBy.name.isEmpty ? "N/A" : updatedBy.name)
            }
            //.frame(maxWidth: .infinity)
            .font(.caption)
            .foregroundColor(.gray)
            
            //Spacer()
        }
        .frame(maxWidth: .infinity)
        #if os(macOS)
        .padding(.bottom, 12)        
        #endif
    }
}
