# CloudX Flutter Demo - Clean Architecture

## Goal: Testable, Maintainable, Automatable

This demo app is built with **clean architecture** principles to enable:
- ✅ **Unit testing** - Test business logic in isolation
- ✅ **Integration testing** - Test CloudX SDK wrapper integration
- ✅ **Widget testing** - Test UI components
- ✅ **Automated testing** - Run tests in CI/CD
- ✅ **Future automation** - Scriptable test scenarios

---

## ⚠️ What We're Testing (CRITICAL)

### ✅ **We ARE testing:**
1. **Flutter Wrapper Methods** - Does the wrapper correctly call CloudX SDK methods?
2. **Flutter Wrapper Callbacks** - Do native callbacks reach Dart listeners?
3. **CLXAd Metadata** - Is ad data (placement, bidder, revenue) passed correctly?
4. **Privacy Parameter Flow** - Are privacy params passed to bid requests? (Charles Proxy validation)
5. **State Management** - Does app state update correctly on callbacks?
6. **UI Integration** - Do ad widgets display properly?

### ❌ **We are NOT testing:**
1. **SDK Internals** - Ad loading logic (native SDK's responsibility)
2. **Bidding Algorithm** - How SDK chooses which ad to show (native SDK's responsibility)
3. **Network Reliability** - Whether SDK's HTTP requests succeed (native SDK's responsibility)
4. **Ad Rendering** - How native ads render pixels (native SDK's responsibility)

### 🔍 **External Validation (Charles Proxy):**
- **Privacy Params** - Verify CCPA, GPP, COPPA, GDPR appear in bid request JSON
- **User Targeting** - Verify user ID and key-values appear in bid request JSON
- **This is NOT testing the SDK** - This is validating that the wrapper passed params to the SDK correctly

---

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (UI Screens - Widgets)                 │
│  - Stateless where possible             │
│  - No business logic                    │
│  - Observes state changes               │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         State Management Layer          │
│  (ChangeNotifier / Cubit / Provider)    │
│  - Holds app state                      │
│  - Notifies UI of changes               │
│  - Calls services                       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Service Layer                   │
│  (Business Logic)                       │
│  - CloudXService (SDK wrapper)          │
│  - SettingsService (config management)  │
│  - LoggerService (callback tracking)    │
│  - Pure Dart (testable)                 │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Data Layer                      │
│  (Repositories)                         │
│  - SettingsRepository (SharedPrefs)     │
│  - LogRepository (in-memory + persist)  │
│  - Abstractions (interfaces)            │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         External Dependencies           │
│  - CloudX Flutter SDK (pub.dev)         │
│  - SharedPreferences                    │
│  - Platform channels                    │
└─────────────────────────────────────────┘
```

---

## Directory Structure

```
lib/
├── main.dart                           # App entry point
│
├── core/                               # Core utilities
│   ├── dependency_injection.dart       # Service locator (GetIt)
│   └── constants.dart                  # App constants
│
├── data/                               # Data layer
│   ├── models/                         # Data models
│   │   ├── ad_callback_event.dart      # Callback event model
│   │   ├── app_settings.dart           # App config model
│   │   └── ad_metadata.dart            # CLXAd wrapper
│   │
│   └── repositories/                   # Data sources
│       ├── settings_repository.dart    # Settings persistence (interface)
│       ├── settings_repository_impl.dart # SharedPrefs implementation
│       ├── log_repository.dart         # Log storage (interface)
│       └── log_repository_impl.dart    # In-memory + persist implementation
│
├── domain/                             # Business logic
│   ├── services/                       # Service interfaces
│   │   ├── cloudx_service.dart         # SDK wrapper interface
│   │   ├── settings_service.dart       # Config management interface
│   │   └── logger_service.dart         # Callback tracking interface
│   │
│   └── usecases/                       # Use cases (optional, can be in services)
│       ├── initialize_sdk.dart         # Initialize CloudX SDK
│       ├── load_banner.dart            # Load banner ad
│       ├── load_interstitial.dart      # Load interstitial ad
│       └── set_privacy_params.dart     # Set privacy settings
│
├── services/                           # Service implementations
│   ├── cloudx_service_impl.dart        # Wraps CloudX SDK calls
│   ├── settings_service_impl.dart      # Manages app settings
│   └── logger_service_impl.dart        # Tracks callbacks
│
├── presentation/                       # UI layer
│   ├── state/                          # State management
│   │   ├── sdk_state.dart              # SDK init state notifier
│   │   ├── banner_state.dart           # Banner ad state notifier
│   │   ├── mrec_state.dart             # MREC ad state notifier
│   │   ├── interstitial_state.dart     # Interstitial ad state notifier
│   │   ├── settings_state.dart         # Settings state notifier
│   │   └── logs_state.dart             # Logs state notifier
│   │
│   ├── screens/                        # UI screens
│   │   ├── settings_screen.dart        # Settings UI
│   │   ├── banner_screen.dart          # Banner test UI
│   │   ├── mrec_screen.dart            # MREC test UI
│   │   ├── interstitial_screen.dart    # Interstitial test UI
│   │   └── logs_screen.dart            # Logs UI
│   │
│   └── widgets/                        # Reusable widgets
│       ├── status_indicator.dart       # Status dot (green/red/gray)
│       ├── callback_log_item.dart      # Single log entry widget
│       └── ad_container.dart           # Ad display container
│
└── test_helpers/                       # Test utilities
    ├── mock_cloudx_service.dart        # Mock SDK for testing
    ├── test_data.dart                  # Test fixtures
    └── test_constants.dart             # Test constants
```

---

## Key Principles

### 1. **Dependency Injection**
- Use `GetIt` for service locator pattern
- All dependencies injected via constructor
- Easy to mock for testing

```dart
// Setup in main.dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Repositories
  getIt.registerSingleton<SettingsRepository>(SettingsRepositoryImpl());
  getIt.registerSingleton<LogRepository>(LogRepositoryImpl());

  // Services
  getIt.registerSingleton<CloudXService>(CloudXServiceImpl());
  getIt.registerSingleton<SettingsService>(SettingsServiceImpl(getIt()));
  getIt.registerSingleton<LoggerService>(LoggerServiceImpl(getIt()));

  // State notifiers
  getIt.registerFactory(() => SdkState(getIt(), getIt()));
  getIt.registerFactory(() => BannerState(getIt(), getIt()));
  // ... etc
}
```

### 2. **Interfaces (Abstract Classes)**
- All services have interfaces
- Implementations are swappable
- Easy to create mocks

```dart
// Interface
abstract class CloudXService {
  Future<bool> initialize(String appKey);
  Future<void> createBanner(String placement, String adId);
  Future<void> loadBanner(String adId);
  // ...
}

// Implementation
class CloudXServiceImpl implements CloudXService {
  @override
  Future<bool> initialize(String appKey) async {
    return await CloudX.initialize(appKey: appKey);
  }
  // ...
}

// Mock for testing
class MockCloudXService implements CloudXService {
  bool shouldSucceed = true;

  @override
  Future<bool> initialize(String appKey) async {
    return shouldSucceed;
  }
  // ...
}
```

### 3. **State Management (ChangeNotifier)**
- Each feature has its own state notifier
- UI observes state changes
- State is immutable where possible

```dart
class BannerState extends ChangeNotifier {
  final CloudXService _cloudxService;
  final LoggerService _loggerService;

  BannerState(this._cloudxService, this._loggerService);

  AdStatus _status = AdStatus.idle;
  String? _errorMessage;
  CloudXAd? _currentAd;

  AdStatus get status => _status;
  String? get errorMessage => _errorMessage;
  CloudXAd? get currentAd => _currentAd;

  Future<void> loadBanner(String placement) async {
    _status = AdStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final adId = 'banner_${DateTime.now().millisecondsSinceEpoch}';
      await _cloudxService.createBanner(placement, adId);
      await _cloudxService.loadBanner(adId);
      // Status updated by callback listener
    } catch (e) {
      _status = AdStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void onAdLoaded(CloudXAd ad) {
    _status = AdStatus.loaded;
    _currentAd = ad;
    _loggerService.log('Banner loaded', ad);
    notifyListeners();
  }
}
```

### 4. **Models (Data Classes)**
- Immutable data classes
- Easy to serialize/deserialize
- Can be copied/compared

```dart
class AppSettings {
  final String appKey;
  final String bannerPlacement;
  final String mrecPlacement;
  final String interstitialPlacement;
  final bool ccpaEnabled;
  final String? ccpaString;
  final bool coppaEnabled;

  const AppSettings({
    required this.appKey,
    required this.bannerPlacement,
    required this.mrecPlacement,
    required this.interstitialPlacement,
    this.ccpaEnabled = false,
    this.ccpaString,
    this.coppaEnabled = false,
  });

  AppSettings copyWith({
    String? appKey,
    String? bannerPlacement,
    // ... etc
  }) {
    return AppSettings(
      appKey: appKey ?? this.appKey,
      bannerPlacement: bannerPlacement ?? this.bannerPlacement,
      // ... etc
    );
  }

  Map<String, dynamic> toJson() => {
    'appKey': appKey,
    'bannerPlacement': bannerPlacement,
    // ... etc
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      appKey: json['appKey'],
      bannerPlacement: json['bannerPlacement'],
      // ... etc
    );
  }
}
```

### 5. **Callback Handling**
- Centralized callback listener
- Routes callbacks to appropriate state notifiers
- Logs all callbacks for debugging

```dart
class CloudXServiceImpl implements CloudXService {
  final LoggerService _loggerService;

  CloudXServiceImpl(this._loggerService) {
    _setupGlobalListeners();
  }

  void _setupGlobalListeners() {
    // Setup banner listener
    _bannerListener = CloudXBannerListener(
      onAdLoaded: (ad) {
        _loggerService.log('Banner loaded', ad);
        _bannerStateNotifier?.onAdLoaded(ad);
      },
      onAdLoadFailed: (error) {
        _loggerService.log('Banner load failed: $error', null);
        _bannerStateNotifier?.onAdLoadFailed(error);
      },
      // ... etc
    );
  }

  BannerState? _bannerStateNotifier;

  void registerBannerStateNotifier(BannerState notifier) {
    _bannerStateNotifier = notifier;
  }
}
```

---

## Testing Strategy

⚠️ **IMPORTANT:** We are **NOT testing the CloudX SDK internals**. We are **ONLY testing the Flutter wrapper** to ensure:
1. ✅ **Methods are called correctly** - Wrapper passes params to native SDK
2. ✅ **Callbacks fire properly** - Native callbacks reach Flutter listeners
3. ✅ **Privacy params reach bid requests** - Verified via Charles Proxy (external validation)

### Unit Tests (`test/unit/`)
**What:** Test wrapper's state management and data flow (NOT SDK behavior)

**Files to test:**
- `presentation/state/*_state_test.dart` - Test state notifiers
- `services/settings_service_impl_test.dart` - Test settings management
- `services/logger_service_impl_test.dart` - Test callback logging
- `data/repositories/*_test.dart` - Test data persistence

**Example:**
```dart
void main() {
  late MockCloudXService mockCloudX;
  late MockLoggerService mockLogger;
  late BannerState bannerState;

  setUp(() {
    mockCloudX = MockCloudXService();
    mockLogger = MockLoggerService();
    bannerState = BannerState(mockCloudX, mockLogger);
  });

  test('loadBanner sets status to loading initially', () async {
    expect(bannerState.status, AdStatus.idle);

    bannerState.loadBanner('test-placement');

    expect(bannerState.status, AdStatus.loading);
  });

  test('onAdLoaded callback updates state correctly', () async {
    final testAd = CloudXAd(
      placementName: 'test-placement',
      bidder: 'test-bidder',
      revenue: 0.05,
    );

    bannerState.onAdLoaded(testAd);

    expect(bannerState.status, AdStatus.loaded);
    expect(bannerState.currentAd, testAd);
  });

  test('logger service records callback event', () {
    final testAd = CloudXAd(placementName: 'test');

    mockLogger.log('Banner loaded', testAd);

    verify(mockLogger.log('Banner loaded', testAd)).called(1);
  });
}
```

### Integration Tests (`test/integration/`)
**What:** Test wrapper integration with **real published CloudX SDK** (v0.3.0 from pub.dev)

**What we're testing:**
- ✅ Wrapper calls SDK methods without errors
- ✅ Callbacks fire and reach Dart listeners
- ✅ CLXAd metadata is passed correctly
- ✅ Ad widgets display properly

**What we're NOT testing:**
- ❌ SDK's ad loading logic (that's the SDK's job)
- ❌ SDK's bidding algorithm (internal to SDK)
- ❌ SDK's network requests (tested via Charles Proxy separately)

**Files to test:**
- `wrapper_callbacks_test.dart` - Verify all callbacks fire
- `wrapper_methods_test.dart` - Verify all SDK methods can be called
- `ad_widget_integration_test.dart` - Verify ad widgets display

**Example:**
```dart
void main() {
  testWidgets('Banner callback fires when ad loads', (tester) async {
    bool callbackFired = false;
    CloudXAd? receivedAd;

    // Create listener to capture callback
    final listener = CloudXBannerListener(
      onAdLoaded: (ad) {
        callbackFired = true;
        receivedAd = ad;
      },
    );

    // Use real SDK (from pub.dev)
    await CloudX.initialize(appKey: 'test-key');
    await CloudX.createBanner(
      placementName: 'test-placement',
      adId: 'banner-1',
      listener: listener,
    );
    await CloudX.loadBanner('banner-1');

    // Wait for callback
    await tester.pumpAndSettle(Duration(seconds: 5));

    // Verify callback fired
    expect(callbackFired, true);
    expect(receivedAd, isNotNull);
    expect(receivedAd?.placementName, 'test-placement');
  });
}
```

### Widget Tests (`test/widget/`)
**What:** Test UI components

**Files to test:**
- `screens/settings_screen_test.dart`
- `screens/banner_screen_test.dart`
- `widgets/status_indicator_test.dart`
- `widgets/callback_log_item_test.dart`

**Example:**
```dart
void main() {
  testWidgets('Settings screen displays app key field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(),
      ),
    );

    expect(find.text('App Key'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('Status indicator shows correct color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StatusIndicator(status: AdStatus.loaded),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.green);
  });
}
```

### E2E Tests (`integration_test/`)
**What:** Test complete user flows

**Files to test:**
- `app_test.dart` - Full app flow test

**Example:**
```dart
void main() {
  testWidgets('Complete ad testing flow', (tester) async {
    await tester.pumpWidget(CloudXDemoApp());

    // Navigate to settings
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Enter app key
    await tester.enterText(find.byKey(Key('appKeyField')), 'test-key');

    // Initialize SDK
    await tester.tap(find.text('Initialize SDK'));
    await tester.pumpAndSettle();

    // Navigate to banner screen
    await tester.tap(find.text('Banner'));
    await tester.pumpAndSettle();

    // Load banner
    await tester.tap(find.text('Load Banner'));
    await tester.pumpAndSettle();

    // Verify banner loaded
    expect(find.byType(CloudXBannerView), findsOneWidget);

    // Verify callback logged
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(find.text('Banner loaded'), findsOneWidget);
  });
}
```

---

## Automation Support

### 1. **Scriptable Test Scenarios**
```dart
// test/scenarios/standard_test_scenario.dart
class StandardTestScenario {
  final CloudXService cloudxService;
  final SettingsService settingsService;

  StandardTestScenario(this.cloudxService, this.settingsService);

  Future<TestReport> run() async {
    final report = TestReport();

    // Test 1: Initialize SDK
    report.addTest('Initialize SDK');
    final initSuccess = await cloudxService.initialize(
      settingsService.getAppKey()
    );
    report.recordResult('Initialize SDK', initSuccess);

    // Test 2: Load Banner
    report.addTest('Load Banner');
    await cloudxService.createBanner('test-banner', 'banner-1');
    await cloudxService.loadBanner('banner-1');
    // Wait for callback...
    report.recordResult('Load Banner', /* callback received */);

    // ... more tests

    return report;
  }
}
```

### 2. **Test Report Generation**
```dart
class TestReport {
  final List<TestResult> results = [];

  void recordResult(String testName, bool success, {String? error}) {
    results.add(TestResult(testName, success, error));
  }

  String toMarkdown() {
    // Generate markdown report
  }

  String toJson() {
    // Generate JSON report for CI/CD
  }
}
```

### 3. **CI/CD Integration**
```yaml
# .github/workflows/test.yml
name: Test CloudX Flutter SDK

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2

      - name: Install dependencies
        run: flutter pub get

      - name: Run unit tests
        run: flutter test test/unit/

      - name: Run integration tests
        run: flutter test test/integration/

      - name: Run widget tests
        run: flutter test test/widget/

      - name: Generate coverage report
        run: flutter test --coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v2
```

---

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cloudx_flutter: ^0.3.0

  # State management
  provider: ^6.0.0

  # Dependency injection
  get_it: ^7.6.0

  # Storage
  shared_preferences: ^2.2.0

  # Utilities
  intl: ^0.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Testing
  mockito: ^5.4.0
  build_runner: ^2.4.0

  # Linting
  flutter_lints: ^3.0.0
```

---

## Development Workflow

### 1. **Build Feature**
1. Create data models
2. Create repository interface + implementation
3. Create service interface + implementation
4. Create state notifier
5. Create UI screen
6. Wire up dependencies in `main.dart`

### 2. **Write Tests**
1. Write unit tests for service
2. Write unit tests for state notifier
3. Write widget tests for UI
4. Write integration test for feature
5. Run all tests: `flutter test`

### 3. **Verify**
1. Test manually on device
2. Check coverage: `flutter test --coverage`
3. Review test report
4. Fix any failing tests

---

## Benefits of This Architecture

✅ **Testable** - All layers can be tested in isolation
✅ **Maintainable** - Clear separation of concerns
✅ **Scalable** - Easy to add new features
✅ **Automatable** - Can run tests in CI/CD
✅ **Mockable** - Easy to create test doubles
✅ **Flexible** - Can swap implementations
✅ **Clean** - Follows SOLID principles
✅ **Future-proof** - Ready for automation/scripting

---

## Next Steps

1. ✅ Setup dependency injection (GetIt)
2. ✅ Create data models (AppSettings, AdCallbackEvent, etc.)
3. ✅ Create repositories (SettingsRepository, LogRepository)
4. ✅ Create services (CloudXService, SettingsService, LoggerService)
5. ✅ Create state notifiers (SdkState, BannerState, etc.)
6. ✅ Create UI screens
7. ✅ Write unit tests
8. ✅ Write integration tests
9. ✅ Write widget tests
10. ✅ Setup CI/CD

This architecture ensures that **every piece of code is testable** and can be **automated in the future**.
