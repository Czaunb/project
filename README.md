# Quest 3 WebXR demó — HTTPS-kiszolgálás

A `index.html` a `quest-mr-demo.html` bájtra azonos másolata
(sha256 `61afb412…c35cc1`). Azért hívják `index.html`-nek, hogy a headsetben
a mappa gyökerét kelljen beírni, ne egy hosszú fájlnevet.

A `check.html` egy különálló diagnosztikai oldal, ami pontosan ezt a sort
mutatja, és egy gombbal valódi `immersive-ar` sessiont is kér próbaképpen:

```
HTTPS / biztonságos kontextus: igen · WebXR: elérhető · keretben: nem
```

## Melyiket válaszd

- **A)** működik most, a te gépedről, GitHub-beállítás nélkül — **ezzel kezdd.**
- **B)** állandó, rövid címet ad, de előbb publikussá kell tenni a repót (lásd ott).
- **C)** kábellel, tunnel nélkül, ha nem akarsz semmit kitenni a netre.

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

**Jelenleg nem működik — kipróbálva.** A workflow lefutott a push után, és
elbukott a Pages-oldal létrehozásánál:

```
Get Pages site failed.    Error: Not Found
Create Pages site failed. Error: Resource not accessible by integration
```

Futás: https://github.com/Czaunb/project/actions/runs/35401598525

Ez a repó **privát**, a GitHub Pages viszont ingyenes csomagon csak publikus
repónál érhető el. (Fizetős csomagon a privát Pages-oldal is csak
GitHub-bejelentkezés után nyílik meg — headsetben kényelmetlen.)

### Hogyan élesítsd

1. **Tedd publikussá a repót:** Settings → legalul *Danger Zone* →
   *Change repository visibility* → **Make public**.
   Ezzel a demó forrása bárki számára látható lesz.
2. Ha a fenti hiba így is jön, engedd a workflow írási jogát:
   Settings → Actions → General → *Workflow permissions* →
   **Read and write permissions**.
   Vagy kapcsold be a Pages-t kézzel: Settings → Pages → *Source:*
   **GitHub Actions** (ekkor az `enablement: true` már nem számít).
3. Indítsd újra: Actions fül → *Deploy to GitHub Pages* → **Run workflow**.
4. A cím ezután állandó:

```
https://czaunb.github.io/project/
https://czaunb.github.io/project/check.html
```

Ez a legkényelmesebb cím headsetben, mert rövid és nem változik.

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

## A két demó

| cím | mi van benne |
|---|---|
| `/` | az eredeti demó — fizika, megfogás, térbeli panel |
| `/lab` | **Szobalabor**: kézkövetés, a valódi szoba síkjai, térbeli hang |
| `/arena` | **Szakadék** — hullámok, pontszám, kombó, pajzs, generatív zene |
| `/game` | **Zárótűz** — pisztoly + pajzs, telegrafált támadások, 5 ellenféltípus |

A `lab/` a Quest 3 fejlettebb WebXR-képességeit használja, mindet
*opcionálisan*: nincs egyetlen `requiredFeature` sem, így ha valamelyik nem
érhető el, a demó attól még elindul, csak az a funkció marad ki.

- **kézkövetés** (`hand-tracking`) — csippentés a megfogáshoz, üres csippentés
  telekinézis; a gombokat ujjheggyel meg lehet bökni
- **szobasíkok** (`plane-detection`) — a `frame.detectedPlanes`-ből valódi
  ütközőfelület lesz, a tárgyak a te falaidról pattannak vissza
- **térbeli hang** — nincs hangfájl, minden koppanás a helyszínen
  szintetizálódik, és egy `PannerNode` teszi oda, ahol történt

A panel fölötti kijelző élőben mutatja a felismert síkok és tárgyak számát,
a követett kezeket és az fps-t. A belépés előtti sor pedig kiírja, melyik
képességet adta meg ténylegesen a rendszer.

## Szakadék (`/arena`)

Hullám-alapú MR-játék, ami a `/lab` alapjaira épül.

- **szakadékok a valódi falaidon** — a felismert függőleges síkokra kerülnek,
  ha nincs felismert szoba, virtuális gyűrűbe
- **kék gömb**: elkapod csippentéssel vagy ravasszal, ez a lőszer
- **piros ellenfél**: dobott gömbbel vagy gyorsan mozgó kézzel (>1,6 m/s)
  semmisíthető meg; minden 4. hullámban jön egy háromtalálatos nehéz ellenfél
- **pajzs**: három van, aki átjut, elvisz egyet
- **kombó**: szakadék nélküli sorozat, minden 5 találat után +1 szorzó
- **generatív zene**: nincs hangfájl — lábdob, basszus, pergő és arpeggio
  ütemezve a Web Audio óráján, a sűrűsége a kombóval nő
- **részecskék**: 500 pontból álló készlet, egyetlen draw call
- a legjobb eredmény `localStorage`-ban marad meg

Játéklogika ellenőrizve headless Chromiumban, a frissítőfüggvényeket
közvetlenül hajtva: fázisváltások, hullámindítás, pajzsvesztés és
játék vége, dobással és ütéssel való ölés, a lassú kéz hatástalansága,
részecske-életciklus, kombószorzó és a legjobb eredmény mentése.

## Zárótűz (`/game`)

Rendes lövölde: jobb kézben pisztoly, balban energiapajzs, és öt
viselkedésében eltérő ellenféltípus.

### Fegyver
12 lőszer, markolattal újratöltés, kifogyáskor lassabb automatikus töltés.
Rugós visszarúgás (~2,5 cm hátra, ~8° csőemelkedés), torkolattűz valódi
fényforrással, lőszerszámláló magán a szánon. A lövedék **szakasz–gömb**
teszttel ütközik, így 34 m/s-nál sem ugorja át az ellenfelet.

### Pajzs
Hatszögű energiapajzs a bal kézen. A lövedék útját a pajzs síkjával metszve
vizsgáljuk, tehát csak az számít blokknak, ami tényleg **elölről** ér át.
Az energia fogy és töltődik; nullánál a pajzs pár másodpercre leáll.

### Ellenfelek — minden támadás telegrafált
| típus | viselkedés | ellenszer |
|---|---|---|
| felderítő | gyors, rád rohan | lelőni időben |
| lövész | távolságot tart, jelez, lő | pajzs vagy kitérés |
| sorozatvető | hosszabb jelzés, három lövés | kitartott pajzs |
| páncélos | **csak nyitáskor sebezhető** | időzítés |
| bombázó | rád repül, robban | előbb lelőni |

A jelzés (felizzó mag + emelkedő hang) a játékos időablaka — ez a
tisztességes nehézség alapja, nem a véletlen.

### Játékérzet
Az iparági gyakorlatot követi, egy VR-specifikus kivétellel: **a kamerát
soha nem mozgatjuk**, mert az VR-ben rosszullétet okoz. A képernyőrázás
helyett haptika, HUD-lökés és irányjelzők mutatják, honnan jött a találat.

- találatmegállás ölésnél (50 ms — a szimuláció áll, a fejkövetés soha)
- lassítás a hullám utolsó ellenfelénél
- találatjelző, lebegő pontszám, sérülésirány-jelzők
- rétegzett hangok (tranziens + test + zaj), kompresszorral összefogva
- adaptív zene: a sűrűség a hullámot, a sorozatot és a veszélyt követi

### Teljesítmény
Teljes kései hullám terhelése alatt mérve: **21 rajzolási hívás**,
5 752 háromszög. A lövedékek `InstancedMesh`-ben vannak (160 lövedék = 2
hívás), a részecskék egyetlen `Points` objektumban (728 részecske = 1 hívás).
A képkockahurokban nincs memóriafoglalás — a pajzs energiaíve is előre
legyártott geometriákból választ.

### Ellenőrzés
30 viselkedés mérve headless Chromiumban: fegyver (lövés, tűzgyorsaság,
tár, újratöltés, visszarúgás), átugrás elleni védelem, páncélos
sérthetetlensége zárva és sebezhetősége nyitva, ellenfél jelzése és
tüzelése, pajzs blokkolása elölről / nem-blokkolása hátulról és mellette,
pajzstörés, sérthetetlenségi ablak, játék vége, hullámvezérlés, a típusok
fokozatos bevezetése, bombázó robbanása, találatmegállás, 60 mp folyamatos
játék és 10 mp teljes terhelés hiba nélkül.

## Ellenőrzés

Nyisd meg a `/check.html`-t a headsetben. Ha mindhárom érték zöld, az origó
alkalmas, és a `Belépés teszt` gomb valódi sessiont indít.

Megjegyzés: a `quest-mr-demo.html`-ben a `Belépés` gomb fölötti sor nem ezt a
három értéket írja ki, hanem a session-állapotot (pl. „Quest észlelve —
passthrough módban indul."). A háromtagú diagnosztikai sor a `check.html`-en van.
