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

private final class BGTaskCompletionController {
    private let lock = NSLock()
    private var hasCompleted = false

    func complete(_ task: BGTask, success: Bool) {
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
        
//        AlarmService.shared.updateAlarmStatus(id: alarmService.currentAlarm!.id, isOn: true, isWakeup: false, isLeave: false)
        
        let userDefaults = UserDefaults.standard
               let lastScheduledDateKey = "lastScheduledDate"
               
               // UserDefaultsから最後にタスクをスケジュールした日付を取得
               let lastScheduledDate = userDefaults.object(forKey: lastScheduledDateKey) as? Date

               // 最後の実行日が今日ではないか、または一度も実行されていない場合のみ実行
               if lastScheduledDate == nil || !Calendar.current.isDateInToday(lastScheduledDate!) {
                   print("バックグラウンドタスクを本日分としてスケジュールします。")
//                   backgroundtask.scheduleDailyAlarmSetup()

                   // 今日の日付を保存して、同日中の再実行を防ぐ
                   userDefaults.set(Date(), forKey: lastScheduledDateKey)
                   print("実行日を保存しました: \(Date())")
               } else {
                   print("本日のバックグラウンドタスクは既にスケジュール済みです。")
                   return
               }
        
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
        let completionController = BGTaskCompletionController()
        var refreshWork: Task<Void, Never>?

        task.expirationHandler = {
            refreshWork?.cancel()
            completionController.complete(task, success: false)
        }

        print("㊗️ Background task started")

        refreshWork = Task { @MainActor [weak self] in
            guard let self else {
                completionController.complete(task, success: false)
                return
            }

            let success: Bool
            if let todayAlarm = AlarmService.shared.getTodayAlarm(), todayAlarm.isOn {
                success = await self.handledDepaturePost()
            } else {
                success = await self.handleSetAarlm()
            }

            completionController.complete(task, success: success && !Task.isCancelled)
        }
    }
       
       /// バックグラウンドで実行される実際の処理
    @MainActor func handleSetAarlm() async -> Bool {
        print("🌅 Background task started. Setting up today's alarm.")

        if Task.isCancelled {
            return false
        }

        if AlarmService.shared.getTodayAlarm() != nil {
            AlarmService.shared.startMonitoring()
        } else {
            print("💸 No Alarm")
        }

        if Task.isCancelled {
            return false
        }

        scheduleDepaturePostSetup()
        print("✅ Background task completed successfully.")
        return true
    }
    
    @MainActor func handledDepaturePost() async -> Bool {
        print("💟 Background task started. posting today post.")
        print("go task")
        print("alarm check")

        guard let todayAlarm = self.alarmService.getTodayAlarm() else {
            print("❌ Error: 実行すべきアラームが見つからず、処理を中断します。")
            return false
        }

        if Task.isCancelled {
            return false
        }

        let didPost = await postFailurePost(alarmdata: todayAlarm)

        if Task.isCancelled {
            return false
        }

        scheduleDailyAlarmSetup()
        print(didPost ? "✅ Background task completed successfully." : "❌ Background task completed with errors.")
        return didPost
    }
    
    
    //謝罪画像の投稿
    @MainActor private func postFailurePost(alarmdata:AlarmData) async -> Bool {
        
        let postService = PostService()
        
        print("start task")
        
        guard alarmdata.isOn else {
            return true
        }

        print("have alarm")

        do {
            if alarmdata.isWakeup && !alarmdata.isLeave {
                guard let wakeupImageData = UserDefaults.standard.data(forKey: "wakeupImage")
                    ?? UIImage(named: "wakeup")?.jpegData(compressionQuality: 0.5) else {
                    print("❌ 起床時写真が見つかりません。")
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
                UserDefaults.standard.removeObject(forKey: "wakeupImage")
                alarmService.updateAlarmStatus(id: alarmdata.id, isOn: false, isWakeup: true, isLeave: true)
                return true
            } else if !alarmdata.isWakeup && !alarmdata.isLeave {
                guard let hitozichiimagedata = UserDefaults.standard.object(forKey: "hitozichiImage") as? Data
                    ?? UIImage(named: "wakeup")?.jpegData(compressionQuality: 0.5) else {
                    print("❌ 謝罪画像が見つかりません。")
                    return false
                }

                try await postService.uploadPost(
                    imageData: hitozichiimagedata,
                    comment: "寝過ごしてしまいました、、",
                    status: .noActions,
                    completion: { _ in
                        print("can uploard")
                    }
                )
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
