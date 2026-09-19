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
| `/prizma` | **Prizma** — teljes VR műhely: járkálás, 4 zóna, pályaépítő, 4 fegyver |
| `/varos` | **Város** — nyílt világ: 952 épület, forgalom, robot járókelők, rendőrség |
| `/revolver` | **Revolver** — mechanikai tanulmány működő dupla akciós szerkezettel |

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

### Prizma (`/prizma`)

Nem játék, hanem **keretrendszer**. Teljes VR, passthrough nélkül. Egy
központi csarnok, amiből zónákba lehet átsétálni — és egy új ötlet
mindössze egy új objektum a `registerZones()` listájában.

### Mozgás — a Meta kényelmi ajánlásai szerint
- **valós tempó**: séta 1,45 m/s, futás 2,85 m/s (a túl gyors mozgás okozza a rosszullétet)
- **45°-os pattanó fordulás** rövid elsötétüléssel; a fej közben **helyben marad**
- **dinamikus vignetta** a sebesség arányában, megálláskor azonnal visszanyílik
- korlátozott gyorsulás — a rándulás a másik fő kiváltó ok

### Zónák
| zóna | tartalom |
|---|---|
| **Központ** | oszlopok élő előnézettel; a fényükbe sétálva utazol |
| **Lőtér** | 4 fegyver, fedezékek, 5 ellenféltípus |
| **Építő** | rakd le, mentsd el, és **teszteld is** a saját pályád |
| **Végtelen** | 30 000 objektum egyetlen rajzolási hívásban |

### Fegyverek
Pisztoly (pontos), Sörétes (9 szem, közelre), Géppisztoly (automata),
Sínágyú (felhúzós, átüt mindent). Váltás az A/X gombbal, a fegyveren
saját kijelző mutatja a nevet és a lőszert.

### Ellenfelek
- **Vadász** — fedezékbe húzódik, onnan tüzel
- **Pajzsos** — elöl pajzs: **csak oldalról sebezhető**, és lassan fordul,
  hogy tényleg meg lehessen kerülni (ezért kellett a járkálás)
- **Mesterlövész** — célzólézerrel jelez, sokat sebez
- **Raj** — gyors, közelharcos, sokan
- **Titán** — a teste páncélozott, csak a három gyenge pontja sebezhető

### Építő
0,5 m-es háló, 5 alakzat, 7 szín, 1200 elemig. A vezérlés **talapzatokon**
van, nem menüben: rálépsz a MENTÉS, BETÖLTÉS, TÖRLÉS, TESZT, ALAKZAT vagy
SZÍN korongra. A pálya `localStorage`-ba megy, a TESZT pedig drónokat rak
bele, hogy le is lehessen játszani.

### Teljesítmény
Rajzolási hívás zónánként, terhelés alatt (40 lövedék + 200 részecske,
a lőtéren 8 ellenféllel): **központ 56, lőtér 42, építő 11, végtelen 10.**
A végtelen 30 000 objektuma egyetlen `InstancedMesh`, a hullámzása
vertex shaderben fut, tehát a processzort nem terheli.

### Város (`/varos`)

Saját tervezésű nyílt világ. **Nem GTA-klón**: a Rockstar városa, karakterei
és márkája szerzői jogvédett, azokból semmi nincs benne — ez a saját
generátorunk saját geometriájával, saját textúráival.

### A város
968 × 968 méter, 22 × 22 blokk, **952 épület**, 126 ms alatt generálva.

- **öt kerület** a központtól kifelé: Belváros (9–26 emelet), Üzleti negyed,
  Lakónegyed, Ipari, és szórt Parkok
- **sugárutak** minden 5. utcán, szélesebb úttesttel és felfestéssel
- blokkonként 1, 2 vagy 4 telek; magas házaknál visszahúzott felső rész,
  antennával
- minden textúra kódból készül: a homlokzat ablakrácsa rajzolt canvas,
  éjszakára külön emissziós réteggel

### Technika, ami ezt lehetővé teszi
A teljes város **néhány összeolvasztott geometriába** kerül — nem külön
objektumok ezrei. A homlokzat UV-je valós méterhez skálázódik, ezért az
ablakok minden épületen egyforma méretűek. Az autók, járókelők, rendőrök,
lámpák és lövedékek mind `InstancedMesh`-ben vannak.

Eredmény teljes terhelés alatt: **19 rajzolási hívás, 80 974 háromszög.**

### Forgalom
130 autó saját sávhálón, három karosszériatípus. Tartják a követési
távolságot, lassítanak a kereszteződés előtt és ha eléd érnek. A
karosszéria fehér a geometriában, a fényezést a példányszín adja — így egy
rajzolási hívásból jön ki az összes szín.

**Bármelyikbe beszállhatsz** (markolat). A vezetés arkád fizika: gáz, fék,
tolatás, sebességfüggő kormányzás, épületütközés. VR-ben a pilótafülke
adja a rögzített viszonyítási pontot, ami a rosszullét ellen a legfontosabb.

### Robotok
150 járókelő a járdán. Közelről feléd fordulnak; lövésre **megijednek és
ellenkező irányba menekülnek**.

### Körözés és rendőrség
Civil vagy autó kilövése csillagot ad, 1-től 5-ig. Szintenként két rendőr
érkezik, akik falat kerülgetve közelítenek, jeleznek, majd tüzelnek.
Bűncselekmény nélkül a szint magától lecseng.

### Napszak
15 perces nappal–éjszaka kör: mozgó nap, alkonyi színek, csillagok,
kigyulladó ablakok és utcalámpák. A B/Y gombbal azonnal váltható.

### Második bővítés: látvány, élet, funkciók

**A legnagyobb felismerés: a város üres volt.** 130 autó szétszórva 968
méteren azt jelentette, hogy nyolc utcaszakaszonként jutott egy — 90 méteren
belül összesen 13 objektum. Ezért érződött élettelennek.

A megoldás az, amit a nyílt világú játékok is csinálnak: aki túl messzire
kerül, azt **visszatesszük a játékos köré**. Ugyanannyi objektumból így
90 méteren belül **273** lett (91 autó, 182 robot) — húszszoros sűrűség.
Mellé a létszám is nőtt: 190 autó, 260 robot.

**Látvány**
- **kontaktárnyék** minden autó, robot és rendőr alatt — ettől nem lebegnek
- **eső**: 2200 csepp, nedves és tükröző aszfalt, **villámlás** mennydörgéssel
- utcai fák, padok, tűzcsapok, kukák, **buszmegállók** a sugárutak járdáin
- **óriásplakátok** a felhőkarcolók tetején
- minden épület **más ablakmintázattal** világít éjjel (UV-eltolás)

**Élet**
- **működő jelzőlámpák** a sugárutak kereszteződéseiben: az észak-déli és a
  kelet-nyugati irány felváltva kap zöldet, sárgával a váltás előtt — és a
  forgalom tényleg megáll a piroson
- **élethű járás**: a lábak és a karok lengenek, vertex shaderben számolva,
  példányonként eltérő fázissal
- **rendőrautók** két csillagtól: üldöznek, villognak és lőnek menet közben

**Funkciók**
- **küldetések**: futár (3 pont, 52 mp), verseny (5 pont, 70 mp) és
  menekülés (rázd le a rendőrséget). Sárga jelzőoszlop mutatja a célt, a
  minitérképen nyíl vezet oda, és fizetnek érte kreditben.
- kredit, küldetés-visszaszámláló és rendőrautók a kijelzőn

Terhelés alatt mindennel bekapcsolva: **27 rajzolási hívás, 236 300
háromszög.**

Ellenőrzés: 25 viselkedés, köztük a lámpaciklus, a piroson megállás, az eső
és a nedves aszfalt, a villám, a járás-shader, a rendőrautó üldözése, a
három küldetéstípus teljesítése, bukása és kifizetése.

### Utólag javított hibák (headsetes visszajelzés után)

**A fő hiba: 180 fokkal el voltál fordítva az autóban.** A kamerák a `-Z`
tengely felé néznek, az autó eleje viszont a `+Z` (ott vannak a fényszórók).
Vezetésnél a rig forgatását az autó szögére állítottam, ezért **hátrafelé
néztél a kocsiban** — innen jött, hogy az autók hátrafelé mennek, és hogy
vezetés helyett vonszolásnak érződött. Javítva: `rig.rotation.y = head + π`.
Mérve: nézésirány · haladásirány = **1.000**.

Ugyanitt: alacsonyabb ülésmagasság (−45 cm), erősebb gyorsulás és
112 km/h végsebesség, elforduló kormány, és egy **zárt pilótafülke**
(műszerfal, A- és B-oszlop, tető, ajtók, ülés, tükrök) — ez adja a rögzített
viszonyítási pontot, ami VR-ben a rosszullét ellen a legfontosabb.

**Az autók most elütnek.** A karosszéria saját terében vizsgáljuk a
találatot: a forgalmi autó elgázol téged (sebességtől függő sebzéssel és
ellökéssel), te pedig elgázolod a járókelőket és a rendőröket.

**Falba bugolás.** Eddig csak a rig közepére volt ütközés, a fej viszont
fizikai lépésnél akár métert is eltérhet ettől — így be lehetett sétálni a
falba. Most a **valódi fejpozícióra** van ütközés, kitolással a kisebb
átfedésű tengely mentén. Kiszálláskor is szabad helyet keresünk az autó körül.

**Kezdőpozíciók.** Az autók és a járókelők eddig a (0,0,0) pontban jöttek
létre, és csak az első frissítéskor kerültek a helyükre. Most rögtön a
sávjukban, illetve a járdán indulnak.

### Látvány
Szegélykő minden blokk körül, zebra a sugárutak kereszteződéseinél, párkány
az épületek tetőélén, tetőgépészet és víztartály, **neonfeliratok** a
belvárosban és az üzleti negyedben, földszinti kirakat-fénycsíkok, autó-
fényszórók és hátsó lámpák, valamint felhők az égen. A neonok és a lámpák
a napszakkal gyulladnak ki.

Terhelés alatt: **23 rajzolási hívás, 142 042 háromszög.**

### Revolver (`/revolver`)

Egy 4 hüvelykes szervizrevolver **működő mechanikával**, valós arányokkal.
109 alkatrészből áll, ebből 17 megnevezve (az A/X gombbal kiírhatók).

### A mechanika
A ravasz a Quest kontrollerén **analóg**, és ezt használjuk ki:

- **dupla akció**: ahogy húzod, úgy emelkedik a kakas *és* fordul a dob;
  86%-os ravaszútnál a kakas elszabadul és elcsattan
- **egyszeres akció**: a bal kézzel felhúzod a kakast — a dob azonnal fordul
  egy kamrát —, és onnantól a ravasz **34%-nál** sül el, sokkal rövidebb úton
- a dob pontosan **60 fokot** fordul lövésenként, hat kamrával
- **kifordítható dob**: nyitva a szerkezet blokkolva van, ahogy a valóságban
- **kiürítő rúd**: a hüvelyek kirepülnek és a földön pattannak
- töltés kamránként, éles és kilőtt töltény külön megjelenéssel
- üres kamrán csak **kattan**

### A modell
- a **cső a felső kamra vonalában** van, nem a dob tengelyén — ez a revolver
  egyik legjellegzetesebb vonása
- hornyolt dob **átfúrt kamrákkal** (kihúzott keresztmetszet lyukakkal)
- hatágú **huzagolás** a furatban, a torkolatba nézve látszik
- szellőzött sín, alsó tok, kivonócsillag, reteszelő bevágások,
  recézett kakassarkantyú, bordázott ravasz, csavarok
- **fa markolatpanel** gyémántmetszésű kockázással — a fa erezete és a
  kockázás is kódból rajzolt textúra

### Anyagok és fény
A fém hitelességéhez **valódi környezettérkép** kell: a `RoomEnvironment`
és a `PMREMGenerator` adja a visszaverődéseket, e nélkül a kékített acél
lapos és halott. ACES filmes tónusleképezés, karcolt érdességtérkép.

### Hang
Minden hang szintetizált, és mindegyik átmegy egy **generált
teremvisszhangon** (exponenciálisan lecsengő zajból készült impulzusválasz),
hogy a lőtér tere is hallatsszon. A lövés négy rétegből áll: tranziens,
test, durranás és elhaló farok. A kakas felhúzása a klasszikus **kettős
kattanás**.

### Ellenőrzés
30 viselkedés mérve: a dupla akciós ravaszút minden szakasza, a 60 fokos
dobfordulás, a hat lövés és a száraz elsütés, az egyszeres akció rövidebb
ravaszútja, a dob kifordítása és a blokkolt szerkezet, az ürítés és töltés,
a céltalálat, és 60 mp folyamatos működés.

Javítva a tesztelés során két valódi hiba: a `THREE.Ray`-nek nincs
`intersectObject` metódusa (az a `Raycaster`-é), és a `shoot()` a torkolat
helyét a közös `_a` ideiglenes vektorban tartotta, amit a részecske- és
füstkibocsátás belül felülírt — ezért a lövés **soha nem talált**.

## Ellenőrzés
30 viselkedés mérve headless Chromiumban: városgenerálás és kerületek,
épületütközés járásnál és lövedéknél, forgalom mozgása és sávtartása
(130/130 az úton maradt), járókelők sétája és menekülése, mind a négy
fegyver, találat civilen, körözés emelkedése és lecsengése, rendőr
közeledése és tüzelése, beszállás–vezetés–kiszállás, sebességkorlát,
nappal–éjszaka váltás, rajzolási hívások és 60 mp folyamatos futás.

## Ellenőrzés
34 viselkedés mérve headless Chromiumban: kézhozzárendelés, zónák,
járás iránya és tempója, vignetta be- és kikapcsolása, 45°-os fordulás
**fejelmozdulás nélkül** (0,00000 m), mind a négy fegyver tüzelése és
lőszerfogyása, a sörétes 9 szeme, üres tár, pajzsos szemből/oldalról,
korlátozott fordulási sebesség, boss páncélja és gyenge pontjai,
mesterlövész jelzése, blokk lerakása/törlése, mentés–betöltés körbe
(alakzattal és színnel), teszt drón lelövése, 30 000 objektum,
rajzolási hívások és 60 mp folyamatos futás hiba nélkül.

Javítva közben: a `lookAt` a three.js-ben a **+Z** tengelyt fordítja a
célpontra, nem a −Z-t. Emiatt a pajzsos lemeze és a boss gyenge pontjai
is a hátoldalra kerültek — vagyis a bosst nem lehetett volna megölni.

### Utólag javított fő hiba: a fejpozíció és a rig

Az első headsetes próbán szinte semmi nem működött: rossz irányba vitt a
kar, nem lehetett átlépni a zónák közt, és a bal kéz nem látszott.

Egyetlen ok állt a háromból kettő mögött. A `renderer.xr.getCamera()`
által adott kamera **nincs benne a jelenetgráfban** — nincs szülője —,
ezért a `getWorldPosition()` a lokális mátrixát adja vissza világmátrixként,
és így **kihagyja a rig-et**, amiben a játékos ül. A fej pozíciója és
iránya nem világkoordinátában érkezett, hanem a righez képest.

Emiatt az „előre" a rig kezdeti állásához tapadt (nem oda, amerre nézel),
és az oszlopoktól mért távolság is rossz koordinátákból jött, tehát az
átlépés sosem indult el. A korábbi demókban ez nem derült ki, mert ott
nem volt rig — a kamera közvetlenül a világban ült.

A javítás a fejpózt közvetlenül az XR képkockából veszi
(`frame.getViewerPose`), és megszorozza a rig világmátrixával.

A bal kéz azért tűnt el, mert a központban nincs eszköz a kézben, és
semmilyen modell nem volt rajta. Most mindkét kontrolleren van látható
modell, a fegyveresen célzósugárral.

A regressziós teszt, ami elkapta volna: **eltolt és elfordított riggel**
mérni a fejpozíciót és a mozgásirányt. A korábbi 34 teszt mind nullára
állított riggel futott, ezért egyik sem fogta meg.

## Ellenőrzés
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
