# haplo-dialog

**Créez des interfaces graphiques natives GTK3 depuis vos scripts shell.**

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
- `haplo-dialog` : XML structuré, une quarantaine de widgets, compatible gtkdialog

**Philosophie :**
- Séparation stricte structure (XML) / logique (shell)
- Sécurité — `safe_system()` exécute sans shell quand c'est possible (voir plus bas)
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
    <frame><label>Identifiants</label>
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

`<window>` `<button>` `<entry>` `<password>` `<checkbox>` `<radiobutton>`  
`<switch>` `<combobox>` `<comboboxtext>` `<list>` `<tree>` `<table>`  
`<hbox>` `<vbox>` `<frame>` `<notebook>` `<expander>` `<separator>`  
`<progressbar>` `<hscale>` `<vscale>` `<spinbutton>` `<calendar>`  
`<menubar>` `<terminal>` `<pixmap>` `<text>` `<edit>` `<statusbar>`  
`<timer>` `<infobar>` `<levelbar>` `<spinner>` `<searchentry>`  
`<drawingarea>` `<aspectframe>` `<togglebutton>` et plus…

Référence complète : le fichier `man/haplo-dialog-xml.5` du dépôt, ou la
ressource `reference-xml` de ce serveur MCP.
⚠️ `man 5 haplo-dialog-xml` ne fonctionne PAS : cette page n'est pas installée
par les paquets, elle vit seulement dans le dépôt source.

---

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
