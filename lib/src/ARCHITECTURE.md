# Flutter Folder Architecture (Riverpod)

## Principles
- Feature-first: mỗi feature tự chứa các layer riêng.
- 4-layer flow: `presentation -> application -> data -> domain`.
- Riverpod là cơ chế DI + state management xuyên suốt.
- Dùng `package:` imports để tránh lỗi khi di chuyển file.

## Structure
```text
lib/src
├─ core/
│  ├─ config/
│  ├─ di/
│  ├─ network/
│  ├─ storage/
│  └─ theme/
└─ features/
   ├─ <feature_name>/
   │  ├─ presentation/
   │  │  ├─ screens/
   │  │  ├─ controllers/
   │  │  └─ states/        # optional
   │  ├─ application/
   │  │  └─ services/
   │  ├─ domain/
   │  │  └─ models/
   │  └─ data/
   │     ├─ datasources/
   │     ├─ dtos/          # optional
   │     └─ repositories/
   └─ navigation/
      └─ presentation/screens/
```

## Naming Convention
- `*_screen.dart`: UI widgets.
- `*_view_model.dart`: Riverpod `Notifier`/`AsyncNotifier` controller.
- `*_state.dart` (hoặc state class trong controller): immutable presentation state.
- `*_service.dart`: application-layer orchestration logic/use-case.
- `*_repository.dart`: SSOT + mapping/caching.
- `*_api_service.dart`: gọi API thuần, stateless.
- `*_dto.dart`: DTO nhận/trả từ API, chỉ sống ở data layer.
- `models/*.dart`: domain model immutable.

## Add New Feature Checklist
1. Tạo folder feature với 4 layer: `presentation/application/domain/data`.
2. Tạo model immutable trong `domain/models`.
3. Tạo datasource + DTO + repository trong `data`.
4. Mapping `DTO -> Domain` bắt buộc đặt ở repository.
5. Nếu có nghiệp vụ phối hợp nhiều repository, đặt vào `application/services`.
6. Tạo `Notifier/AsyncNotifier` + state + screen trong `presentation`.
7. Đăng ký data providers ở `core/di/data_providers.dart` và app-state providers ở `core/di/app_providers.dart`.
