# creo-work — личная рабочая папка Микиты

Синхронизируется между компами через git (приватный репо). Не канон — личные рабочие артефакты.

- `shotlists/` — микродрама-шотлисты (.md + .html). `shotlists/INDEX.md` — автосписок (генерит worksync, руками не трогать).
- `bin/` — служебные скрипты (worksync, plist агента).
- дальше сюда же — любые личные рабочие файлы.

## Синк

Синхрон постоянный и фоновый — работает сам, ничего запускать не нужно.

- **Автоматом:** launchd-агент `com.mik2.worksync` гоняет `worksync` раз в 30 мин + при входе/пробуждении Mac. Тянет свежее и пушит твои правки. С таймаутами (не виснет) и локом (не накладывается). Нет сети — тихо ждёт следующего раза.
- **Руками (если надо прямо сейчас):** команда `worksync` в терминале.

Что делает `worksync`: `git pull --rebase --autostash` → обновляет INDEX → коммит всех изменений → `git push`.

## Новый комп (разово)

```sh
git clone git@github.com:kostofon/creo-work.git ~/creo-work
# alias для ручного вызова:
echo 'alias worksync="/bin/zsh ~/creo-work/bin/worksync.sh && echo synced"' >> ~/.zshrc
# фоновый агент:
cp ~/creo-work/bin/com.mik2.worksync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.mik2.worksync.plist
```

Дальше синк идёт сам.

## Логи (если что-то не синкается)

- `.worksync.log` — что делал worksync (pushed / nothing to sync / push failed).
- `.worksync.launchd.log` — вывод самого агента.
