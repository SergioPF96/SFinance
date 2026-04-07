# Quickstart: SFinance Core Application

**Branch**: `001-sfinance-core-app` | **Date**: 2026-04-06

## Prerequisites

- **Flutter SDK**: Stable channel (run `flutter channel stable && flutter upgrade`)
- **Dart SDK**: Bundled with Flutter
- **Melos**: `dart pub global activate melos`
- **Platform**: Windows, macOS, or Linux desktop environment
- **IDE**: VS Code or Android Studio with Flutter/Dart plugins

## Initial Setup

### 1. Bootstrap the monorepo

From the repository root:

```bash
# Navigate to the monorepo root
cd my_apps/

# Install dependencies across all packages
melos bootstrap
```

This runs `flutter pub get` in every package and sets up cross-package symlinks.

### 2. Run code generation (Drift)

Drift requires `build_runner` to generate database code:

```bash
# From the shared_services package (where Drift tables live)
cd packages/shared_services/
dart run build_runner build --delete-conflicting-outputs

# Or from monorepo root via Melos
cd my_apps/
melos exec --scope=shared_services -- dart run build_runner build --delete-conflicting-outputs
```

Re-run this command whenever you modify Drift table definitions.

### 3. Run the app

```bash
cd my_apps/apps/sfinance/

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## Development Commands

### Run all tests
```bash
cd my_apps/
melos run test
```

### Run tests for a single package
```bash
cd my_apps/apps/sfinance/
flutter test

# Or a specific test file
flutter test test/providers/kpi_provider_test.dart
```

### Analyze code
```bash
cd my_apps/
melos exec -- flutter analyze
```

### Format code
```bash
cd my_apps/
melos exec -- dart format .
```

### Watch mode for code generation
```bash
cd my_apps/packages/shared_services/
dart run build_runner watch --delete-conflicting-outputs
```

## Project Structure

```
my_apps/
├── apps/
│   └── sfinance/
│       ├── lib/
│       │   ├── main.dart                 # App entry point
│       │   ├── app.dart                  # MaterialApp + go_router setup
│       │   ├── providers/                # Riverpod providers (globally scoped)
│       │   │   ├── kpi_provider.dart
│       │   │   ├── chart_providers.dart
│       │   │   ├── transaction_providers.dart
│       │   │   ├── template_providers.dart
│       │   │   ├── form_providers.dart
│       │   │   └── initial_capital_provider.dart
│       │   ├── ui/                       # Presentational widgets only
│       │   │   ├── shell/                # App shell + nav bar
│       │   │   ├── resumen/              # Resumen view widgets
│       │   │   ├── analisis/             # Analisis view widgets
│       │   │   ├── entradas/             # Entradas view widgets
│       │   │   └── forms/                # Income/expense form widgets
│       │   ├── routing/                  # go_router configuration
│       │   │   └── app_router.dart
│       │   └── services/                 # App-specific services
│       │       └── recurring_generation_service.dart
│       └── test/
│           ├── providers/                # Provider unit tests
│           └── services/                 # Service unit tests
├── packages/
│   ├── shared_models/
│   │   └── lib/
│   │       └── src/
│   │           ├── enums/                # TransactionType, categories, etc.
│   │           ├── transaction.dart      # Transaction model (pure Dart)
│   │           ├── recurring_template.dart
│   │           └── initial_capital.dart
│   ├── shared_ui/
│   │   └── lib/
│   │       └── src/
│   │           ├── theme/                # App theme (dark theme, colors)
│   │           ├── widgets/              # Reusable widgets (KPI card, transaction row, etc.)
│   │           └── formatters/           # Currency formatter, date formatter
│   └── shared_services/
│       └── lib/
│           └── src/
│               ├── database/             # Drift database definition + DAOs
│               │   ├── app_database.dart
│               │   ├── tables/           # Drift table definitions
│               │   └── daos/             # TransactionDao, TemplateDao, InitialCapitalDao
│               └── generation/           # Recurring entry generation logic
│                   └── period_generator.dart
└── melos.yaml
```

## Key Dependencies

| Package | Location | Purpose |
|---------|----------|---------|
| `flutter_riverpod` | sfinance app | State management |
| `go_router` | sfinance app | Routing |
| `drift` | shared_services | SQLite ORM |
| `drift_dev` | shared_services (dev) | Code generation |
| `sqlite3_flutter_libs` | shared_services | SQLite native bindings |
| `build_runner` | shared_services (dev) | Code generation runner |
| `fl_chart` | shared_ui | Charts (bar + line) |
| `intl` | shared_ui | Locale-aware formatting |
| `flutter_test` | all packages (dev) | Testing |
| `riverpod` | shared_services | Provider access without Flutter |

## Workflow

1. **Models first**: Define/modify models in `shared_models` (pure Dart, no Flutter imports)
2. **Storage next**: Define Drift tables and DAOs in `shared_services`, run `build_runner`
3. **Providers**: Wire up Riverpod providers in `sfinance/lib/providers/`
4. **UI last**: Build presentational widgets in `sfinance/lib/ui/`
5. **Test throughout**: Financial logic tests written and failing BEFORE implementation (Red-Green-Refactor)
