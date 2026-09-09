# AFTERLIFE INC.｜目前進度與後續開發

更新日期：2026-09-09  
分支：`main`  
專案：Godot 4.7／Windows Steam 目標

## 一句話現況

目前是**可操作的美術驅動宇宙增量遊戲原型**：玩家能翻開生成卡牌、引導靈魂穿過多段閘門掉落、重生後進行浮文校準、開啟星圖／收藏／靈魂背包／神祉／商店／每週挑戰；尚未達到可發行的 v1.0。

## 已完成與可操作內容

### 核心遊玩流程

- 初局：**翻牌 → 查看規則 → 靈魂掉落 → 閘門結算**。
- 初始命運牌從 3 張牌背中選 1，翻牌後才會顯示規則文字。
- 掉落為可見的多段彈板路徑，有衝擊點、三個落點閘門與結算資料。
- 結算會顯示業力、碎片、卡牌、閘門、精準度、倍率，以及新增靈魂。
- 重生後：翻牌確認後必須依序鎖定浮文；浮文所在左右位置會推動掉落方向。
- 浮文支援圓環、八字、星形三種軌道；卡牌會決定使用的軌道。
- 可使用命運印記將浮文數量從 3 枚永久解鎖到 8 枚。
- 解鎖宇宙星圖末節點後可按 `A` 開啟自動命運儀式；自動收益限制為手動計算的 58%，不取代手動高分。

### 視覺與生成素材

- 主彈盤、開場、結算、星圖、卡牌與神祉皆以生成插畫作為主要畫面。
- 初始 10 張卡牌皆已製作無文字專屬卡面。
- 特殊商店兩張永久卡也已有專屬卡面：`weaver`、`void_bloom`。
- 神祉主視覺：
  - `assets/art/characters/deity_astraea_v1.png`（已接入衣櫥）
  - `assets/art/characters/deity_selene_v1.png`（已生成，尚未接入）
  - `assets/art/characters/deity_orpheon_v1.png`（已生成，尚未接入）

### 成長、收藏與介面

| 快捷鍵 | 畫面 | 狀態 |
| --- | --- | --- |
| `T` | 宇宙星圖 | 36 節點、三分支、前置、成本、保存、效果皆已實作 |
| `C` | 命運牌收藏 | 已收藏卡顯示生成卡面；商店卡可買入 |
| `I` | 靈魂圖鑑／背包 | 靈魂掉落、圖鑑、容量、釋放換業力 |
| `G` | 阿斯特萊雅衣櫥 | 三個外觀槽、解鎖、裝備、短句預言 |
| `B` | 特殊商店 | 20 分鐘輪替、混合資源價格、永久遺物、一次性諭令 |
| `W` | 每週挑戰 | 本機週規則、最佳紀錄、榮譽、稱號 |
| `O` | 設定 | 教學重播、低閃爍偏好、UI 縮放值保存 |

### 平台準備

- 已建立 `SteamService` 抽象層，未安裝 GodotSteam 時會安全回報 unavailable。
- Steam 接入清單在 `docs/STEAMWORKS_INTEGRATION.md`。
- 沒有自建資料庫；每週與單局資料目前只保存本機紀錄。

## 尚未完成：依優先順序

### P0：讓 v1.0 核心循環真正完整

1. **掉落物理／可重放模擬**
   - 現況為可見的多段路徑，不是逐釘的物理彈珠。
   - 需要讓閘門、彈板、鎖定浮文與卡牌修改的路徑都能以可重放資料描述。

2. **完整流程自動測試**
   - 目前只有核心經濟測試。
   - 要新增完整場景模式測試：新存檔 → 選卡 → 翻牌確認 → 掉落 → 結算 → 重生 → 浮文 → 結算。

3. **命運牌擴充**
   - v1.0 最少 30 張；目前有 12 張資料與專屬卡面。
   - 每張新增卡必須包含：JSON 數據、取得方式、無文字生成卡面、`main_game.gd`／`fate_collection.gd` 映射、測試或驗證。

4. **靈魂視覺與稀有度**
   - 現有 6 種靈魂僅有資料，尚未每種都有生成光球／人形剪影資產。
   - 需在圖鑑顯示個別視覺與稀有度辨識，不只文字與顏色。

### P1：內容系統完成度

5. **神祉三原型**
   - Selene、Orpheon 已有主視覺，但衣櫥仍只支援阿斯特萊雅。
   - 要新增角色切換、每位神祉的外觀資料與至少一組可見變體。

6. **特殊商店與限定卡深化**
   - 現在輪替與購買已可用。
   - 要補商品專屬視覺、限定卡使用介面、購入後的可讀狀態與平衡。

7. **週挑戰與榮譽外觀**
   - 目前為本機週規則／紀錄。
   - 要補榮譽外觀獎勵與週挑戰更明確的特殊交互規則。

### P2：發行準備

8. **GodotSteam／Steamworks**
   - 目前尚未放入 GodotSteam 外掛或 Steam App ID。
   - 需要實作 Steam Cloud、兩個 Leaderboard（單局命運印記、週榜）與異常分數檢查。

9. **設定與可及性**
   - UI 縮放目前只保存數值，尚未影響實際畫面。
   - 尚缺音效、音量、完整按鍵重新綁定。

10. **平衡、存檔與發行 Build**
    - 經濟曲線、存檔版本遷移、錯誤處理、Steam build、發行前 QA。

## 重要檔案

- `docs/AFTERLIFE_INC_CONTENT_SPEC.md`：內容規格，新增內容必須符合它。
- `docs/DEVELOPMENT_PROGRESS.md`：逐項工程進度。
- `docs/CLOUD_HANDOFF.md`：雲端接續說明與驗證命令。
- `docs/STEAMWORKS_INTEGRATION.md`：Steamworks 必要作業。
- `src/core/game_engine.gd`：遊戲循環、資源、卡牌、浮文、收藏、商店與週挑戰的主邏輯。
- `src/ui/main/`：主要畫面和互動層。
- `src/config/`：資料驅動的卡牌、靈魂、星圖、神祉與商店資料。

## 驗證指令

在專案根目錄執行：

```powershell
$env:APPDATA="$PWD\.godot-user\Roaming"
$env:LOCALAPPDATA="$PWD\.godot-user\Local"
& 'C:\Users\diorl\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --headless --path . --editor --quit
& 'C:\Users\diorl\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/run_tests.gd
```

預期核心測試輸出：`All AFTERLIFE INC. core tests passed.`

## 雲端代理開發規則

1. 不要將生成主視覺替換成 Godot 預設灰色面板。
2. 卡牌正面禁止嵌入文字；文字只在玩家翻開或選取後出現。
3. 資源不可互換；只有特殊商品可以同時消耗多種資源。
4. Steam Leaderboard 不是通用資料庫。
5. 每個功能完成後都要更新 `docs/DEVELOPMENT_PROGRESS.md` 並重跑 headless 驗證。
