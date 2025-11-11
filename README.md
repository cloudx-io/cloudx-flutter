# CloudX Flutter SDK

[![pub package](https://img.shields.io/pub/v/cloudx_flutter.svg)](https://pub.dev/packages/cloudx_flutter)
[![GitHub](https://img.shields.io/badge/github-cloudx--flutter-blue)](https://github.com/cloudx-io/cloudx-flutter)

Flutter plugin for CloudX ad monetization platform. Monetize your Flutter apps with banner, MREC, interstitial, and rewarded ads across iOS and Android.

## 📖 Documentation

**[→ View Full SDK Documentation](cloudx_flutter_sdk/README.md)**

The complete documentation including installation, usage examples, API reference, and best practices is available in the SDK README.

## Repository Structure

```
cloudx-flutter/
├── cloudx_flutter_sdk/      # Flutter plugin SDK package
│   └── README.md            # 📖 Full documentation here
└── cloudx_flutter_demo_app/ # Demo app with examples
```

## Quick Links

- **[Installation Guide](cloudx_flutter_sdk/README.md#installation)** - Get started with the SDK
- **[Quick Start](cloudx_flutter_sdk/README.md#quick-start)** - Banner, MREC, and Interstitial examples
- **[Privacy & Compliance](cloudx_flutter_sdk/README.md#privacy--compliance)** - CCPA, GDPR, COPPA, GPP support
- **[API Reference](cloudx_flutter_sdk/README.md#api-reference)** - Complete API documentation
- **[Demo App](cloudx_flutter_demo_app/)** - Full-featured example application

## Platform Support

| Platform | Status | Minimum Version |
|----------|--------|-----------------|
| **Android** | ✅ Production Ready | API 21 (Android 5.0) |
| **iOS** | ⚠️ Alpha/Experimental | iOS 14.0 |

## Features

- **Banner Ads** (320x50) - Standard banner ads
- **MREC Ads** (300x250) - Medium Rectangle ads
- **Interstitial Ads** - Full-screen ads
- **Privacy Compliance** - CCPA, GPP, GDPR, COPPA support
- **Auto-Refresh** - Server-side configuration
- **Revenue Tracking** - eCPM and bidder information

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cloudx_flutter: ^0.11.0
```

Then see the [full installation guide](cloudx_flutter_sdk/README.md#installation) for platform-specific setup.

## Support

For questions, issues, or feature requests, contact the CloudX team.

## License

Business Source License 1.1 - See LICENSE file for details.
