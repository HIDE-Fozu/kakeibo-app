# App Store Connect ストア掲載文 下書き — 経理の家計簿 v2.0.0（9ロケール）

作成日: 2026-07-22（feature/i18n・v2.0.0+16 のリポジトリ実装を確認して作成）

## 0. 使い方（貼り付け先と前提）

**前提（このアプリ固有）**

- ASC 上のアプリは既に「**経理の家計簿**」（Bundle ID `com.hidefozu.kakeibo`・永久固定）として作成済み。
  **主要言語=日本語・ja のアプリ名は変更不要**（本書の ja 欄は現状確認＋予備の代替案）。
- 端末ホーム画面の名前は CFBundleDisplayName「家計簿」で、ストア名とは別物（意図した設計）。
- 他8ロケールは、この既存アプリに**ローカリゼーションを追加**する作業。新規アプリ登録ではない。

**どの欄に貼るか（ASC の場所）**

| 本書の項目 | ASC の場所 | 制限 | 変更タイミング |
|---|---|---|---|
| アプリ名 | App 情報 → ローカライズ可能な情報（ロケール別） | 30文字 | 新バージョン提出時のみ |
| サブタイトル | 同上 | 30文字 | 新バージョン提出時のみ |
| プロモーションテキスト | バージョンページ（ロケール別） | 170文字 | **いつでも（審査不要）** |
| 説明 | 同上 | 4000文字 | 新バージョン提出時 |
| キーワード | 同上 | 100文字 | 新バージョン提出時のみ |
| 新機能（What's New） | 同上「このバージョンの新機能」 | 4000文字 | バージョンごと |

**文字数の数え方**: Apple は全角・半角を問わず 1文字=1 で数える（CJKも同じ）。本書の各項目に
「実測n/上限」を併記済み（プログラムで len() 実測）。

**アプリ名の一意性リスク**

- アプリ名はストア全体で一意。**ローカライズ名も**他アプリの名前と衝突すると保存・審査で弾かれる。
- 単独「Kakeibo」「家计簿」「가계부」はほぼ確実に取得済みのため、全ロケールで補語付きを第1案にした。
  第1案が弾かれたら代替案1→2の順に試す。
- ja は登録済みの「経理の家計簿」をそのまま使うので一意性の懸念なし。

**その他の注意**

- キーワードは**カンマ区切り・スペースなし**で貼る。アプリ名・サブタイトルの語は自動でインデックス
  されるため、キーワード欄では重複させていない（第1案の名前を基準に作成。代替案を採用した場合は
  重複チェックを再度）。
- スクリーンショットを設定しないロケールには主要言語（日本語）のものが表示される。まずは流用で可。
- OCR・消費税・万表示は**通貨がJPYのときのみ**有効のため、非日本語の説明文では主要訴求にせず
  「日本向けの追加機能（JPY設定時のみ）」として末尾に記載してある。
- pt はブラジルポルトガル語（ASC「ポルトガル語（ブラジル）」）を想定した文体。
- zh-Hans は簡体字（ASC「簡体字中国語」）。

## 1. 日本語（ja）— 主要言語

> ASC 上のアプリ名は既に「経理の家計簿」で登録済み（変更不要）。代替案は将来名前を変えたくなった場合の予備。

### アプリ名（30文字以内）

- **第1案**: `経理の家計簿`（6/30） — ASC 登録済みの正式名。**このまま変更しない**
- **代替案1**: `経理の家計簿 - かんたん記帳`（15/30） — 予備（改名する場合のみ）
- **代替案2**: `経理の家計簿 - レシート記帳`（15/30） — 予備（改名する場合のみ）

### サブタイトル（30文字以内）

`レシート読取・内訳・消費税もかんたん`（18/30）

### プロモーションテキスト（170文字以内）

Ver 2.0で9言語・16通貨に対応しました。日本語のほか英語・中国語・韓国語・欧州5言語で使え、ドルやユーロでは小数の金額も入力できます。円でのご利用はこれまで通り、レシート読取・消費税8/10%・万表示もそのままです。

（112/170）

### 説明（4000文字以内）

```
レシートを撮って、確認して、保存。カレンダーから今日の支出をすぐ記録できる、シンプルな家計簿アプリです。データはすべて端末の中。アカウント登録は不要で、毎日の記帳に集中できます。

■ 入力がはやい
・電卓型キーで金額をそのまま入力（計算しながらの入力にも対応）
・レシートをカメラで読み取り、金額・日付・店舗名を自動入力。確認画面で直してから保存
・1枚のレシートを品目ごとに分ける「内訳入力」。残りの金額は自動計算
・行をまとめて選んでカテゴリを塗り分ける一括割当

■ 消費税に強い
・内税/外税、8%/10%を品目ごとに切り替え
・食費→8%、外食→10%などカテゴリに応じた自動税率

■ 見返しやすい
・カレンダーで日ごとの記録をひと目で確認
・月ごとのサマリで収入・支出・差引とカテゴリ別支出を表示。子カテゴリの内訳も開ける
・大きな金額は「万」表示で読みやすく

■ カテゴリは自分流に
・絵文字アイコン付き。追加・改名・並べ替え・アーカイブ
・「食費の中の外食」のような親子カテゴリに対応

■ データはあなたのもの
・記録は端末内にのみ保存。自動で外部送信されません
・端末内に自動バックアップ。JSONエクスポート（パスフレーズ暗号化対応）とCSVエクスポート、復元
・背景色やアクセント色のカスタマイズ

Ver 2.0より9言語・16通貨に対応しました。※レシート読み取りと消費税機能は、通貨が日本円（JPY）のときに利用できます。
```

（629/4000）

### キーワード（100文字以内・カンマ区切り）

`家計,節約,貯金,支出,収入,予算,お金,管理,カレンダー,記帳,袋分け,出納帳,小遣い帳,主婦,経費,マネー,オフライン`（61/100）

## 2. 英語（en / English (U.S.)）

### アプリ名（30文字以内）

- **第1案**: `Kakeibo – Household Budget`（26/30）



- **代替案1**: `Kakeibo: Simple Budget Book`（27/30）
- **代替案2**: `Kakeibo Expense Diary`（21/30）

### サブタイトル（30文字以内）

`Simple daily expense tracker`（28/30）

### プロモーションテキスト（170文字以内）

Version 2.0 speaks 9 languages and supports 16 currencies — USD, EUR, GBP and more, with decimal amounts. Same calm, calendar-first way to keep your spending in view.

（166/170）

### 説明（4000文字以内）

```
Kakeibo is the Japanese art of keeping a household ledger: write down what you spend, see where it goes, and stay mindful of your money. This app brings that calm, paper-like routine to your phone — no account, no cloud, no clutter.

FAST ENTRY
• Calculator-style keypad — type an amount and save in seconds
• Split one receipt into line items; the remainder is calculated automatically
• Notes and store names on every entry

CLEAR OVERVIEW
• Calendar view shows each day's entries at a glance
• Monthly summary with income, expenses and balance
• Spending by category, with drill-down into subcategories

YOUR CATEGORIES
• Preset categories in your language, with emoji icons
• Add, rename, reorder and archive; subcategories supported (e.g. Dining out under Food)

YOUR DATA STAYS YOURS
• Everything is stored on your device — nothing is sent to a server
• Automatic on-device backups, JSON export (optional passphrase encryption) and CSV export
• Restore your data anytime

AND MORE
• 16 currencies (USD, EUR, GBP, JPY, KRW and more) with decimal amounts
• 9 languages
• Customizable background and accent colors
• Japan extras: receipt scanning and consumption-tax handling are available when the currency is set to Japanese yen (JPY)

Note: to keep your history consistent, the currency can't be changed after your first entry — pick it once in Settings.
```

（1360/4000）

### キーワード（100文字以内・カンマ区切り）

`money,spending,saving,finance,ledger,diary,journal,receipt,calendar,offline,cash,bookkeeping`（92/100）

## 3. 簡体字中国語（zh-Hans / Chinese (Simplified)）

### アプリ名（30文字以内）

- **第1案**: `家计簿-简单记账`（8/30）
- **代替案1**: `家计簿·日式记账本`（9/30）
- **代替案2**: `Kakeibo家计簿`（10/30）

### サブタイトル（30文字以内）

`轻松记录每天开销与收入`（11/30）

### プロモーションテキスト（170文字以内）

2.0 版新增 9 种语言和 16 种货币（人民币、美元、欧元等），金额支持小数输入。像手写家计簿一样，安静地记下每一笔。

（61/170）

### 説明（4000文字以内）

```
家计簿（Kakeibo）源自日本的手写记账传统：把每天的开销写下来，看清钱花在哪里。这款应用把这种安静、专注的记账方式带到手机上——无需注册，数据只保存在你的设备里。

【快速记账】
• 计算器式键盘，输入金额几秒完成
• 一张小票可拆分成多个项目，剩余金额自动计算
• 每笔可加备注和店铺名

【一目了然】
• 日历视图查看每天的记录
• 月度汇总：收入、支出、结余
• 按分类统计支出，可展开查看子分类

【自由的分类】
• 内置分类以你的语言显示，带表情图标
• 支持添加、重命名、排序、归档；支持父子分类（如“外出就餐”归入“食品”）

【数据属于你】
• 所有记录仅保存在设备本地，不会上传服务器
• 设备内自动备份；JSON 导出（可选密码加密）与 CSV 导出，随时恢复
• 可自定义背景色与主题色

【更多】
• 支持 16 种货币（人民币、美元、欧元、日元等），金额可含小数
• 支持 9 种语言
• 面向日本用户的小票扫描、消费税功能，在货币设为日元（JPY）时可用

提示：为保证历史数据一致，记账后货币不可更改，请在开始前于设置中选择。
```

（480/4000）

### キーワード（100文字以内・カンマ区切り）

`存钱,省钱,理财,预算,账本,流水,消费,开支,日历,家庭,手账,工资,离线`（38/100）

## 4. 韓国語（ko / Korean）

### アプリ名（30文字以内）

- **第1案**: `심플 가계부 Kakeibo`（14/30）
- **代替案1**: `가계부 - 카케이보`（10/30）
- **代替案2**: `카케이보: 달력 가계부`（12/30）

### サブタイトル（30文字以内）

`달력으로 쉽게 쓰는 지출·수입 기록`（19/30）

### プロモーションテキスト（170文字以内）

2.0 버전부터 9개 언어와 16개 통화(원·달러·유로 등)를 지원하고, 소수점 금액도 입력할 수 있습니다. 종이 가계부처럼 차분하게, 매일의 소비를 기록하세요.

（90/170）

### 説明（4000文字以内）

```
가계부(Kakeibo)는 하루하루의 소비를 손으로 적어 돈의 흐름을 살피는 일본의 기록 습관에서 왔습니다. 이 앱은 그 차분한 습관을 스마트폰으로 옮겼습니다. 회원가입 없이, 데이터는 내 기기 안에만 저장됩니다.

■ 빠른 입력
• 계산기식 키패드로 금액을 바로 입력
• 영수증 하나를 여러 품목으로 나누는 분할 입력, 남은 금액은 자동 계산
• 기록마다 메모와 상호명 추가 가능

■ 한눈에 보기
• 달력에서 날짜별 기록 확인
• 월별 요약: 수입·지출·잔액
• 카테고리별 지출 통계와 하위 카테고리 상세 보기

■ 나만의 카테고리
• 내 언어로 표시되는 기본 카테고리와 이모지 아이콘
• 추가·이름 변경·순서 변경·보관 지원, 상하위 카테고리 지원(예: 식비 아래 외식)

■ 데이터는 내 것
• 모든 기록은 기기 안에만 저장되며 서버로 전송되지 않습니다
• 기기 내 자동 백업, JSON 내보내기(암호 설정 가능)와 CSV 내보내기, 언제든 복원
• 배경색·포인트 색상 변경 가능

■ 더 보기
• 원화·달러·유로 등 16개 통화, 소수점 금액 입력 지원
• 9개 언어 지원
• 일본 사용자용 영수증 스캔·소비세 기능은 통화를 엔화(JPY)로 설정했을 때 사용할 수 있습니다

참고: 기록의 일관성을 위해 첫 기록 후에는 통화를 변경할 수 없습니다. 시작 전에 설정에서 선택해 주세요.
```

（666/4000）

### キーワード（100文字以内・カンマ区切り）

`돈관리,절약,저축,예산,용돈기입장,장부,소비,영수증,가계,머니,오프라인`（39/100）

## 5. スペイン語（es / Spanish (Spain)）

### アプリ名（30文字以内）

- **第1案**: `Kakeibo – Control de gastos`（27/30）
- **代替案1**: `Kakeibo: Diario de gastos`（25/30）
- **代替案2**: `Kakeibo, tu libreta de gastos`（29/30）

### サブタイトル（30文字以内）

`El método japonés de ahorro`（27/30）

### プロモーションテキスト（170文字以内）

La versión 2.0 habla 9 idiomas y admite 16 monedas (euro, dólar, libra…) con importes decimales. La misma forma serena de apuntar tus gastos, día a día.

（152/170）

### 説明（4000文字以内）

```
El kakeibo es el método japonés de apuntar los gastos a mano para ser consciente de en qué se va el dinero. Esta app traslada ese hábito sereno a tu móvil: sin registro, sin nube, con tus datos guardados solo en tu dispositivo.

APUNTA EN SEGUNDOS
• Teclado tipo calculadora para introducir importes al momento
• Divide un ticket en varias líneas; el resto se calcula solo
• Añade notas y el nombre de la tienda a cada apunte

TODO A LA VISTA
• Calendario con los apuntes de cada día
• Resumen mensual: ingresos, gastos y saldo
• Gasto por categorías, con detalle por subcategorías

TUS CATEGORÍAS
• Categorías predefinidas en tu idioma, con iconos emoji
• Añade, renombra, reordena y archiva; admite subcategorías (p. ej., Restaurantes dentro de Alimentación)

TUS DATOS SON TUYOS
• Todo se guarda en tu dispositivo; nada se envía a servidores
• Copias de seguridad automáticas en el dispositivo, exportación JSON (cifrado opcional) y CSV
• Restaura tus datos cuando quieras

Y ADEMÁS
• 16 monedas (euro, dólar, libra, yen…) con importes decimales
• 9 idiomas
• Colores de fondo y de acento personalizables
• Extras para Japón: el escaneo de tickets y el impuesto al consumo japonés solo están disponibles con la moneda en yenes (JPY)

Nota: para mantener la coherencia del historial, la moneda no puede cambiarse tras el primer apunte; elígela al empezar en Ajustes.
```

（1368/4000）

### キーワード（100文字以内・カンマ区切り）

`dinero,presupuesto,finanzas,cuentas,diario,calendario,ingresos,libreta,contabilidad,recibos,hucha`（97/100）

## 6. フランス語（fr / French）

### アプリ名（30文字以内）

- **第1案**: `Kakeibo – Budget & dépenses`（27/30）
- **代替案1**: `Kakeibo : carnet de dépenses`（28/30）
- **代替案2**: `Kakeibo – Carnet de comptes`（27/30）

### サブタイトル（30文字以内）

`Vos comptes, jour après jour`（28/30）

### プロモーションテキスト（170文字以内）

La version 2.0 parle 9 langues et gère 16 devises (euro, dollar, livre…) avec montants décimaux. La même façon sereine de noter vos dépenses au quotidien.

（154/170）

### 説明（4000文字以内）

```
Le kakeibo, c'est l'art japonais de tenir son carnet de comptes : noter ses dépenses à la main pour reprendre la main sur son argent. Cette app transpose ce rituel apaisant sur votre téléphone : sans compte, sans cloud, vos données restent sur votre appareil.

SAISIE RAPIDE
• Pavé façon calculatrice : saisissez un montant en quelques secondes
• Détaillez un ticket en plusieurs lignes ; le reste est calculé automatiquement
• Ajoutez une note et le nom du magasin à chaque écriture

VUE D'ENSEMBLE
• Calendrier avec les écritures de chaque jour
• Synthèse mensuelle : revenus, dépenses, solde
• Dépenses par catégorie, avec le détail des sous-catégories

VOS CATÉGORIES
• Catégories prédéfinies dans votre langue, avec émojis
• Ajout, renommage, réorganisation, archivage ; sous-catégories prises en charge (ex. Restaurants dans Alimentation)

VOS DONNÉES VOUS APPARTIENNENT
• Tout est stocké sur votre appareil, rien n'est envoyé sur un serveur
• Sauvegardes automatiques sur l'appareil, export JSON (chiffrement facultatif) et CSV
• Restauration à tout moment

ET AUSSI
• 16 devises (euro, dollar, livre, yen…) avec montants décimaux
• 9 langues
• Couleurs de fond et d'accent personnalisables
• Spécifique au Japon : le scan de tickets et la taxe japonaise ne sont disponibles qu'avec la devise en yens (JPY)

À savoir : pour préserver la cohérence de l'historique, la devise ne peut plus être modifiée après la première écriture ; choisissez-la au départ dans les réglages.
```

（1479/4000）

### キーワード（100文字以内・カンマ区切り）

`argent,épargne,économies,finances,carnet,journal,calendrier,reçu,suivi,portefeuille`（83/100）

## 7. ドイツ語（de / German）

### アプリ名（30文字以内）

- **第1案**: `Kakeibo – Haushaltsbuch`（23/30）
- **代替案1**: `Kakeibo: Ausgaben-Tagebuch`（26/30）
- **代替案2**: `Kakeibo Haushaltsbuch & Budget`（30/30）

### サブタイトル（30文字以内）

`Ausgaben einfach im Blick`（25/30）

### プロモーションテキスト（170文字以内）

Version 2.0 spricht 9 Sprachen und unterstützt 16 Währungen (Euro, Dollar, Pfund u. a.) mit Dezimalbeträgen. Dasselbe ruhige Haushaltsbuch wie bisher.

（150/170）

### 説明（4000文字以内）

```
Kakeibo ist die japanische Kunst des Haushaltsbuchs: Ausgaben von Hand notieren, den Überblick behalten, bewusster mit Geld umgehen. Diese App bringt dieses ruhige Ritual aufs Smartphone – ohne Konto, ohne Cloud, alle Daten bleiben auf deinem Gerät.

SCHNELL ERFASST
• Rechner-Tastatur: Betrag eintippen, speichern, fertig
• Einen Kassenbon in Positionen aufteilen – der Rest wird automatisch berechnet
• Notiz und Geschäftsname zu jedem Eintrag

ALLES IM BLICK
• Kalenderansicht mit den Einträgen jedes Tages
• Monatsübersicht: Einnahmen, Ausgaben, Saldo
• Ausgaben nach Kategorien, mit Unterkategorien im Detail

DEINE KATEGORIEN
• Vorlagen in deiner Sprache, mit Emoji-Symbolen
• Hinzufügen, Umbenennen, Sortieren, Archivieren; Unterkategorien möglich (z. B. Restaurant unter Lebensmittel)

DEINE DATEN GEHÖREN DIR
• Alles wird nur auf dem Gerät gespeichert, nichts an Server gesendet
• Automatische Backups auf dem Gerät, JSON-Export (optional verschlüsselt) und CSV-Export
• Wiederherstellung jederzeit möglich

AUSSERDEM
• 16 Währungen (Euro, Dollar, Pfund, Yen …) mit Dezimalbeträgen
• 9 Sprachen
• Hintergrund- und Akzentfarbe anpassbar
• Japan-Extras: Bon-Scan und japanische Verbrauchssteuer sind nur bei Währung Yen (JPY) verfügbar

Hinweis: Damit dein Verlauf konsistent bleibt, lässt sich die Währung nach dem ersten Eintrag nicht mehr ändern – wähle sie zu Beginn in den Einstellungen.
```

（1399/4000）

### キーワード（100文字以内・カンマ区切り）

`geld,sparen,budget,finanzen,kassenbuch,kalender,quittung,einnahmen,übersicht,offline`（84/100）

## 8. イタリア語（it / Italian）

### アプリ名（30文字以内）

- **第1案**: `Kakeibo – Gestione spese`（24/30）
- **代替案1**: `Kakeibo: diario delle spese`（27/30）
- **代替案2**: `Kakeibo – Conti di casa`（23/30）

### サブタイトル（30文字以内）

`Entrate e uscite, ogni giorno`（29/30）

### プロモーションテキスト（170文字以内）

La versione 2.0 parla 9 lingue e supporta 16 valute (euro, dollaro, sterlina…) con importi decimali. Lo stesso modo calmo di annotare le spese, ogni giorno.

（156/170）

### 説明（4000文字以内）

```
Il kakeibo è l'arte giapponese del libro dei conti di casa: annotare le spese a mano per capire dove vanno i soldi. Questa app porta quel rituale calmo sul telefono: niente account, niente cloud, i dati restano solo sul tuo dispositivo.

REGISTRA IN UN ATTIMO
• Tastierino stile calcolatrice: digiti l'importo e salvi in pochi secondi
• Suddividi uno scontrino in più voci; il resto si calcola da solo
• Nota e nome del negozio per ogni registrazione

TUTTO SOTT'OCCHIO
• Calendario con le registrazioni di ogni giorno
• Riepilogo mensile: entrate, uscite e saldo
• Spese per categoria, con dettaglio delle sottocategorie

LE TUE CATEGORIE
• Categorie predefinite nella tua lingua, con icone emoji
• Aggiungi, rinomina, riordina e archivia; sottocategorie supportate (es. Ristoranti dentro Alimentari)

I DATI SONO TUOI
• Tutto resta sul dispositivo: nulla viene inviato a server
• Backup automatici sul dispositivo, esportazione JSON (cifratura facoltativa) e CSV
• Ripristino in qualsiasi momento

E INOLTRE
• 16 valute (euro, dollaro, sterlina, yen…) con importi decimali
• 9 lingue
• Colori di sfondo e accento personalizzabili
• Extra per il Giappone: scansione scontrini e imposta sui consumi giapponese disponibili solo con valuta in yen (JPY)

Nota: per mantenere coerente lo storico, la valuta non può essere cambiata dopo la prima registrazione; sceglila all'inizio nelle impostazioni.
```

（1395/4000）

### キーワード（100文字以内・カンマ区切り）

`soldi,risparmio,bilancio,budget,contabilità,calendario,scontrino,denaro,portafoglio,offline`（91/100）

## 9. ポルトガル語（pt / Portuguese (Brazil) 想定・pt-BR 文体）

> ASC のロケールは「ポルトガル語（ブラジル）」を選ぶ想定。ポルトガル本国向け（pt-PT）を追加する場合は要別調整。

### アプリ名（30文字以内）

- **第1案**: `Kakeibo – Controle de gastos`（28/30）
- **代替案1**: `Kakeibo: Diário de gastos`（25/30）
- **代替案2**: `Kakeibo – Caderno de contas`（27/30）

### サブタイトル（30文字以内）

`O jeito japonês de economizar`（29/30）

### プロモーションテキスト（170文字以内）

A versão 2.0 fala 9 idiomas e aceita 16 moedas (real, dólar, euro…) com valores decimais. O mesmo jeito tranquilo de anotar seus gastos, dia após dia.

（150/170）

### 説明（4000文字以内）

```
Kakeibo é a arte japonesa do caderno de contas: anotar os gastos à mão para enxergar para onde vai o dinheiro. Este app traz esse hábito tranquilo para o celular: sem cadastro, sem nuvem, com os dados guardados só no seu aparelho.

ANOTE EM SEGUNDOS
• Teclado estilo calculadora: digite o valor e salve na hora
• Divida uma nota em vários itens; o restante é calculado automaticamente
• Observações e nome da loja em cada lançamento

TUDO À VISTA
• Calendário com os lançamentos de cada dia
• Resumo mensal: receitas, despesas e saldo
• Gastos por categoria, com detalhes por subcategoria

SUAS CATEGORIAS
• Categorias predefinidas no seu idioma, com ícones emoji
• Adicione, renomeie, reordene e arquive; subcategorias incluídas (ex.: Restaurantes dentro de Alimentação)

SEUS DADOS SÃO SEUS
• Tudo fica no seu aparelho; nada é enviado a servidores
• Backup automático no aparelho, exportação JSON (criptografia opcional) e CSV
• Restaure quando quiser

E MAIS
• 16 moedas (real, dólar, euro, iene…) com valores decimais
• 9 idiomas
• Cores de fundo e destaque personalizáveis
• Extras para o Japão: leitura de notas fiscais e imposto de consumo japonês disponíveis apenas com a moeda em ienes (JPY)

Observação: para manter o histórico consistente, a moeda não pode ser trocada após o primeiro lançamento; escolha nos Ajustes ao começar.
```

（1339/4000）

### キーワード（100文字以内・カンマ区切り）

`dinheiro,poupança,orçamento,finanças,despesas,caderneta,calendário,recibo,carteira,offline`（90/100）

## 10. 新機能（What's New）— このバージョンの内容 2.0.0

バージョンページの「このバージョンの新機能」欄に貼る（各4000文字以内）。

### ja

```
Ver 2.0.0
・9言語に対応しました（日本語・英語・簡体字中国語・韓国語・スペイン語・フランス語・ドイツ語・イタリア語・ポルトガル語）
・多通貨に対応しました（ドル・ユーロなど16通貨。小数の金額入力に対応）
・カテゴリ名を端末の言語で表示するようにしました
・日本円でのご利用はこれまで通りです（レシート読取・消費税8/10%・万表示）
```

（172/4000）

### en

```
Version 2.0.0
• Now available in 9 languages: Japanese, English, Simplified Chinese, Korean, Spanish, French, German, Italian and Portuguese
• Multi-currency support: 16 currencies including USD, EUR and GBP, with decimal amounts
• Preset categories now appear in your language
• JPY users: everything works as before, including receipt scanning and 8/10% tax
```

（359/4000）

### zh-Hans

```
2.0.0 版本
• 新增 9 种语言：日语、英语、简体中文、韩语、西班牙语、法语、德语、意大利语、葡萄牙语
• 新增多货币支持：人民币、美元、欧元等 16 种货币，金额支持小数
• 内置分类现以系统语言显示
• 使用日元的用户：功能与之前完全一致（含小票扫描与 8/10% 消费税）
```

（142/4000）

### ko

```
버전 2.0.0
• 9개 언어 지원: 일본어, 영어, 중국어(간체), 한국어, 스페인어, 프랑스어, 독일어, 이탈리아어, 포르투갈어
• 다중 통화 지원: 원화·달러·유로 등 16개 통화, 소수점 금액 입력
• 기본 카테고리가 기기 언어로 표시됩니다
• 엔화(JPY) 사용자: 영수증 스캔과 8/10% 소비세 등 기존 기능 그대로
```

（183/4000）

### es

```
Versión 2.0.0
• Ahora en 9 idiomas: japonés, inglés, chino simplificado, coreano, español, francés, alemán, italiano y portugués
• Compatibilidad con 16 monedas (euro, dólar, libra, etc.) e importes decimales
• Las categorías predefinidas se muestran en tu idioma
• Con la moneda en yenes, todo funciona igual que antes (incluido el escaneo de tickets)
```

（352/4000）

### fr

```
Version 2.0.0
• Désormais en 9 langues : japonais, anglais, chinois simplifié, coréen, espagnol, français, allemand, italien, portugais
• Prise en charge de 16 devises (euro, dollar, livre…) avec montants décimaux
• Les catégories prédéfinies s'affichent dans votre langue
• Avec la devise en yens, tout fonctionne comme avant (scan de tickets inclus)
```

（351/4000）

### de

```
Version 2.0.0
• Jetzt in 9 Sprachen: Japanisch, Englisch, vereinfachtes Chinesisch, Koreanisch, Spanisch, Französisch, Deutsch, Italienisch, Portugiesisch
• Unterstützung für 16 Währungen (Euro, Dollar, Pfund u. a.) mit Dezimalbeträgen
• Kategorien-Vorlagen erscheinen jetzt in deiner Sprache
• Mit Währung Yen funktioniert alles wie bisher (inklusive Bon-Scan)
```

（361/4000）

### it

```
Versione 2.0.0
• Ora in 9 lingue: giapponese, inglese, cinese semplificato, coreano, spagnolo, francese, tedesco, italiano, portoghese
• Supporto per 16 valute (euro, dollaro, sterlina…) con importi decimali
• Le categorie predefinite ora appaiono nella tua lingua
• Con la valuta in yen tutto funziona come prima (scansione scontrini inclusa)
```

（343/4000）

### pt

```
Versão 2.0.0
• Agora em 9 idiomas: japonês, inglês, chinês simplificado, coreano, espanhol, francês, alemão, italiano e português
• Suporte a 16 moedas (real, dólar, euro etc.) com valores decimais
• As categorias predefinidas agora aparecem no seu idioma
• Com a moeda em ienes, tudo funciona como antes (incluindo a leitura de notas)
```

（335/4000）

