# CI

Workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) — три джоба: `backend` (тесты Gradle на PostgreSQL),
`admin` (`npm run build` + тесты), `mobile` (`flutter analyze` + тесты). Запуск: push в `main` и `pull_request` (только из этого же
репозитория — форки на раннер не пускаются); новый пуш в ту же ветку/PR отменяет ещё идущий прогон (`concurrency`),
а пуш в ветку PR не запускает CI второй раз. Отдельный workflow
[`runner-smoke.yml`](../.github/workflows/runner-smoke.yml) проверяет, что self-hosted раннер берёт джобы.

## Self-hosted runner

GitHub-hosted раннеры требуют Actions-минуты/биллинг (если их нет — джобы падают за секунды без шагов, `runner_id = 0`).
Self-hosted раннер на своей машине их не расходует. Раннер выбирается переменной репозитория `CI_RUNS_ON`
(не задана = `ubuntu-latest`), менять код не нужно. Скрипт и схема перенесены из проверенных настроек
`ADatkashov/feya` (ветка `main`) и `ADatkashov/zairo` (ветка `develop`).

1. Linux x64 с Docker (пользователь в группе `docker`). GitHub → репозиторий *Settings → Actions → Runners → New
   self-hosted runner* → скопировать registration token (действует 1 час, одноразовый; не вставляйте его в чат, PR и
   коммиты).
2. `scripts/setup-self-hosted-runner.sh <token>` — скачивает раннер, регистрирует (метки `self-hosted,linux,x64`) и
   ставит сервисом (`systemd`). Запускать **не от root**, нужен `sudo`.
3. *Settings → Secrets and variables → Actions → Variables*: `CI_RUNS_ON` = `["self-hosted","linux"]`.
4. *Actions → Runner smoke test → Run workflow* — проверка, что раннер берёт джобы. Затем перезапустить CI.
   Вернуться на GitHub-hosted: удалить переменную `CI_RUNS_ON`.

**Windows:** запускайте раннер внутри WSL2 (Ubuntu), не нативно: `wsl --install -d Ubuntu`; в Docker Desktop включить
WSL integration для Ubuntu; опционально включить `systemd=true` в `/etc/wsl.conf` (иначе скрипт попросит запускать
`~/actions-runner-jemis/run.sh` вручную и держать терминал открытым). Компьютер должен быть включён на время CI.

### Особенности

- Раннер ставится в `~/actions-runner-jemis` (переменная `RUNNER_DIR`), поэтому не конфликтует с раннерами других
  репозиториев на той же машине (`~/actions-runner` для `zairo`, `~/actions-runner-feya` и т. д.). Раннер привязан к
  одному репозиторию (общая папка даёт ошибку «Cannot configure the runner because it is already configured»); несколько
  раннеров на одной машине работают как отдельные сервисы.
- Раннер постоянный: Gradle, pub и Flutter SDK остаются на диске, поэтому CI быстрее. При заданном `CI_RUNS_ON`
  облачные кэши (`setup-gradle`, `flutter-action`) отключены — они считаются в квоте Actions storage.
- PostgreSQL для тестов поднимается service-контейнером на **случайном** порту хоста (`ports: ["5432"]`), адрес
  передаётся в тесты через `JEMIS_TEST_DB_URL`, поэтому локальный PostgreSQL на 5432 не мешает.
- Артефакты отчёта о тестах хранятся 3 дня.
- Джобы пропускаются для PR из форков (`head.repo.full_name != github.repository`): код чужих форков не должен
  выполняться на вашей машине. Не добавляйте триггеры `pull_request_target` и не включайте раннер для публичных форков.
- В `ci.yml` нет шагов `docker run`, поэтому очищать старые контейнеры не нужно. Если такой шаг появится, перед ним
  добавьте `docker rm -f <имя> || true`: на постоянном раннере контейнер мог остаться от отменённого прогона.
- Если машина выключена, джоб ждёт в очереди.

## Сборка APK

Workflow [`build-apk.yml`](../.github/workflows/build-apk.yml), запуск вручную: *Actions → Build APK → Run workflow*.
Адрес API вводится в поле `api_base_url` (или задаётся переменной репозитория `API_BASE_URL`); без него приложение
соберётся с адресом эмулятора `http://10.0.2.2:8080`. Готовый `app-release.apk` лежит в артефактах прогона (14 дней).
Раннеру нужен доступ к `dl.google.com` (Android SDK ставится шагом `android-actions/setup-android`, ~1–2 ГБ при
первом запуске). Сборка пока подписана debug-ключом — для публикации в сторах нужен собственный keystore.
