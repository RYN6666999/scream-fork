---
name: template-batch
description: 精準模板批次工作流。從參考模板（SVG/PNG）中程式化分析字體、字級、絕對座標、去背等規格，鎖定後用同一引擎批量產出個人化文件（名牌、海報、識別證等）
version: 1.0.0
---

# 精準模板批次工作流 (Template Batch)

## ⚡ 進場檢查（Immediate Action）

1. 檢查工作目錄是否存在且符合結構（`模板原始檔/`、`參考輸出/` 等）
2. 如果沒有參考輸出 PNG → 問使用者要參考圖
3. 如果沒有模板原始檔 → 問使用者要模板
4. 檢查 Python 依賴：`python3 -c "from PIL import Image; import numpy as np"`

## 📖 前置記憶召回（Pre-task Memory Recall）

```python
MemoryLookup(query="template batch SVG PNG deback position font", limit=3)
```

## ⚠️ Anti-hallucination：常見錯誤

| ❌ 你可能會做 | ✅ 正確做法 |
|-------------|-----------|
| 用肉眼猜字體、座標 | 一律用 Python PIL + NumPy 做像素級分析 |
| 樣張用 HTML/CSS，批量用 PIL | 樣張與批量必須用同一渲染引擎 |
| 核准後偷換引擎 | 鎖定引擎後不可更換 |
| 跳過去背分析直接做 | 去背分析是強制關卡，不可跳過 |

## 核心原則

> **先鎖規格，再出樣張，再量產。**
> **樣張與批量必須用同一渲染引擎。**
> **座標必須程式化比對，不能用視覺猜。**

## 流程

### Phase 0：建立素材資料夾

建立工作目錄，分類存放：

```
工作目錄/
├── 模板原始檔/     # 使用者給的設計檔（SVG/PNG/PSD）
├── 參考輸出/       # 使用者給的「正確版」輸出（PNG）
├── 解析結果/       # 程式分析產出的規格表
├── 模板_可變區/    # 去背後的底版（無文字/無Logo版本）
├── 產出/           # 批量產出的最終檔案
```

### Phase 1：程式化規格萃取

禁止用視覺猜。一律用 Python PIL/NumPy 做像素級分析：

#### 1.1 字體分析
```python
# 從參考 PNG 中截取文字區塊
# 用 OCR 或像素特徵比對判斷字體家族
# 驗證：對照系統字體清單交叉比對
```

#### 1.2 去背分析（強制執行，不可跳過）

使用者的肉眼看到的就是「去好背的」。程式必須自動做到相同結果。

```python
# 掃描所有內嵌圖片的 mode 與 alpha channel
for each_embedded_image in SVG:
    img = Image.open(image_data)
    if 'A' not in img.mode:
        # 無透明通道 → 必須去背

        if img.mode == 'L':
            # 灰階圖：白底(>220) → 透明，其餘不透明
            arr = np.array(img)  # shape (H, W)
            rgba = np.zeros((H, W, 4), dtype=np.uint8)
            rgba[:,:,0] = arr  # R = 灰階值
            rgba[:,:,1] = arr  # G = 灰階值
            rgba[:,:,2] = arr  # B = 灰階值
            rgba[:,:,3] = np.where(arr > 220, 0, 255)  # Alpha

        elif img.mode == 'RGB':
            # 彩色圖：純白(>240 all channels) → 透明
            arr = np.array(img)
            white_mask = np.all(arr > 240, axis=2)
            rgba = np.zeros((H, W, 4), dtype=np.uint8)
            rgba[:,:,:3] = arr
            rgba[:,:,3] = np.where(white_mask, 0, 255)

        # 驗證：透明比例 vs 不透明比例
        transparent_pct = np.sum(alpha < 50) / total * 100
        assert transparent_pct > 0, "去背後必須有透明像素"
```

**去背診斷報告（每張圖片都要輸出）：**

| 屬性 | 值 |
|:----|:----|
| 圖層編號 | 1 |
| 原始 mode | L / RGB / RGBA |
| 有無 alpha | ✅ / ❌ |
| 白底比例 | XX% |
| 去背後透明比 | XX% |
| 去背後不透明比 | XX% |

#### 1.3 字級與座標分析
```python
# 逐行掃描找出文字區塊的 y 範圍、x 跨度
# 計算：文字區塊高度 → 對應 font-size
# 記錄：絕對 y 位置（距頂部 %）、中心 x
# 記錄：文字顏色（RGB 取樣）
```

輸出規格表（JSON）：

```json
{
  "engine": "cairosvg | playwright | pillow",
  "fonts": {
    "name": {"family": "Noto Serif TC", "size_px": 360, "color": "#1a1a1a"},
    "role":  {"family": "Noto Serif TC", "size_px": 90,  "color": "#F05050"},
    "region": {"family": "Noto Serif TC", "size_px": 80,  "color": "#555555"}
  },
  "positions": {
    "name":   {"x_pct": 50.0, "y_pct": 71.2},
    "role":   {"x_pct": 50.0, "y_pct": 79.8},
    "region": {"x_pct": 50.0, "y_pct": 83.5}
  },
  "zones": {
    "fixed":  {"brand_logo": "不可碰", "border": "不可碰"},
    "variable": ["name", "role", "region"]
  },
  "safe_margins": {"between_fields_px": 40, "from_brand_px": 100}
}
```

### Phase 2：建立模板

1. **固定區（不可動）**：品牌 Logo、裝飾線、邊框 → 鎖死
2. **可變區（僅文字）**：姓名、職級、區域 → 設佔位符 `{{name}}`
3. **安全距離規範**：每個區塊間最小 N px

### Phase 3：樣張驗證

1. 用**唯一引擎**渲染 1 張樣張
2. **程式化比對**：樣張 vs 參考 PNG
   - 文字 y 偏差 < 3%
   - 字級偏差 < 5%
   - 顏色容差 < 10 RGB
   - Logo 去背檢查
3. 讓使用者確認

### Phase 4：極端樣本測試

先產 6 張極端案例：
- 最短姓名（2 字）
- 最長姓名（4+ 字）
- 最短職稱
- 最長職稱
- 一般案例
- 特殊符號案例

每張跑自動檢查。

### Phase 5：正式量產

- 同一模板、同一引擎、不換技術棧
- 逐張輸出（SVG + PNG）
- 輸出後自動 QA

### Phase 6：自動 QA

每張輸出都驗證：

```python
checks = [
  ("字體", "是否使用指定字體族"),
  ("框內", "職稱是否完全在安全區內"),
  ("品牌避讓", "文字是否與品牌區重疊"),
  ("中心線", "各文字區共享同一中心線 ±2%"),
  ("安全距離", "區塊間距 ≥ 最小門檻"),
  ("去背", "Logo 無白底/無 alpha 問題")
]
```

加一層人工 QA：6 張極端樣本過了才允許整批輸出。

## 技術棧規格

| 用途 | 工具 | 原因 |
|:----|:----|:----|
| 像素分析 | Python PIL + NumPy | 精準、可重複 |
| 模板渲染 | **只能選一個** | 樣張=批量 必須一致 |
| 向量輸出 | cairosvg / svgwrite | 印刷級 |
| 點陣輸出 | Playwright / cairosvg | PNG/PDF |
| 座標系 | 絕對 %（距頂部/左緣） | 不受 DPI 變換影響 |

## 禁止事項

- ❌ 樣張用 HTML，批量換 PIL
- ❌ 未經像素分析就猜字體
- ❌ 未經像素分析就調座標
- ❌ 核准後換引擎
- ❌ 核准後改字體
- ❌ 核准後改模板結構
- ❌ 用不同程式「模仿」核准樣張

## ✅ 完成回饋（Post-task Memory Store）

```python
MemoryWrite(
    userNeed="批次模板處理：<專案名稱>",
    approach="Phase 0-6 完整流程 / 快速通道（僅產樣張）",
    outcome="完成 / 部分完成",
    whatFailed="<去背/座標/字體渲染等問題>",
    whatWorked="<有效的方法或工具>",
    tags=["template-batch", "<渲染引擎>", "<任務類型>"]
)
```

## 🔄 Skill Interface

### 輸出（寫入腦庫的 key）
- `skill/template-batch/last-run` → 最後批次執行的產出摘要
- `skill/template-batch/spec/{task_id}` → 單次任務的規格表 JSON

### 輸入（從腦庫讀取的 key）
- `skill/agentos/status` → AgentOS 是否在線（agentos skill 寫入）
- `project/current/status` → 當前專案狀態摘要