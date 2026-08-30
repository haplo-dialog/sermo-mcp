# haplo-dialog

**Créez des interfaces graphiques natives depuis vos scripts shell.**
Deux ports lisent le même XML : `gtk3sermo` (GTK 3, port de référence) et
`gtk4sermo` (GTK 4).

```sh
export MAIN_DIALOG='
<window title="Bonjour !" width-request="320" height-request="140">
  <vbox>
    <text><label>Entrez votre nom :</label></text>
    <entry><variable>NOM</variable></entry>
    <hbox>
      <button ok></button>
      <button cancel></button>
    </hbox>
  </vbox>
</window>'

gtk3sermo --program MAIN_DIALOG
echo "Bonjour, $NOM !"
```

Ce script fonctionne **tel quel**, que vous l'appeliez avec `gtk3sermo` ou avec
`gtkdialog` : c'est le **même binaire** (voir plus bas). Les scripts écrits pour
gtkdialog tournent sans modification.

---

## Installation rapide

```sh
# Depuis les sources (seule voie disponible aujourd'hui)
cd gtk3sermo/gtk3sermo_1.1.3        # ou gtk4sermo/gtk4sermo_1.1.3
./autogen.sh && ./configure && make && sudo make install
```

⚠️ **Il n'existe pas encore de dépôt APT public** : `apt install` ne fonctionne pas.
Les paquets `.deb` se construisent depuis les sources avec `dpkg-buildpackage -b`.

**Trois paquets, et la distinction compte :**

| Paquet | Commande installée | Conflits |
|---|---|---|
| `gtk3sermo` | `gtk3sermo` | aucun |
| `gtk4sermo` | `gtk4sermo` | aucun |
| `gtksermo` | `gtkdialog` | avec tout ce qui possède `/usr/bin/gtkdialog` |

Le nom `gtkdialog` n'est **PAS** fourni par `gtk3sermo`. Il vit dans le paquet
`gtksermo`, à installer séparément — ce qui permet d'avoir `gtk3sermo` à côté d'une
autre implémentation de gtkdialog sans conflit.

---

## gtk3sermo, le successeur de gtkdialog

haplo-dialog reprend **gtkdialog 0.8.3** (László Pere, GPL-2.0+), resté sur
GTK2, et le modernise sur **GTK3** en gardant sa syntaxe XML **à l'identique**.

- **Un seul binaire, deux noms.** `gtkdialog` est un lien vers `gtk3sermo`. La
  même fenêtre, décrite une seule fois en XML, s'ouvre à l'identique par les deux
  commandes — vos anciens scripts gtkdialog fonctionnent sans y toucher.
- **Même langage XML.** Les descriptions de fenêtres gtkdialog sont lues telles
  quelles.
- **GTK3.** Rendu natif moderne, intégration GNOME et Xfce.

---

## Pourquoi haplo-dialog ?

Le shell est un langage de première classe. Il orchestre, filtre, décide — mais
délègue l'affichage. haplo-dialog est le chaînon manquant : une syntaxe XML
déclarative, un binaire à invoquer, une interface native qui s'intègre au bureau.

**Versus les alternatives :**
- `zenity` / `kdialog` : limités à quelques boîtes de dialogue figées
- `yad` : plus riche, mais syntaxe en ligne de commande difficile à maintenir
- `python3 + tkinter` : requiert Python, cassure du paradigme shell
- `haplo-dialog` : XML structuré, **55 widgets**, compatible gtkdialog

**Philosophie :**
- Séparation stricte structure (XML) / logique (shell)
- `safe_system()` exécute sans shell quand la commande n'a pas de métacaractères
  — ce n'est PAS un bac à sable, voir la section Sécurité
- Compatibilité gtkdialog — un script hérité tourne sans réécriture
- Minimalisme des dépendances à l'exécution

---

## Exemple complet — formulaire avec validation

```sh
#!/bin/sh
# Développé avec l'assistance de Claude (Anthropic).

export DIALOG='
<window title="Nouvelle connexion" width-request="400" height-request="220">
  <vbox>
    <frame Identifiants>
      <vbox>
        <hbox>
          <text><label>Utilisateur :</label></text>
          <entry><variable>USER_INPUT</variable></entry>
        </hbox>
        <hbox>
          <text><label>Mot de passe :</label></text>
          <password><variable>PASS_INPUT</variable></password>
        </hbox>
      </vbox>
    </frame>
    <hbox>
      <button ok></button>
      <button cancel></button>
    </hbox>
  </vbox>
</window>'

gtk3sermo --program DIALOG

if [ -n "$USER_INPUT" ]; then
    echo "Connexion de : $USER_INPUT"
fi
```

---

## Widgets disponibles

**Conteneurs** — `<window>` `<hbox>` `<vbox>` `<frame>` `<notebook>`
`<expander>` `<aspectframe>` `<eventbox>`

**Boutons** — `<button>` `<checkbox>` `<radiobutton>` `<togglebutton>`
`<switch>` `<linkbutton>`

**Saisie** — `<entry>` `<password>` `<searchentry>` `<edit>`

**Texte** — `<text>` `<statusbar>` `<infobar>`

**Listes** — `<combobox>` `<comboboxtext>` `<comboboxentry>` `<list>`
`<tree>` `<table>`

**Nombres** — `<hscale>` `<vscale>` `<spinbutton>` `<levelbar>`

**Progression** — `<progressbar>` `<pulse>` `<spinner>`

**Médias** — `<pixmap>` `<image>` `<drawingarea>` `<colorbutton>`
`<fontbutton>`

**Menus** — `<menubar>` `<menu>` `<menuitem>` `<menuitemseparator>`

**Fichiers** — `<filechooser>` `<chooser>`

**Divers** — `<calendar>` `<terminal>` `<timer>` `<hseparator>`
`<vseparator>` `<gvim>`

**Port GTK 4 uniquement** — `<flowbox>` `<overlay>` `<revealer>` `<stack>`

`<gvim>` est le seul cas inverse : il ne marche que dans le port GTK 3
(GtkSocket a disparu de GTK 4). Le port GTK 4 affiche une étiquette qui le
dit, il ne fait pas semblant.

Référence complète : `man 5 haplo-dialog-xml`, installée par le paquet
`gtk3sermo` — vérifié sur une machine où il est installé (`dpkg -L gtk3sermo`
liste `/usr/share/man/man5/haplo-dialog-xml.5.gz`). Aussi disponible via
l'outil `gtk3sermo_reference` de ce serveur MCP.

---

## ⚠️ Pièges de syntaxe — les formes qui ont l'air justes

Ces cinq écritures paraissent naturelles et **arrêtent le programme** avec une
erreur de syntaxe. Chaque ligne a été rejouée sur `gtk3sermo 1.1.3`.

| On écrit spontanément | Résultat | La forme qui marche |
|---|---|---|
| `<frame><label>Titre</label>` | `near token '<label>'` | `<frame Titre>` ou `<frame label="Titre">` |
| `<notebook><label>a</label>` | `near token '<label>'` | `<notebook labels="a\|b">` |
| `<expander><label>Titre</label>` | `near token '<label>'` | `<expander label="Titre">` |
| `<pixmap><filename>x.png</filename>` | `near token '<filename>'` | `<pixmap><input file>x.png</input></pixmap>` |
| `<table><column-header>c</column-header>` | `near token '<column-header>'` | `<table><label>c1\|c2</label>` |

`<expander Titre>` en positionnel échoue aussi — contrairement à `<frame>`, qui
l'accepte. Les deux ne se comportent pas pareil.

Dans `<pixmap>`, `file` est un attribut **nu**, sans valeur : le chemin est le
contenu de l'élément. Pour une icône du thème :
`<pixmap><input file stock="gtk-info"></input></pixmap>`.

**Vérifier une syntaxe sans ouvrir de fenêtre :**

```sh
MAIN_DIALOG="$(cat mon-dialogue.xml)" gtk3sermo --program=MAIN_DIALOG --print-ir
```

`--print-ir` analyse et sort. Code de retour 0 = la syntaxe passe.

---

## Options de la ligne de commande

Relevées sur `gtk3sermo --help` de la version 1.1.3.

| Option | Effet |
|---|---|
| `-p`, `--program=VAR` | lit la description dans la variable d'environnement VAR |
| `-f`, `--file=CHEMIN` | lit la description dans un fichier |
| `-s`, `--stdin` | lit la description sur l'entrée standard |
| `-g`, `--glade-xml=F` | lit un fichier Glade |
| `--do=COMMANDE` | exécute la commande **après** la fermeture du dialogue |
| `--print-ir` | analyse la syntaxe et sort, sans ouvrir de fenêtre |
| `-G`, `--geometry=…` | position et taille de la fenêtre |
| `-c`, `--center` | centre la fenêtre |
| `-v`, `--version` | numéro de version |

`--program VAR` et `--program=VAR` fonctionnent tous les deux.

### `--do` — la voie sûre pour agir sur une valeur

La sortie de `gtk3sermo` est faite de lignes `NOM="valeur"`, et la valeur vient
de la personne qui **se sert** du dialogue. La passer à `eval` lui donne le
droit d'exécuter ce qu'elle veut. `--do` exécute la commande dans le programme,
sans que le shell appelant ait à évaluer quoi que ce soit.

---

## Vérifier son installation

```sh
gtk3sermo --version        # gtk3sermo version 1.1.3 sermo …
gtk4sermo --version        # le port GTK 4, même numéro
gtkdialog --version        # même binaire que gtk3sermo (lien symbolique)
man 5 haplo-dialog-xml     # la référence XML complète
```

`gtkdialog` est un **lien symbolique** vers `gtk3sermo`, posé par le paquet
`gtksermo` — pas une copie, pas une réimplémentation. Il n'est PAS fourni par
le paquet `gtk3sermo` : c'est ce qui permet de garder `gtk3sermo` à côté d'une
autre implémentation de gtkdialog sans conflit de fichiers.

## Structure du dépôt

```
haplo-dialog/
├── README.md               ← vous êtes ici
├── CHANGELOG.md            ← historique des versions
├── AUTHORS                 ← auteurs et contributeurs
├── NEWS                    ← annonces utilisateurs
├── CONTRIBUTING.md         ← comment contribuer
├── SECURITY.md             ← politique de sécurité
├── LICENCES.md             ← résumé des licences
├── ROADMAP.md              ← feuille de route
├── gtk3sermo/             ← le port GTK 3 (port de référence)
│   └── gtk3sermo_1.1.3/
│       ├── src/            ← sources C
│       ├── examples/       ← scripts de démonstration
│       ├── doc/            ← documentation Texinfo
│       └── packaging/      ← .deb, .rpm, PKGBUILD, .ebuild
├── gtk4sermo/             ← le port GTK 4 : même syntaxe, plus <flowbox>,
│   └── gtk4sermo_1.1.3/      <overlay>, <revealer> et <stack>
└── tests/
    └── xml/                ← suite de régression XML
```

---

## Sécurité

haplo-dialog est conçu pour tourner en contexte utilisateur non privilégié.

- Les commandes passent par `safe_system()` / `safe_popen()`, qui remplacent
  `system()` / `popen()` : quand la commande **ne contient pas de métacaractères
  shell**, elle est exécutée **directement, sans shell** — ce qui évite
  l'injection shell dans ce cas courant. En présence de métacaractères, il y a
  repli sur `/bin/sh -c` (fonctionnalité shell complète) ; ce repli peut être
  **refusé** en posant la variable `HAPLO_NO_SHELL_FALLBACK`.
- ⚠️ **Il n'y a AUCUNE liste blanche de commandes par défaut.** Le filtre existe
  mais reste éteint tant que `HAPLO_ALLOWED_CMDS` n'est pas posée : sans elle,
  `_allowlist_permits()` rend `TRUE` sans rien vérifier. La poser
  (`HAPLO_ALLOWED_CMDS=cat,grep,…`) filtre sur le `basename` de `argv[0]` **et**
  refuse tout repli `/bin/sh -c`.
- La valeur d'un widget vient de la personne qui **se sert** du dialogue : ne
  jamais la passer à `eval` ni la concaténer dans une `<action>`. La voie sûre
  est `--do`.
- Binaires compilés avec : `FORTIFY_SOURCE`, PIE, Full RELRO, pile non
  exécutable (NX), stack canary — vérifiable via `checksec --file=/usr/bin/gtk3sermo`.
- ⚠️ **Un `<password>` ressort EN CLAIR sur la sortie standard.** Mesuré sur la
  1.1.3 : un dialogue avec `<password><variable>PASS_INPUT</variable></password>`
  imprime `PASS_INPUT="secret-123"`. La valeur passe donc par le tube du shell
  appelant, par son historique si elle est manipulée, et par l'environnement de
  tout processus lancé par une `<action>`. `<password>` masque la saisie **à
  l'écran**, il ne protège pas la valeur ensuite. Pour un vrai secret, préférer
  `--do` et ne jamais faire transiter la valeur par `eval`.
- Politique de sécurité complète : [SECURITY.md](SECURITY.md)
- Signalement de vulnérabilité : `devel@haplo-dialog.fr`

---

## Contribuer

Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour le workflow complet.

En bref :
1. Lire `SECURITY.md` avant toute modification du cœur
2. Respecter le style `.clang-format` et `.editorconfig` fournis
3. Tester avec `make check`
4. Un patch par fonctionnalité, message de commit en anglais

---

## Licence

| Composant | Licence |
|-----------|---------|
| Code — binaire, widgets, cœur C | GPL-2.0-or-later |
| Documentation | CC-BY-SA 4.0 |
| Exemples (`examples/`) | CC0 (domaine public) |

Hérite de **gtkdialog 0.8.3** (László Pere, GPL-2.0+) — modernisé et porté sur
GTK3.

---

## Contact

`devel@haplo-dialog.fr` · https://haplo-dialog.fr

> *Développé avec l'assistance de Claude (Anthropic).*
