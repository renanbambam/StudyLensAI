# StudyLens AI — TODO

> Fonte da verdade: `Studylens architecture.MD`. Este arquivo rastreia fases, tarefas, dependências e progresso.
> Status: `[ ]` pendente · `[~]` em andamento · `[x]` concluído · `[!]` bloqueado

## Restrição de ambiente (registrada)

- **Ambiente de desenvolvimento atual é Windows 11 sem toolchain Swift/Xcode.** Build, testes e SwiftLint só executam em macOS. A validação de compilação/testes é delegada ao CI (GitHub Actions, runner macOS) e ao Xcode local do autor. Nenhuma afirmação de "build passou" foi feita sem execução real — ver "Problemas conhecidos" abaixo.
- **Decisão:** projeto declarado via **XcodeGen** (`project.yml`). No Mac: `brew install xcodegen && xcodegen generate`.

## Fase 0 — Fundação ✅
- [x] Repositório git (branch `main`), `.gitignore`
- [x] `project.yml` (XcodeGen: app + widget + testes + UI tests)
- [x] `.swiftlint.yml`
- [x] `.github/workflows/ci.yml` (xcodegen + SwiftLint strict + xcodebuild test)

## Fase 1 — Domínio ✅
- [x] Enums: `ReviewRating`, `ScanStatus`, `StudyMode`
- [x] Erros: `StudyLensError`
- [x] Modelos SwiftData: `Deck`, `Flashcard`, `StudySession`, `CardReview`, `ScanSession`
- [x] `SpacedRepetitionService` (SM-2) + protocolo
- [x] `ProgressService` (streak, retenção, heatmap, due por matéria) + protocolo

## Fase 2 — Dados ✅
- [x] `PersistenceController` (CloudKit privado + fallback local + in-memory p/ testes)
- [x] `DeckRepository`, `FlashcardRepository`, `SessionRepository` + protocolos

## Fase 3 — Infraestrutura ✅
- [x] `KeychainHelper` + protocolo `APIKeyProviding`
- [x] Prompts versionados (`flashcard_generation_v1`, `card_improvement_v1`)
- [x] `ClaudeAPIModels` + `ClaudeAIService` (URLSession async/await, strip de fences, erros tipados)
- [x] `VisionOCRService` (`VNRecognizeTextRequest`, `.accurate`, language correction)
- [x] `StudyAnalytics` (os.Logger local)
- [x] `WidgetDataStore` (App Group, compartilhado com o widget)

## Fase 4 — Design System + App shell ✅
- [x] `Colors` (tokens + `DeckPalette`), `Typography`
- [x] `PrimaryButton`, `SubjectBadge`, `LoadingOverlay`
- [x] `StudyLensApp` (@main, ModelContainer, deep link, prompt de API key)
- [x] `AppDependencies` (composition root + refresh do snapshot do widget)
- [x] `AppRouter` (tabs, deep link `studylens://study/<uuid>`, handoff do Siri intent)

## Fase 5 — Features ✅
- [x] Scan: `ScanView` (+wrapper `VNDocumentCameraViewController`), `ScanViewModel`, `ReviewGeneratedCardsView`, `ScanPreviewCard`, `CardDraftRow`
- [x] Decks: `DeckListView(+VM)` (busca/filtro/sort/swipe), `DeckDetailView(+VM)` (CRUD + improve via AI), `CreateDeckView`, `DeckCard`, `FlashcardRow`
- [x] Study: `StudySessionView(+VM)`, `SessionCompleteView`, `FlashcardFlipView` (flip 3D), `RatingButtons`, `SessionProgressBar`
- [x] Stats: `StatsView(+VM)`, `StreakBadge`, `RetentionChart` (Charts), `HeatmapView`, `DueBySubjectChart`
- [x] Settings: `APIKeySetupView` (requisito do Quick Start da arquitetura)

## Fase 6 — Widget + App Intents ✅
- [x] `StudyLensWidget` (bundle), `StudyWidgetProvider`, `StudyWidgetView` (Home), `LockScreenWidgetView` (streak)
- [x] Deep link do widget → sessão de estudo
- [x] `StartStudyIntent` + `AppShortcutsProvider` ("Start studying [deck]")

## Fase 7 — Testes ✅
- [x] `SpacedRepetitionServiceTests` (8 casos: reset, escada 1/6/EF×, piso 1.3, datas)
- [x] `ProgressServiceTests` (11 casos: streak, retenção, heatmap, due por matéria)
- [x] `ClaudeAIServiceTests` (URLProtocol mock: parse, fences, headers, erros)
- [x] `ScanViewModelTests` (usa os 3 mocks: OCR, AI, DeckRepository)
- [x] Mocks: `MockDeckRepository`, `MockAIService`, `MockOCRService`
- [x] `ScanFlowUITests` (smoke: launch + navegação de tabs)

## Fase 8 — Documentação e revisão ✅
- [x] `README.md` (setup, arquitetura, decisões, limitações)
- [x] Revisão de consistência (concorrência @MainActor, imports, Swift 5.10, sem código morto)
- [!] **Execução de build/testes — bloqueado neste ambiente (Windows).** Validar no Mac: `xcodegen generate` → `xcodebuild test`. O CI executa o mesmo pipeline em cada push.

## Decisões registradas
1. **XcodeGen** em vez de `.xcodeproj` versionado (impossível gerar pbxproj no Windows; melhor DX de equipe).
2. **Modelos CloudKit-compatíveis**: sem `@Attribute(.unique)`, defaults em atributos, relacionamentos opcionais (exigência da plataforma; API computada preservada).
3. **Modelo Claude `claude-sonnet-4-6`**: o `claude-sonnet-4-20250514` fixado na arquitetura foi deprecado pela Anthropic (aposentadoria 15/06/2026); substituto drop-in oficial adotado e documentado.
4. **App Intents no target do app** (recomendação Apple para intents que abrem o app); pasta `StudyLensIntents/` mantida.
5. **`WidgetDataStore`** em `Infrastructure/Widget/` compartilhado entre targets — materializa o requisito "App Group UserDefaults".
6. **`card_improvement_v1.swift`**: prompt versionado para `improveCard` (exigido pelo protocolo `AIGenerationServiceProtocol`).
7. **Fallback de store local** quando CloudKit indisponível (simulador/CI/sem conta iCloud).
8. **Retenção**: rating ≠ `.again` conta como correto (suposição técnica; não especificado na arquitetura).
9. **Scan MVP**: processa a primeira página de um scan multipágina (suposição técnica de escopo).

## Fase 2 do roadmap da arquitetura ✅
- [x] Lock Screen widget (streak) — entregue na Fase 6
- [x] Siri App Intent — entregue na Fase 6
- [x] PDF import (scan from Files): `PDFPageRenderer` (PDFKit) + `fileImporter` na ScanView; primeira página → mesmo pipeline de OCR (consistente com o escopo do scan)
- [x] Haptic feedback nos ratings: `UINotificationFeedbackGenerator` em `RatingButtons` (error/warning/success por rating — suposição técnica de mapeamento)
- [x] Export CSV / Anki: `DeckExportService` (+protocolo, puro/testável), menu de export no `DeckDetailView` com share sheet; CSV RFC-4180 com header, Anki = TSV sem header (formato de import nativo do Anki)
- [x] `DeckExportServiceTests` (6 casos: header, escaping, deck vazio, TSV, sanitização, ordenação)

## Validação no CI ✅
- [x] **Pipeline verde** (run 27412246372, 12/06/2026): XcodeGen → SwiftLint strict → build Xcode 16.1 → **41 testes unitários + 2 UI tests, 0 falhas** (`** TEST SUCCEEDED **`).
- Correções aplicadas durante a estabilização do CI (cada uma com causa raiz no histórico de commits):
  1. 4 violações SwiftLint strict (`f9eaeca`)
  2. `.percent` ambíguo no AxisMarks do Charts (`ec2a60e`)
  3. Bundle ID do widget sem o prefixo do app → instalação no simulador rejeitada (`51f0fa4`)
  4. Runner sem o simulador nomeado → seleção dinâmica via `simctl` por UDID (`9d00109`)
  5. Parâmetro `String` em frase de App Shortcut → crash no registro durante o launch (`23df348`)
  6. `ModelContainer` CloudKit sem entitlement (build não assinado) lança exceção ObjC não-capturável → store in-memory sob testes + dump de crash reports no CI (`a0c0aba`)

## Auditoria de completude vs arquitetura (12/06/2026) ✅
- [x] **ScanSession integrado ao fluxo de scan** (era código morto): `ScanSessionRepository` (+protocolo, +mock, +3 testes); ciclo pending → generating → complete/failed, thumbnail JPEG reduzido e `generatedDeckId` vinculado no save. A arquitetura não define UI de histórico de scans, então o registro é só persistência/rastreabilidade.
- [x] **Import da fototeca** (`PhotosPicker`): materializa o `NSPhotoLibraryUsageDescription` declarado na arquitetura; mesma pipeline de OCR.
- [x] Todos os demais itens do MVP e da Fase 2 conferidos item a item contra o arquivo de arquitetura — completos.

## Pendências reais
- [ ] Teste de CloudKit sync em dispositivo físico com conta iCloud (não verificável em CI/simulador).
- **Xcode Cloud** (listado no stack junto com GitHub Actions): não é configurável via arquivos do repositório — exige setup manual no App Store Connect/Xcode pelo dono da conta Apple Developer. GitHub Actions cobre build/lint/testes; Xcode Cloud fica como passo manual opcional.
