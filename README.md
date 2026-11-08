# XOL Station

Страница для сброса задач: https://kroune.github.io/xol-station/

- `reset.ps1` — сброс на Windows через PowerShell;
- `reset.sh` — сброс на Linux и macOS через POSIX `sh`;
- `index.html` — страница с копируемыми командами.

Команды запускаются из **родительской папки**. Они скачивают актуальный архив [kroune/xol-tasks](https://github.com/kroune/xol-tasks), удаляют локальную папку `xol-station`, если она существует, и создают её заново с чистыми `main.xol`.

Для сброса нужен интернет. Git, Python и npm не требуются. Для последующего запуска тестов нужен Node.js 20+.
