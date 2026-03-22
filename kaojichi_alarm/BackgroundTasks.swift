//
//  BackgroundTasks.swift
//  picture_alarm_app
//
//  Created by tanaka niko on 2025/09/19.
//

import Foundation
import SwiftData
import BackgroundTasks
import SwiftUI

private final class BGTaskCompletionState {
    private let lock = NSLock()
    private var hasCompleted = false
    private let task: BGAppRefreshTask

    init(task: BGAppRefreshTask) {
        self.task = task
    }

    func finish(success: Bool) {
        lock.lock()
        defer { lock.unlock() }

        guard !hasCompleted else { return }
        hasCompleted = true
        task.setTaskCompleted(success: success)
    }
}

class BackgroundTasks {
    
    private let backgroundTaskID = "app.hakuu.mukimuki.picture-alarm-app.background.v2"
    
    private let alarmService = AlarmService.shared
    
    
    
    var isAlarmOn = UserDefaults.standard.value(forKey: "isAlarmOn") as? Bool ?? false
    
    
    /// バックグラウンドタスクのハンドラを登録する
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskID, using: nil) { task in
            // 実際に実行したい処理はここ（handleAppRefresh）に書く
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
       
       /// バックグラウンドタスクをOSにスケジュール（予約）する
    @MainActor func scheduleDailyAlarmSetup() {
           let request = BGAppRefreshTaskRequest(identifier: backgroundTaskID)
           
           if let todayalarm =  AlarmService.shared.getTodayAlarm() {
               if todayalarm.isOn == true {
                   scheduleDepaturePostSetup()
                   
                   return
               }
           }
        
     
           // --- ここから修正 ---
           let calendar = Calendar.current
           let now = Date()

           // 基準日を「昨日」ではなく「今日」にする
           guard var targetDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) else {
               print("目標時刻の生成に失敗しました。")
               return
           }


           if now > targetDate {
               targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
           }


              // OSに「この時刻以降のできるだけ早いタイミングで実行してください」と伝える
              request.earliestBeginDate = targetDate

              print("次のバックグラウンドタスクは \(targetDate) 以降にスケジュールされました。")
              
              // --- ここまで修正 ---

              do {
                  BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskID)
                  try BGTaskScheduler.shared.submit(request)
                  print("Successfully scheduled background task.")
              } catch {
                  print("Could not schedule background task: \(error)")
              }
           
           
       }
    
    //出発時刻にタスクが実行されるようにする
    @MainActor func scheduleDepaturePostSetup() {
        let now = Date()
        print(now)
        
        guard let todayalarm =  AlarmService.shared.getTodayAlarm() else {
            scheduleDailyAlarmSetup()
            return
        }
        
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskID)

        // --- ここから修正 ---
        let calendar = Calendar.current
//               let now = Date()

               // アラームの起床時刻から「時」と「分」を抽出
        let targetHour = calendar.component(.hour, from: todayalarm.leaveTime)
            let targetMinute = calendar.component(.minute, from: todayalarm.leaveTime)

               // 今日の日付で目標時刻を生成
               guard var targetDate = calendar.date(bySettingHour: targetHour, minute: targetMinute, second: 0, of: now) else {
                   print("目標時刻の生成に失敗しました。")
                   return
               }
//        targetDate = calendar.date(byAdding: .hour, value: 9, to: targetDate)!

               // ⭐️ もし現在の時刻が「今日の目標時刻」を過ぎていたら、目標日を1日進める
               if now > targetDate {
                   targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
               }

           // OSに「この時刻以降のできるだけ早いタイミングで実行してください」と伝える
           request.earliestBeginDate = targetDate

           print("次のバックグラウンドタスクは \(targetDate) 以降にスケジュールされました。")
           
           // --- ここまで修正 ---

           do {
               BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskID)
                try BGTaskScheduler.shared.submit(request)
               print("Successfully scheduled background task.")
           } catch {
               print("Could not schedule background task: \(error)")
           }
        
        
    }
    
    @MainActor func handleAppRefresh(task:  BGAppRefreshTask) {
        let completionState = BGTaskCompletionState(task: task)

        task.expirationHandler = {
            completionState.finish(success: false)
        }

        print("㊗️ Background task started")

        Task { @MainActor in
            let success: Bool

            if let todayAlarm = AlarmService.shared.getTodayAlarm(), todayAlarm.isOn {
                success = await handledDepaturePost()
            } else {
                success = await handleSetAarlm()
            }

            completionState.finish(success: success)
        }
    }
       
       /// バックグラウンドで実行される実際の処理
    @MainActor func handleSetAarlm() async -> Bool {
        print("🌅 Background task started. Setting up today's alarm.")

        if AlarmService.shared.getTodayAlarm() != nil {
            AlarmService.shared.startMonitoring()
        } else {
            print("💸 No Alarm")
        }

        scheduleDepaturePostSetup()
        print("✅ Background task completed successfully.")
        return true
    }
    
    @MainActor func handledDepaturePost() async -> Bool {
        print("💟 Background task started. posting today post.")

        print("alarm check")
        guard let todayAlarm = self.alarmService.getTodayAlarm() else {
            print("❌ Error: 実行すべきアラームが見つからず、処理を中断します。")
            return false
        }

        let success = await postFailurePost(alarmdata: todayAlarm)
        print("✅ Background task completed successfully.")

        scheduleDailyAlarmSetup()
        return success
    }
    
    
    //謝罪画像の投稿
    @MainActor private func postFailurePost(alarmdata: AlarmData) async -> Bool {
        let postService = PostService()
        let wakeupStatusPostIdKey = "wakeupStatusPostId_\(alarmdata.id)"
        
        print("start task")
        
        guard alarmdata.isOn else { return true }

        do {
            print("have alarm")

            if alarmdata.isWakeup && !alarmdata.isLeave {
                guard let wakeupImageData = UserDefaults.standard.data(forKey: "wakeupImage")
                    ?? UIImage(named: "wakeup")?.jpegData(compressionQuality: 0.5) else {
                    return false
                }

                try await postService.uploadPost(
                    imageData: wakeupImageData,
                    comment: "準備が終わりませんでした、、、",
                    status: .isWakeup,
                    completion: { _ in
                        print("can uploard")
                    }
                )
                
                if let wakeupStatusPostId = UserDefaults.standard.string(forKey: wakeupStatusPostIdKey) {
                    try? await postService.deletePost(postId: wakeupStatusPostId)
                    UserDefaults.standard.removeObject(forKey: wakeupStatusPostIdKey)
                }

                UserDefaults.standard.removeObject(forKey: "wakeupImage")
                UserDefaults.standard.removeObject(forKey: "wakeupImageData")
                alarmService.updateAlarmStatus(id: alarmdata.id, isOn: false, isWakeup: true, isLeave: true)
                return true
            } else if !alarmdata.isWakeup && !alarmdata.isLeave {
                guard let hitozichiImageData = UserDefaults.standard.data(forKey: "hitozichiImage")
                    ?? UIImage(named: "wakeup")?.jpegData(compressionQuality: 0.5) else {
                    return false
                }

                try await postService.uploadPost(
                    imageData: hitozichiImageData,
                    comment: "寝過ごしてしまいました、、",
                    status: .noActions,
                    completion: { _ in
                        print("can uploard")
                    }
                )

                UserDefaults.standard.removeObject(forKey: "wakeupImage")
                UserDefaults.standard.removeObject(forKey: "wakeupImageData")
                UserDefaults.standard.removeObject(forKey: wakeupStatusPostIdKey)
                alarmService.updateAlarmStatus(id: alarmdata.id, isOn: false, isWakeup: true, isLeave: true)
                return true
            }

            return true
        } catch {
            print("❌ バックグラウンドでの投稿に失敗しました: \(error.localizedDescription)")
            return false
        }
    }
}
