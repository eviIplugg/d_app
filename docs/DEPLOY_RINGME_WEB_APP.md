# Деплой на https://ringme.web.app

Страница **Site Not Found** в Firebase значит: для проекта **ringme** ещё не было успешного деплоя **или** в `build/web` не было файлов.

## 1. Проверьте проект в консоли

1. Откройте [Firebase Console](https://console.firebase.google.com) → проект с ID **`ringme`** (именно он даёт адрес `ringme.web.app`).
2. Слева **Build → Hosting** — должен быть сайт по умолчанию.

Если проекта `ringme` нет — создайте или используйте тот проект, к которому привязан нужный домен.

## 2. Войдите в CLI и выберите проект

```bash
cd c:\Users\User\d_app
firebase login
firebase use ringme
```

Если проекта нет в списке: `firebase use --add` и выберите **ringme**.

## 3. Соберите веб-приложение (обязательно до deploy)

```bash
flutter build web --release
```

Убедитесь, что появился файл **`build/web/index.html`**. Если папки нет — деплой будет «пустым» и снова покажется Site Not Found.

**Только CRM-админка:**

```bash
flutter build web -t lib/main_crm_web.dart --release
```

## 4. Задеплойте Hosting на ringme

В корне проекта лежит **`firebase.ringme.json`** — конфиг без привязки к `dating-app-34f38`, с `public: build/web`.

```bash
firebase deploy --only hosting --project ringme --config firebase.ringme.json
```

Если ваша версия Firebase CLI **не поддерживает** `--config`, временно скопируйте файл:

```powershell
Copy-Item firebase.json firebase.json.bak
Copy-Item firebase.ringme.json firebase.json
firebase deploy --only hosting --project ringme
Copy-Item firebase.json.bak firebase.json
```

(Во временном `firebase.json` для ringme должен быть один блок `hosting` с `"public": "build/web"`, без чужих `target`.)

## 5. После деплоя

Через 1–2 минуты откройте **https://ringme.web.app** — должна открыться ваша сборка, а не страница Firebase «Site Not Found».

## 6. Авторизация (Firebase Auth)

В **Authentication → Settings → Authorized domains** добавьте **`ringme.web.app`**.

---

**Почему раньше не работало:** в `.firebaserc` по умолчанию указан проект **`dating-app-34f38`**, а деплой шёл туда — сайт **`ringme.web.app`** при этом оставался пустым.
