# Quest 3 WebXR demó — HTTPS-kiszolgálás

A `index.html` a `quest-mr-demo.html` bájtra azonos másolata
(sha256 `61afb412…c35cc1`). Azért hívják `index.html`-nek, hogy a headsetben
a mappa gyökerét kelljen beírni, ne egy hosszú fájlnevet.

A `check.html` egy különálló diagnosztikai oldal, ami pontosan ezt a sort
mutatja, és egy gombbal valódi `immersive-ar` sessiont is kér próbaképpen:

```
HTTPS / biztonságos kontextus: igen · WebXR: elérhető · keretben: nem
```

---

## A) Ideiglenes cím a saját gépedről (a leggyorsabb)

### Telepítés (egyszer)

| Rendszer | Parancs |
|---|---|
| macOS | `brew install cloudflared` |
| Windows | `winget install --id Cloudflare.cloudflared` |
| Linux | `curl -L -o /tmp/cf https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && sudo install /tmp/cf /usr/local/bin/cloudflared` |

Python 3 is kell (macOS/Linux alapból van, Windows: `winget install Python.Python.3.12`).
Fiók, regisztráció nem kell.

### Futtatás

macOS / Linux:

```bash
./serve.sh                              # a mappában lévő html-t szolgálja ki
./serve.sh /ut/quest-mr-demo.html       # vagy add meg útvonallal
./serve.sh --lt                         # localtunnel, ha nincs cloudflared
```

Windows:

```powershell
.\serve.ps1
```

A szkript kiírja a `https://….trycloudflare.com` címet — ezt írd be a Quest
böngészőjének címsorába. A cím addig él, amíg a szkript fut (Ctrl+C = vége).

### Kézi megoldás szkript nélkül (két terminál)

```bash
# 1. terminál — a mappában, ahol a fájl index.html néven van
python3 -m http.server 8080 --bind 127.0.0.1

# 2. terminál
cloudflared tunnel --url http://127.0.0.1:8080
```

---

## B) Tartós cím: GitHub Pages

Ez a repó **privát**, a GitHub Pages viszont ingyenes csomagon csak publikus
repónál működik (fizetősnél a privát Pages-oldal is csak GitHub-bejelentkezés
után nyílik meg — headsetben kényelmetlen).

1. GitHub → a repó **Settings** → legalul **Change repository visibility** →
   **Make public**.
2. Push a branchre (vagy a Actions fülön *Deploy to GitHub Pages* →
   *Run workflow*). A workflow `enablement: true`-val magától bekapcsolja a
   Pages-t, nem kell külön beállítani.
3. A cím ezután állandó:

```
https://czaunb.github.io/project/
https://czaunb.github.io/project/check.html
```

---

## C) USB-kábellel, tunnel nélkül

A `http://localhost` a böngészők szerint **biztonságos kontextus**, tehát a
WebXR elindul rajta. Nem kell se HTTPS, se internet, se harmadik fél.

1. Quest: Beállítások → Rendszer → Fejlesztői mód bekapcsolása.
2. Kösd USB-vel a géphez, és a headsetben engedélyezd a hibakeresést.

```bash
adb reverse tcp:8080 tcp:8080
python3 -m http.server 8080 --bind 127.0.0.1
```

3. A Quest böngészőjében: `http://localhost:8080`

---

## Ellenőrzés

Nyisd meg a `/check.html`-t a headsetben. Ha mindhárom érték zöld, az origó
alkalmas, és a `Belépés teszt` gomb valódi sessiont indít.

Megjegyzés: a `quest-mr-demo.html`-ben a `Belépés` gomb fölötti sor nem ezt a
három értéket írja ki, hanem a session-állapotot (pl. „Quest észlelve —
passthrough módban indul."). A háromtagú diagnosztikai sor a `check.html`-en van.
