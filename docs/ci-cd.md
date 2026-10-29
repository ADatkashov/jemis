# CI/CD

Workflows live in `.github/workflows/`:

| Workflow | When | What |
|---|---|---|
| `ci.yml` | push, pull request | `backend` (Gradle tests against a PostgreSQL service container), `admin` (npm build + tests), `mobile` (Flutter analyze + tests) |
| `runner-smoke.yml` | push that touches the file, manual | Checks that the self-hosted runner picks up jobs |

## Self-hosted runner

GitHub-hosted runners need Actions minutes and billing. If they are unavailable (jobs fail within seconds with no
steps and no logs), or you just want to save minutes, run CI on your own machine. Every job in `ci.yml` picks its
runner from the repo variable `CI_RUNS_ON` (unset = `ubuntu-latest`), so no code change is needed to switch.
The procedure and script are the ones already used in the zairo repo.

1. On a Linux x64 machine with Docker (the user must be in the `docker` group): GitHub -> repo *Settings -> Actions ->
   Runners -> New self-hosted runner*, copy the registration token (valid 1 hour).
2. `scripts/setup-self-hosted-runner.sh <token>` as a normal user with sudo (not root). It downloads the runner,
   registers it and installs it as a service.
3. *Settings -> Secrets and variables -> Actions -> Variables*: add `CI_RUNS_ON` = `["self-hosted","linux"]`.
4. Run *Actions -> Runner smoke test -> Run workflow* to check it, then re-run CI. To go back to GitHub-hosted,
   delete the variable.

**On Windows:** run the runner inside WSL2, not as a native Windows runner (the jobs are bash + Linux containers).
1. PowerShell (admin): `wsl --install -d Ubuntu`, reboot, create the Ubuntu user.
2. Docker Desktop -> *Settings -> Resources -> WSL integration*: enable Ubuntu. Check `docker ps` works inside Ubuntu.
3. Optional, so the runner can be a service: in Ubuntu `sudo sh -c 'printf "[boot]\nsystemd=true\n" >> /etc/wsl.conf'`,
   then `wsl --shutdown` from PowerShell. Without systemd the script tells you to start `~/actions-runner/run.sh`
   by hand and keep that terminal open.
4. In Ubuntu: `git clone` the repo (or copy the script) and continue from step 2 above.
The PC must be on, with WSL and Docker Desktop running, while CI runs.

Notes:

- The runner is persistent, so caches (Gradle, pub, Flutter SDK) stay on its disk. When `CI_RUNS_ON` is set, the
  workflows skip the GitHub cloud caches.
- The backend job publishes PostgreSQL on host port 5433 (not 5432), so a PostgreSQL already running on the runner
  machine does not clash; the tests read it through `JEMIS_TEST_DB_URL`.
- **Security:** `ci.yml` also runs on `pull_request`. Use a self-hosted runner only for a **private** repository, or
  one where nobody can open pull requests from forks you do not trust: a pull request can run arbitrary code on the
  runner machine. For a public repository, restrict the triggers to pushes (as the zairo repo does) before setting
  `CI_RUNS_ON`.
- If the machine is off, jobs wait in the queue until it is back.
