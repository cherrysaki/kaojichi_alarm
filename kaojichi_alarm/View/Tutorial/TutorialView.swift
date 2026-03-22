//
//  TutorialView.swift
//  kaojichi_alarm
//
//  Created by 酒井みな実 on 2026/03/15.
//

import SwiftUI

struct TutorialPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String?
}

struct TutorialView: View {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var currentPage = 0

    let pages: [TutorialPage] = [
        TutorialPage(
            title: "顔質アラーム！ へようこそ",
            description: "寝起き顔を撮って止める、\n遅刻防止アラームアプリです。",
            imageName: nil
        ),
        TutorialPage(
            title: "起床時刻と出発時刻を設定",
            description: "就寝前に、翌日の\n起床時刻と出発時刻を設定します。",
            imageName: "tutorial_setting"
        ),
        TutorialPage(
            title: "朝、寝起き顔を撮影",
            description: "起床したら、寝起きの姿で写真を撮ります。\n顔が画面内に写っていないと撮影できません。",
            imageName: "tutorial_wakeup"
        ),
        TutorialPage(
            title: "出発時にもう一度撮影",
            description: "家を出るときに、もう一度写真を撮って投稿します。\n出発時刻までに投稿できないと…",
            imageName: "tutorial_departure"
        ),
        TutorialPage(
            title: "寝起き姿が投稿されます",
            description: "出発時刻までに投稿できなかった場合、\n寝起きの写真が自動で投稿されます。",
            imageName: nil
        ),
        TutorialPage(
            title: "準備を始めましょう",
            description: "",
            imageName: nil
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 24) {
                        Spacer(minLength: 20)

                        if index == 0 {
                            firstPageView
                        } else if index == 4 {
                            penaltyPageView
                        } else if index == 5 {
                            finalPageView
                        } else {
                            defaultPageView(page: page)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            bottomButton
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            if currentPage > 0 {
                Button(action: {
                    currentPage -= 1
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .foregroundColor(.white)
                }
            } else {
                Color.clear
                    .frame(width: 60, height: 20)
            }

            Spacer()

            Button("スキップ") {
                hasSeenTutorial = true
            }
            .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var bottomButton: some View {
        Button(action: {
            if currentPage < pages.count - 1 {
                currentPage += 1
            } else {
                hasSeenTutorial = true
            }
        }) {
            Text(currentPage == pages.count - 1 ? "はじめる" : "次へ")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.themeOrange)
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }

    private var firstPageView: some View {
        VStack(spacing: 28) {
            Image("appicon")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)

            Text("顔質アラーム！ へようこそ")
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            Text("寝起き顔を撮って止める、\n遅刻防止アラームアプリです。")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
        }
    }

    private func defaultPageView(page: TutorialPage) -> some View {
        VStack(spacing: 24) {
            if let imageName = page.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(radius: 8)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                Text(page.description)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
            }
            .padding(.horizontal, 8)
        }
    }

    private var penaltyPageView: some View {
        VStack(spacing: 28) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
            
            Text("寝起きで撮影した写真が\n投稿されます")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themeOrange)

            Text("出発時刻までに投稿できなかった場合、\n寝起きの写真が自動で投稿されます。")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .lineSpacing(6)
        }
    }

    private var finalPageView: some View {
        VStack(spacing: 35) {
            Image(systemName: "clock.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
            
            Text("寝起き顔を守るために\n時間通りに出発しましょう！")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themeOrange)

//            Text("このあと、カメラと通知の設定を行います。")
//                .font(.system(size: 18))
//                .multilineTextAlignment(.center)
//                .foregroundColor(.white.opacity(0.9))
//                .lineSpacing(6)
        }
    }
}

#Preview {
    TutorialView()
}

