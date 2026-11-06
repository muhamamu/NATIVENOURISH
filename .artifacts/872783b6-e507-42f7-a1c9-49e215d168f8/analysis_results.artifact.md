# 🔍 Comprehensive Code Audit & Food Tracker Analysis: NativeNourish

This audit evaluates **NativeNourish** against professional online food trackers (such as **Cronometer**, **MyFitnessPal**, and **FatSecret**), analyzing data accuracy, API integrations, macro calculations, and database structures.

---

## 📋 Executive Summary

| Evaluation Area | Status | Benchmark vs Professional Trackers |
| :--- | :--- | :--- |
| **Core Architecture** | 🟢 Excellent | Clean separation of Providers, SQLite DAO, and Material 3 UI. |
| **West African Nutrition DB** | 🟢 Outstanding | Unique local focus (Jollof, Egusi, Suya, Moi Moi, Semovita). |
| **Barcode Scanning & OFF API** | 🟡 Good with Caveats | Has offline fallback + API v2 lookup, but needs robust unit/serving normalization. |
| **Macro & Calorie Math** | 🟢 Strong | Atwater general formula applied (`P*4 + C*4 + F*9`). |
| **Micronutrients & Fibre** | 🔴 Opportunity | Currently tracks Macros (P, C, F) & Calories; lacks Fibre, Iron, Sodium tracking. |

---

## 🔎 Detailed Findings & Potential Issues

### 1. Open Food Facts API & Serving Size Normalization
- **Current Implementation**: `OpenFoodFactsService` checks `nutriments['energy-kcal_serving']` vs `energy-kcal_100g`.
- **The Problem**: Open Food Facts database entries often report nutritional values **per 100g**, while `serving_size` is returned as a string (e.g. `"30g"`, `"1 bottle (330ml)"`, `"1 packet (70g)"`). If a product lacks per-serving keys (`_serving`), our fallback to `_100g` without multiplying by the actual serving weight can cause calorie underreporting or overreporting.
- **Recommendation**: Parse the numeric gram/ml weight from `serving_size` (e.g., extracting `"30"` from `"30g"`) and scale `100g` nutritional values proportionally when serving-specific keys are absent.

### 2. Barcode Scanner UI Feedback & Error Recovery
- **Current Implementation**: When scanning an unknown barcode, `lookupBarcode` returns `null` and may leave the user waiting or without clear guidance.
- **Recommendation**: Add a user-friendly dialog in `BarcodeScannerScreen` prompting: *"Product not found in database. Would you like to add it as a custom food item?"* with prefilled barcode data.

### 3. Macro-to-Calorie Consistency (Atwater Validation)
- **Current Implementation**: Calories are calculated via `(protein * 4) + (carbs * 4) + (fat * 9)`.
- **Recommendation**: In professional trackers like Cronometer, if packaged food label calories differ significantly from the Atwater sum (due to alcohol, polyols, or fiber variance), a warning badge is shown. Adding a tolerance check (e.g., flagging if label calories deviate >20% from the macro sum) ensures data integrity.

### 4. Expansion into Micronutrients & Fibre (Cronometer Standard)
- **Current Vision Gap**: A true personal health platform tracks more than just calories, protein, carbs, and fat. Fibre is critical for digestive health (especially with West African staples like beans, plantains, vegetables, and tubers), and micronutrients like iron, sodium, and calcium prevent nutritional deficiencies.
- **Recommendation**: Extend `Food` and `MealLog` models with optional `fibre`, `sodium`, and `iron` fields in future database migrations.

---

## 🛠️ Proposed Action Plan for Next Enhancements
1. **Serving Size Parser**: Enhance `OpenFoodFactsService` to parse gram/ml weights from Open Food Facts `serving_size` strings.
2. **Barcode Not Found Dialog**: Improve `BarcodeScannerScreen` error flow to seamlessly redirect unknown barcodes to `ManualFoodEntryScreen`.
3. **Fibre & Micronutrient Support**: Add fiber tracking to food entries to support health insights.
