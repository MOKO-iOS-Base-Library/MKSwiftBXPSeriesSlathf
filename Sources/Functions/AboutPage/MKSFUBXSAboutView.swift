//
//  MKSFUBXSAboutView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/11/4.
//

import SwiftUI

import MKBaseSwiftModule

import MKSwiftCustomUI

import MKSwiftUILibrary

struct MKSFUBXSAboutView: View {
    var body: some View {
        VStack() {
            Image(uiImage: moduleIcon(name: "bxs_swf_about_logo",in: .module) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 110,height: 110)
                .padding(.top,40)
            Text("MK Sensor")
                .foregroundStyle(Color(MKColor.defaultText))
                .multilineTextAlignment(.center)
                .font(Font(MKFont.font(20)))
                .padding(.top,17)
            Text("Version: V\(MKApp.version)")
                .foregroundStyle(Color(MKColor.rgb(189, 189, 189)))
                .multilineTextAlignment(.center)
                .font(Font(MKFont.font(16)))
                .padding(.top,17)
            
            Spacer()
            ZStack {
                Image(uiImage: moduleIcon(name: "bxs_swf_aboutBottomIcon",in: .module) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.bottom,0)
                VStack {
                    Text("MOKO TECHNOLOGY LTD.")
                        .foregroundStyle(Color(MKColor.defaultText))
                        .multilineTextAlignment(.center)
                        .font(Font(MKFont.font(16)))
                        .padding(.bottom,17)
                    MKSFUBXSWebBtn()
                        .padding(.bottom,60)
                }
            }
        }
        .withNavBar(title: "About")
    }
}

struct MKSFUBXSBottomView: View {
    var body: some View {
        VStack {
            Image(uiImage: moduleIcon(name: "bxs_swf_aboutBottomIcon",in: .module) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct MKSFUBXSWebBtn: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("www.mokoblue.com")
                .foregroundColor(Color(MKColor.navBar))
                .multilineTextAlignment(.center)
                .font(Font(MKFont.font(16.0)))
                .onTapGesture {
                    openWebBrowser()
                }
            Rectangle()
                .fill(Color(MKColor.rgb(3, 191, 234)))
                .frame(width: 155, height: 0.5)
        }
    }
    
    private func openWebBrowser() {
        
    }
}

#Preview {
    NavigationView {
        MKSFUBXSAboutView()
    }
}
