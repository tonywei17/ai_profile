# 光影形象馆 / AIIDPhoto CN

SwiftUI iOS app for AI ID photo and professional profile photo generation, customized for the China mainland edition.

- Source code lives under `ios/AIIDPhoto/`
- Features: SwiftUI UI, StoreKit 2 consumable photo task, HivisionIDPhotos + Alibaba Cloud Bailian backend pipeline, 3-attempt generation flow, HD export, print layout

## Quick start
1. Generate/open `AIIDPhoto.xcodeproj`.
2. Confirm `project.yml` Info.plist values and StoreKit product ID `com.yufeicn.aiidphoto.photo_task_3`.
3. Run on simulator or device.

## Backend

The CN backend runs as a Node/Express service on Alibaba Cloud ECS behind Nginx. See `docs/07-deployment/cloud-run-deploy.md` for the current deployment notes. The filename is historical.
