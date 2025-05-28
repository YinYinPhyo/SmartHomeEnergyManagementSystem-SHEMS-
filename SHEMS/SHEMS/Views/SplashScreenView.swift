//
//  Views.swift
//  SHEMS
//
//  Created by QSCare on 2/23/25.
//

import SwiftUI

struct SplashScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ZStack {
            AppColors.appBGColor
                .edgesIgnoringSafeArea(.all)

            
            VStack {
                // App logo
                Image("AppLogo") // Replace "logo" with the actual name of your logo asset
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // Adjust the size of the logo
                
                // App name text
                Text("Smart Home Energy Management System\n(SHEMS)")
                    .font(.custom("Montaga-Regular", size: 20))
                    .font(AppFontStyle.secondaryFont)
                 
                    .multilineTextAlignment(.center)
                   
                    .foregroundColor(AppColors.primaryColor) // Adjust the text color as needed
            }
        }
    }
}

//struct SplashScreenView_Previews: PreviewProvider {
//    static var previews: some View {
//        SplashScreenView()
//    }
//}
