# bycreep — iPhone 14 Pro (iOS 17+, Swift/SwiftUI/SwiftData)

## Запуск (нужен Mac с Xcode 15+)
1. `brew install xcodegen`
2. В папке проекта: `xcodegen` → создастся `bycreep.xcodeproj`
3. Открой проект, в Signing & Capabilities у обоих таргетов (bycreep и bycreepWidget) выбери свой Team.
4. Если App Group `group.com.bycreep.app` занят — поменяй имя в `project.yml` и в `Shared/Shared.swift` (константа `group`).
5. Запусти на iPhone (Run). Виджет: долгое нажатие на главный экран → «+» → bycreep → «неделя» (средний размер).

## Оптимизация
- SwiftData + предикаты на уровне БД (питание грузится только за выбранный день)
- Фото — файлы на диске, сжатие до 1600px, миниатюры через ImageIO, NSCache
- LazyVStack/LazyVGrid/List, без лишних перерисовок
- Виджет: UserDefaults (App Group), 1 обновление в сутки после полуночи
- Только iPhone, только портрет, тёмная тема, whole-module компиляция

## Сборка IPA через GitHub (без Mac)
1. Залей СОДЕРЖИМОЕ папки проекта в корень репозитория (чтобы `project.yml` и `.github` были в корне).
2. Вкладка Actions → Build IPA (запускается сам при push, или Run workflow).
3. Когда сборка зелёная — открой запуск, внизу Artifacts → `bycreep-ipa` → скачай `bycreep.ipa` (внутри zip).
4. IPA неподписанный: установи через Sideloadly / AltStore / TrollStore (они подпишут твоим Apple ID).
