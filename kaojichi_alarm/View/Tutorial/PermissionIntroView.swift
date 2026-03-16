//
//  PermissionIntroView.swift
//  kaojichi_alarm
//
//  Created by 酒井みな実 on 2026/03/16.
//

import SwiftUI
import AVFoundation
import UserNotifications

struct PermissionIntroView: View {
    @AppStorage("hasCompletedPermissionFlow") private var hasCompletedPermissionFlow = false
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "camera.badge.ellipsis")
                    .font(.system(size: 56))
                    .foregroundColor(.orange)

                Text("使い始める前に")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)

                Text("このアプリでは\nカメラと通知を使用します")
                    .font(.system(size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
            }

            VStack(alignment: .leading, spacing: 16) {
                Label("寝起き顔と出発時の写真を撮るために、カメラを使用します", systemImage: "camera.fill")
                Label("アラームや出発時刻のお知らせのために、通知を使用します", systemImage: "bell.fill")
            }
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 28)

            Button(action: {
                requestPermissions()
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("許可してはじめる")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal, 24)
            }
            .disabled(isRequesting)

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func requestPermissions() {
        isRequesting = true

        AVCaptureDevice.requestAccess(for: .video) { _ in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                DispatchQueue.main.async {
                    hasCompletedPermissionFlow = true
                    isRequesting = false
                }
            }
        }
    }
}

#Preview {
    PermissionIntroView()
}
