# 🎬 External Animations Guide for NativeNourish

We have successfully integrated **`lottie`** and **`flutter_animate`** into your Flutter project! 

The `ExternalAnimationView` widget (`lib/widgets/external_animation_view.dart`) is now ready to render any external animations you download.

---

## 📥 How to Download & Add External Animations

1. **Visit LottieFiles**: Go to [Lottiefiles.com](https://lottiefiles.com/) (or any other Lottie animation library).
2. **Search & Select**: Search for animations you want (e.g., "success checkmark", "food loading", "scanning barcode", "empty box", "fitness progress").
3. **Download JSON**: Download the **Lottie JSON (.json)** file for each animation.
4. **Place in Assets**: Create (or use) the `assets/animations/` folder in your project root and drop your `.json` files there. For example:
   - `assets/animations/success.json`
   - `assets/animations/loading.json`
   - `assets/animations/scanning.json`
   - `assets/animations/empty.json`
5. **Register in `pubspec.yaml`**: Ensure `assets/animations/` is registered under `flutter:` in your `pubspec.yaml`:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/animations/
   ```

---

## 💻 Code Usage Example

You can easily render any downloaded animation using `ExternalAnimationView`:

```dart
ExternalAnimationView(
  assetPath: 'assets/animations/success.json',
  width: 120,
  height: 120,
  repeat: false,
)
```

Or load directly from a Lottie URL:

```dart
ExternalAnimationView(
  url: 'https://assets2.lottiefiles.com/packages/lf20_kji8gpcc.json',
  width: 150,
  height: 150,
)
```

---

## ✨ Using `flutter_animate` for Micro-Interactions

In addition to Lottie JSON files, **`flutter_animate`** is now available in your project for smooth UI transitions and entrance animations:

```dart
Text('Welcome to NativeNourish')
  .fadeIn(duration: 600.ms)
  .slideY(begin: 0.2, end: 0);
```
