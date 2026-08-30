# sermo-mcp

**Un compagnon de documentation pour développer avec gtk3sermo, à côté de votre
assistant IA.**

Ce petit serveur [MCP](https://modelcontextprotocol.io) donne à un assistant IA
(Claude, ou tout autre client compatible) une connaissance précise et à jour de
la syntaxe XML de **gtk3sermo** / **gtkdialog** : widgets, attributs, exemples.
Votre assistant peut alors vous aider à écrire des dialogues corrects, sans
inventer de balises.

> **Il est optionnel.** gtk3sermo fonctionne parfaitement sans. Installez ce
> compagnon seulement si vous développez avec l'aide d'une IA et souhaitez
> qu'elle connaisse le format sur le bout des doigts.

## Protection de l'utilisateur d'abord

Ce serveur est conçu pour être **inoffensif** :

- **Strictement local** : il communique par l'entrée/sortie standard (`stdio`).
  Il **n'ouvre aucun port**, ne fait **aucun accès réseau** (ni entrant ni
  sortant). Rien ne quitte votre machine.
- **Lecture seule** : il n'exécute rien, n'écrit aucun fichier, ne publie rien.
- **Contenu embarqué** : la documentation qu'il sert est incluse dans le dépôt
  et dérivée de la documentation publique du projet.

Le pire qu'il puisse faire, c'est vous donner une réponse de documentation.

## Prérequis

- Python 3 (aucune dépendance externe).

## Installation

Clonez le dépôt, puis déclarez le serveur dans la configuration MCP de votre
client :

```sh
git clone https://gitlab.com/haplo-dialog/sermo-mcp.git
```

Exemple pour un fichier `.mcp.json` :

```json
{
  "mcpServers": {
    "gtk3sermo": {
      "command": "python3",
      "args": ["/chemin/vers/sermo-mcp/server.py"]
    }
  }
}
```

Redémarrez votre client : l'assistant dispose alors des outils ci-dessous.

## Outils fournis

| Outil | Ce qu'il donne |
|-------|----------------|
| `gtk3sermo_reference` | La référence complète de la syntaxe XML (widgets, attributs, sous-éléments). |
| `gtk3sermo_guide` | Le guide de prise en main (installation, compatibilité gtkdialog, sécurité, licences). |
| `gtk3sermo_search` | Recherche plein texte dans la documentation. |
| `gtk3sermo_example` | Un exemple complet de dialogue. |
| `gtk3sermo_how_to_report` | Comment signaler un bug ou proposer une amélioration. |

## Vérifier que la documentation servie est juste

```sh
./tests/verifie-exemples.sh
```

Ce banc extrait **chaque** bout de XML de `data/guide.md` et
`data/reference-xml.txt`, et le rejoue contre `gtk3sermo` et `gtk4sermo` réels
avec `--print-ir`. Il échoue si un seul exemple n'est pas analysable.

Il existe parce que le 2026-08-30, **six** formes documentées étaient des
erreurs de syntaxe — `<frame><label>`, `<notebook><label>`,
`<expander><label>`, `<pixmap><filename>`, `<table><column-header>` — et
l'exemple phare du guide ne démarrait pas. Rien ne rejouait la documentation,
donc personne ne l'avait vu.

Codes de retour : `0` tout passe · `1` un exemple casse, **ou** rien n'a été
extrait · `77` les binaires ne sont pas installés, rien n'a été vérifié. Un
banc muet ne rend jamais 0.

## Signaler un bug, proposer une idée

Ce compagnon ne publie rien lui-même. Pour remonter un bug ou une idée
d'amélioration, ouvrez une **issue** sur le dépôt GitLab de gtk3sermo
(<https://gitlab.com/haplo-dialog/sermo/-/issues>), en
indiquant la version, un script XML minimal qui reproduit le cas, et le
comportement attendu vs observé.

## Licence

GPL-2.0-or-later — voir [COPYING](COPYING). Documentation embarquée dérivée de
la documentation publique de gtk3sermo (elle-même héritée de gtkdialog 0.8.3,
László Pere).

> *Développé avec l'assistance de Claude (Anthropic).*
