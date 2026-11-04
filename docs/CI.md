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

Workflow [`build-apk.yml`](../.github/workflows/build-apk.yml) (схема взята из `ADatkashov/zairo`, `android-release.yml` /
`build-artifacts.yml`), раннер — `CI_RUNS_ON` или `ubuntu-latest`.

- **Автоматически:** push в `main`, затронувший `mobile/**`, собирает APK; файл лежит в артефактах прогона (14 дней).
- **Вручную:** *Actions → Build APK → Run workflow*. Поля: `api_base_url` (иначе переменная репозитория `API_BASE_URL`,
  иначе `https://jemis-backend.onrender.com`) и `publish_release` — опубликовать GitHub Release с APK и AAB
  (только если задан release-keystore).
- **Подпись:** если заданы секреты репозитория `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` — сборка подписывается release-ключом (CI пишет `mobile/android/key.properties`,
  он в `.gitignore` и удаляется в конце джоба) и дополнительно собирается `.aab` для Google Play. Без секретов —
  debug-ключ (для тестов, не для сторов). Секреты вводит владелец: *Settings → Secrets and variables → Actions*.
  Keystore: `keytool -genkeypair -v -keystore release.jks -alias jemis -keyalg RSA -keysize 2048 -validity 10000`,
  затем `base64 -w0 release.jks` → значение `ANDROID_KEYSTORE_BASE64`. Храните keystore в надёжном месте: потеряв его,
  приложение в сторе нельзя будет обновить.
- Публикация в сторах и выкладка на прод в workflow не входит.
