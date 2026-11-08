#!/bin/sh
set -u

STATION_NAME='xol-station'
ARCHIVE_URL='https://github.com/kroune/xol-tasks/archive/refs/heads/main.tar.gz'
CURRENT_DIR="$(pwd -P)" || {
    printf 'ОШИБКА: не удалось определить текущую папку.\n' >&2
    exit 1
}
DESTINATION="$CURRENT_DIR/$STATION_NAME"

fail() {
    printf '\nОШИБКА: %s\n' "$1" >&2
    exit 1
}

case "$CURRENT_DIR/" in
    "$DESTINATION/"*)
        fail "запустите команду из родительской папки, а не изнутри $STATION_NAME."
        ;;
esac

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xol-station-reset.XXXXXX")" \
    || fail 'не удалось создать временную папку.'
trap 'rm -rf "$WORK_DIR"' EXIT
trap 'exit 1' HUP INT TERM

ARCHIVE="$WORK_DIR/tasks.tar.gz"
printf 'Скачивание задач XOL...\n'
if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 2 "$ARCHIVE_URL" -o "$ARCHIVE" \
        || fail 'не удалось скачать архив. Проверьте интернет и доступ к github.com.'
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$ARCHIVE" "$ARCHIVE_URL" \
        || fail 'не удалось скачать архив. Проверьте интернет и доступ к github.com.'
else
    fail 'не найдены curl и wget. Установите один из них и повторите команду.'
fi

command -v tar >/dev/null 2>&1 \
    || fail 'не найден tar. Установите tar и повторите команду.'
tar -xzf "$ARCHIVE" -C "$WORK_DIR" \
    || fail 'скачанный архив повреждён. Повторите команду позже.'

SOURCE="$WORK_DIR/xol-tasks-main"
[ -f "$SOURCE/easy/main.xol" ] && [ -f "$SOURCE/medium/main.xol" ] && [ -f "$SOURCE/hard/main.xol" ] \
    || fail 'архив имеет неожиданную структуру. Существующая папка не изменена.'

if [ -e "$DESTINATION" ]; then
    printf 'Удаление старой папки %s...\n' "$DESTINATION"
    rm -rf "$DESTINATION" \
        || fail "не удалось удалить $DESTINATION. Закройте файлы папки и проверьте права."
fi

cp -R "$SOURCE" "$DESTINATION" \
    || fail "не удалось создать $DESTINATION. Проверьте права на текущую папку."

[ -f "$DESTINATION/easy/main.xol" ] && [ -f "$DESTINATION/medium/main.xol" ] && [ -f "$DESTINATION/hard/main.xol" ] \
    || fail 'папка создана не полностью. Повторите команду.'

printf '\nГотово: %s\n' "$DESTINATION"
printf 'Решения и тесты сброшены.\n'
printf '\nЗапуск тестов (нужен Node.js 20+):\n'
printf '  node %s/easy/test.js\n' "$STATION_NAME"
printf '  node %s/medium/test.js\n' "$STATION_NAME"
printf '  node %s/hard/test.js\n' "$STATION_NAME"
