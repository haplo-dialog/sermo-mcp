#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
# gtk3sermo-mcp — serveur MCP LOCAL (stdio) exposant la documentation publique
# de gtk3sermo / gtkdialog à un assistant IA.
#
# Principes (ADR-0015, niveau 1) :
#   - transport stdio uniquement : aucun port, aucun accès réseau (entrant ni
#     sortant) ;
#   - LECTURE SEULE : n'exécute rien, n'écrit rien, ne publie rien ;
#   - contenu 100 % embarqué, dérivé de la documentation publique du projet.
# Sans dépendance : uniquement la bibliothèque standard Python.

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data")


def _load(name):
    try:
        with open(os.path.join(DATA, name), encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


REFERENCE = _load("reference-xml.txt")
GUIDE = _load("guide.md")
EXAMPLE = _load(os.path.join("examples", "formulaire.xml"))

REPORT = (
    "Pour signaler un bug ou proposer une amélioration de gtk3sermo, ouvrez une "
    "« issue » sur le dépôt GitLab du projet :\n"
    "  https://gitlab.com/haplo-dialog/gtk3sermo/-/issues\n"
    "Décrivez :\n"
    "  1. la version (sortie de `gtk3sermo --version`) ;\n"
    "  2. le script XML minimal qui reproduit le problème ;\n"
    "  3. le comportement attendu et le comportement observé.\n"
    "Ce serveur ne publie rien lui-même : il vous aide seulement à préparer un "
    "signalement clair."
)

TOOLS = [
    {
        "name": "gtk3sermo_reference",
        "description": "Référence complète de la syntaxe XML de gtk3sermo / "
                       "gtkdialog (widgets, attributs communs, sous-éléments).",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "gtk3sermo_guide",
        "description": "Guide de prise en main : installation, compatibilité "
                       "gtkdialog, exemples, sécurité, licences.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "gtk3sermo_search",
        "description": "Recherche plein texte dans la documentation (référence + "
                       "guide). Renvoie les passages pertinents avec leur contexte.",
        "inputSchema": {
            "type": "object",
            "properties": {"query": {"type": "string",
                                     "description": "terme ou widget à rechercher"}},
            "required": ["query"],
        },
    },
    {
        "name": "gtk3sermo_example",
        "description": "Un exemple complet et fonctionnel de dialogue "
                       "(formulaire de saisie).",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "gtk3sermo_how_to_report",
        "description": "Comment signaler un bug ou proposer une amélioration "
                       "(via les issues GitLab du projet).",
        "inputSchema": {"type": "object", "properties": {}},
    },
]


def _search(query):
    q = query.lower().strip()
    if not q:
        return "Indiquez un terme à rechercher."
    hits = []
    for label, text in (("référence", REFERENCE), ("guide", GUIDE)):
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if q in line.lower():
                ctx = "\n".join(lines[max(0, i - 2):i + 3])
                hits.append("[%s]\n%s" % (label, ctx))
                if len(hits) >= 12:
                    break
    return "\n\n---\n\n".join(hits) if hits else "Aucun résultat pour « %s »." % query


def _call_tool(name, args):
    if name == "gtk3sermo_reference":
        return REFERENCE or "(référence indisponible)"
    if name == "gtk3sermo_guide":
        return GUIDE or "(guide indisponible)"
    if name == "gtk3sermo_example":
        return EXAMPLE or "(exemple indisponible)"
    if name == "gtk3sermo_how_to_report":
        return REPORT
    if name == "gtk3sermo_search":
        return _search(str(args.get("query", "")))
    raise ValueError("outil inconnu : %s" % name)


def _send(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def _respond(rid, result):
    _send({"jsonrpc": "2.0", "id": rid, "result": result})


def _error(rid, code, message):
    _send({"jsonrpc": "2.0", "id": rid, "error": {"code": code, "message": message}})


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except json.JSONDecodeError:
            continue
        method = req.get("method")
        rid = req.get("id")
        if method == "initialize":
            _respond(rid, {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "gtk3sermo-mcp", "version": "1.0.0"},
            })
        elif method == "notifications/initialized":
            pass  # notification : aucune réponse attendue
        elif method == "tools/list":
            _respond(rid, {"tools": TOOLS})
        elif method == "tools/call":
            params = req.get("params", {})
            try:
                text = _call_tool(params.get("name"), params.get("arguments") or {})
                _respond(rid, {"content": [{"type": "text", "text": text}]})
            except Exception as exc:  # noqa: BLE001 — renvoyé proprement au client
                _error(rid, -32602, str(exc))
        elif rid is not None:
            _error(rid, -32601, "méthode inconnue : %s" % method)


if __name__ == "__main__":
    main()
