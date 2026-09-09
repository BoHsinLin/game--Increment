# Steamworks 接入清單

目前專案沒有 GodotSteam／Steamworks SDK 二進位外掛，因此遊戲不會宣稱 Steam Cloud 或排行榜已啟用。

## 已完成的遊戲端準備

- `SteamService` 是唯一 Steam 服務入口，未安裝外掛時會安全回報 unavailable。
- 存檔維持 `SaveManager` 的本機流程；不會以自建資料庫偽造雲端同步。
- 每週規則與單局最佳紀錄已在遊戲內保存，可作為未來 Steam Leaderboard 上傳值。

## 發行前必要作業

1. 安裝與目前 Godot 版本相容的 GodotSteam 擴充套件。
2. 在 Steamworks 後台建立 App、Cloud 檔案規則及兩個榜單：單局命運印記、週規則最佳成績。
3. 將實際 App ID 以 build pipeline 或 `steam_appid.txt` 注入測試／發行版本；不得硬編碼正式 ID。
4. 依安裝的 GodotSteam API 實作 `SteamService.initialize`、Cloud 同步與 leaderboard upload/download。
5. 以 Steamworks 測試環境驗證離線、登入切換、雲端衝突、週期重置、無效分數與防作弊策略。

## 公平性

排行榜僅上傳結算後的單局／週挑戰值；榮譽與外觀不改變週榜算分。伺服端規則與分數異常檢查需由 Steamworks 發行流程補足。
