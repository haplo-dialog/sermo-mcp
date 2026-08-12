# gtk3dialog-mcp

**Un compagnon de documentation pour développer avec gtk3dialog, à côté de votre
assistant IA.**

Ce petit serveur [MCP](https://modelcontextprotocol.io) donne à un assistant IA
(Claude, ou tout autre client compatible) une connaissance précise et à jour de
la syntaxe XML de **gtk3dialog** / **gtkdialog** : widgets, attributs, exemples.
Votre assistant peut alors vous aider à écrire des dialogues corrects, sans
inventer de balises.

> **Il est optionnel.** gtk3dialog fonctionne parfaitement sans. Installez ce
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
client. Exemple pour un fichier `.mcp.json` :

```json
{
  "mcpServers": {
    "gtk3dialog": {
      "command": "python3",
      "args": ["/chemin/vers/gtk3dialog-mcp/server.py"]
    }
  }
}
```

Redémarrez votre client : l'assistant dispose alors des outils ci-dessous.

## Outils fournis

| Outil | Ce qu'il donne |
|-------|----------------|
| `gtk3dialog_reference` | La référence complète de la syntaxe XML (widgets, attributs, sous-éléments). |
| `gtk3dialog_guide` | Le guide de prise en main (installation, compatibilité gtkdialog, sécurité, licences). |
| `gtk3dialog_search` | Recherche plein texte dans la documentation. |
| `gtk3dialog_example` | Un exemple complet de dialogue. |
| `gtk3dialog_how_to_report` | Comment signaler un bug ou proposer une amélioration. |

## Signaler un bug, proposer une idée

Ce compagnon ne publie rien lui-même. Pour remonter un bug ou une idée
d'amélioration, ouvrez une **issue** sur le dépôt GitLab de gtk3dialog, en
indiquant la version, un script XML minimal qui reproduit le cas, et le
comportement attendu vs observé.

## Licence

GPL-2.0-or-later — voir [COPYING](COPYING). Documentation embarquée dérivée de
la documentation publique de gtk3dialog (elle-même héritée de gtkdialog 0.8.3,
László Pere).

> *Développé avec l'assistance de Claude (Anthropic).*
