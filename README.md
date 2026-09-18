# 💧 EasyFind - Public Restroom & Water Refill Station Finder / 全台飲水機與公廁尋找神器 🚽

<div align="center">

![EasyFind Banner](docs/assets/demo.gif)

[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange.svg?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/swiftui/)
[![iOS Platform](https://img.shields.io/badge/iOS-17.0%2B-blue.svg?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
[![Xcode](https://img.shields.io/badge/Xcode-15.0%2B-1575F9.svg?style=for-the-badge&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg?style=for-the-badge)](https://developer.apple.com/)

**[English](#-english) | [繁體中文](#-繁體中文)**

---

</div>

<a name="english"></a>
## 🌐 English

### 🌟 About EasyFind
**EasyFind** is an intuitive, modern iOS application designed to help users quickly locate public drinking water dispensers and restrooms across Taiwan. Built entirely with **SwiftUI** and MapKit, it integrates real government open datasets, live audio feedback, custom typography, advanced attribute filtering, user favorites, and real-time issue reporting.

---

### ✨ Key Features

- 📍 **Interactive Map & Real-time Location**: Browse nationwide water stations and restrooms with instant distance calculations from your current location.
- 🔍 **Smart Autocomplete Search**: Interactive search bar with instant drop-down suggestions showing exact addresses and distance.
- 🎛️ **Multi-Categorized Advanced Filters**: Filter facilities by location (County/District), water properties (Cold/Warm/Hot), restroom features (Accessible/Parent-Child/Gender-Friendly), and operating hours (24/7).
- ❤️ **My Favorites with Persistence**: Bookmark frequently used locations stored locally with instant filtering and search capability.
- 🔊 **Audio Interaction System**: Audio feedback played when tapping map pins and automatically stopped upon sheet dismissal or navigation.
- 📢 **Facility Issue Reporting Hub**: Segmented report interface allowing users to submit maintenance issues directly to local storage and view live community status boards.
- 🎨 **Custom Typography Integration**: Custom embedded font support (**openhuninn 2.1**) for a friendly visual aesthetic.

---

### 📱 Screenshots & Demo

<div align="center">

| 🗺️ Map & Detail Card | ⚙️ Advanced Filters | ❤️ Favorites List | 📢 Facility Issue Report |
| :---: | :---: | :---: | :---: |
| <img src="docs/assets/map_view.png" width="200" alt="Map View"> | <img src="docs/assets/filter_view.png" width="200" alt="Filter View"> | <img src="docs/assets/favorites_view.png" width="200" alt="Favorites View"> | <img src="docs/assets/report_view.png" width="200" alt="Report View"> |

</div>

---

### 🚀 Technical Stack

| Component | Technology / Framework |
| :--- | :--- |
| **Framework** | SwiftUI (iOS 17+) |
| **Mapping Engine** | MapKit (`Map`, `MapCameraPosition`, `Annotation`) |
| **Location Services** | CoreLocation (`CLLocationManagerDelegate`) |
| **Audio Engine** | AVFoundation (`AVAudioPlayer`) |
| **Typography** | CoreText (`CTFontManagerRegisterFontsForURL`) |
| **Data Storage** | UserDefaults (Favorites Persistence) |
| **Architecture** | MVVM Pattern (`ObservableObject`, `@Published`) |

---

### 🛠️ Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/EasyFind.git
   cd EasyFind
   ```

2. **Open project in Xcode**:
   ```bash
   open "Untitled Project.xcodeproj"
   ```

3. **Build & Run**:
   - Select your target simulator (e.g. iPhone 15 Pro) or a physical device running iOS 17+.
   - Press `Cmd + R` to build and launch the app.

---

<hr style="height:2px;border-width:0;color:gray;background-color:gray">

<a name="繁體中文"></a>
## 🇹🇼 繁體中文

### 🌟 關於 EasyFind
**EasyFind** 是一款專為台灣在地使用者設計的公共設施尋找 App，協助使用者第一時間找到身邊最近的**飲水機**與**優質公廁**。全專案採用 **SwiftUI** 與 MapKit 打造，結合政府開放資料、語音效果、客製粉圓體字型、精準進階篩選、個人收藏與即時故障回報功能。

---

### ✨ 核心功能特色

- 📍 **地圖即時定位與距離計算**：快速在地圖上瀏覽全台飲水點與廁所，即時顯示距目前位置之公里/公尺數。
- 🔍 **關鍵字即時下拉關聯選單**：搜尋列輸入關鍵字即時浮現前數筆設施建議，顯示類型圖示、地址與距離。
- 🎛️ **三分區進階條件篩選**：分為「行政區位置」、「飲水機條件（冰/溫/熱水）」與「廁所條件（無障礙/親子/性別友善）」，精準過濾需求。
- ❤️ **我的收藏與持久化保存**：支援一鍵愛心收藏，資料持久化儲存於本地，並提供專屬分頁分類與關鍵字搜尋。
- 🔊 **互動音效播放控制**：點擊地圖設施地標即時播放專屬對應音效，關閉詳情或切換分頁時自動停止播放。
- 📢 **設施故障回報專區**：整合「回報系統」、「最近回報」與「即時回報消息」三大標籤頁，支援從地圖詳情直接代入設施資訊通報。
- 🎨 **粉圓體 2.1 (openhuninn) 全局字型**：動態載入客製化字型，打造極致溫馨流暢的視覺體驗。

---

### 📱 畫面截圖與動態展示

<div align="center">

| 🗺️ 主地圖與設施詳情 | ⚙️ 三分區進階篩選 | ❤️ 我的收藏專區 | 📢 設施回報與即時消息 |
| :---: | :---: | :---: | :---: |
| <img src="docs/assets/map_view.png" width="200" alt="地圖畫面"> | <img src="docs/assets/filter_view.png" width="200" alt="篩選畫面"> | <img src="docs/assets/favorites_view.png" width="200" alt="收藏畫面"> | <img src="docs/assets/report_view.png" width="200" alt="回報畫面"> |

</div>

---

### 🚀 技術架構

| 模組區塊 | 採用的技術與 API |
| :--- | :--- |
| **UI 框架** | SwiftUI (iOS 17+) |
| **地圖元件** | MapKit (`Map`, `Annotation`, `MapCameraPosition`) |
| **定位服務** | CoreLocation (`CLLocationManager`) |
| **音效模組** | AVFoundation (`AVAudioPlayer`) |
| **字型註冊** | CoreText (`CTFontManagerRegisterFontsForURL`) |
| **資料持久化** | UserDefaults (收藏清單與回報紀錄) |
| **設計模式** | MVVM (`ObservableObject`, `@Published`) |

---

### 🛠️ 開發與安裝說明

1. **複製專案**:
   ```bash
   git clone https://github.com/your-username/EasyFind.git
   cd EasyFind
   ```

2. **使用 Xcode 開啟**:
   ```bash
   open "Untitled Project.xcodeproj"
   ```

3. **建置與執行**:
   - 選擇執行目標模擬器（如 iPhone 15 Pro）或 iOS 17+ 實體裝置。
   - 按下 `Cmd + R` 即可開始執行。

---

### 📄 授權條款
本專案採用 [MIT License](LICENSE) 授權。
