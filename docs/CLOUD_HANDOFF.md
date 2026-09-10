# AFTERLIFE INC. 雲端接手說明

最後整理：2026-09-10

## 目前已可玩的內容

- 開場引導：翻牌 → 規則揭示 → 多段靈魂掉落 → 閘門結算。
- 重生後命運校準：圓環／八字／星形浮文，3 至 8 枚永久解鎖，鎖定位置影響路徑。
- 自動命運儀式：需星圖最末宇宙節點，收益刻意限制為手動計算的 58%。
- 30 張命運牌資料與生成卡面映射；前 10 張為初始卡池，其餘可於收藏畫面以業力取得；收藏依成本呈現常見／罕見／史詩／傳說。
- 卡牌收藏（`C`）、六種靈魂視覺圖鑑與背包（`I`）、36 節點星圖（`T`）。
- 神祉：三位神祉皆可在衣櫥選擇（`G`），各有三個外觀槽與預言；Astraea 的金誓／虛空日蝕裝備已有生成視覺變體，Selene 與 Orpheon 待補。
- 特殊商店（`B`）：20 分鐘輪替、混合資源價格、永久遺物與一次性諭令；僅能買當輪展示品，諭令每輪限購一份並在下一局消耗。
- 每週規則與本機榮譽紀錄（`W`）。
- 設定（`O`）：教學重播、低閃爍偏好、立即套用並保存的 UI 縮放。

## 已驗證

```powershell
Godot_v4.7.2-stable_win64.exe --headless --path . --editor --quit
Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/run_tests.gd
Godot_v4.7.2-stable_win64.exe --headless --path . --scene res://tests/integration_test.tscn
```

核心經濟與整局流程測試通過；後者以完整 Autoload 驗證首局翻牌直落、重生節印、彈珠回放和限定商店售罄，也驗證連續三輪「翻牌 → 規則確認 → 掉落 → 結算 → 下一輪」可完整執行。Windows 根憑證存取訊息是本機 Godot 環境警告，非遊戲腳本錯誤。

## 雲端接續優先順序

1. 補 Selene、Orpheon 的神祉專屬外觀視覺變體。
2. 補音效與完整鍵盤重新綁定。
3. 平衡測試、存檔遷移與錯誤追蹤。
4. 安裝 GodotSteam 後，依 `STEAMWORKS_INTEGRATION.md` 實作 Steam Cloud 與 Leaderboard；目前 `SteamService` 僅是安全抽象層。
5. 建立 Steam 發行 Build。

## 重要規範

- 主畫面、卡面、星圖、角色、結算皆優先使用生成視覺；Godot 僅作透明互動與必要文字。
- 卡面不可嵌入文字，效果在翻開後顯示。
- 資源不可互相兌換；特殊商店可同時消耗多項資源。
- 不要以 Steam Leaderboard 當作通用資料庫。
