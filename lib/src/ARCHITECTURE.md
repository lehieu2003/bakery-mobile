# Flutter Folder Architecture

## Principles
- Feature-first: mỗi feature tự chứa `presentation`, `domain`, `data`.
- Layered dependency: `presentation -> data -> core`, domain model dùng chung trong feature.
- Dùng `package:` imports để tránh lỗi khi di chuyển file.

## Structure
```text
lib/src
├─ core/
│  ├─ config/
│  ├─ network/
│  ├─ storage/
│  └─ theme/
└─ features/
   ├─ <feature_name>/
   │  ├─ presentation/
   │  │  ├─ screens/
   │  │  ├─ controllers/
   │  │  └─ states/        # optional
   │  ├─ domain/
   │  │  └─ models/
   │  └─ data/
   │     ├─ datasources/
   │     └─ repositories/
   └─ navigation/
      └─ presentation/screens/
```

## Naming Convention
- `*_screen.dart`: UI widgets.
- `*_view_model.dart`: presentation controller/state holder.
- `*_repository.dart`: SSOT + mapping/caching.
- `*_api_service.dart`: gọi API thuần, stateless.
- `models/*.dart`: domain model immutable.

## Add New Feature Checklist
1. Tạo folder feature với 3 layer: `presentation/domain/data`.
2. Tạo model trong `domain/models`.
3. Tạo datasource + repository trong `data`.
4. Tạo view model và screen trong `presentation`.
5. Inject repository/view model ở `main.dart` (hoặc DI container nếu tách sau).
