#!/bin/sh
# verifie-verite.sh — la documentation servie aux IA dit-elle VRAI sur le code ?
#
# verifie-exemples.sh prouve que la syntaxe documentee s'analyse. Il ne prouve
# RIEN sur le fond : le mensonge « safe_system impose une liste blanche » serait
# passe au travers, et il est passe au travers pendant des mois.
#
# Ce banc-ci relie chaque affirmation forte de data/ a un FAIT du code source.
# Il a besoin du depot logiciel ; sans lui il s'arrete en 77, jamais en 0.
#
#   SERMO_SRC=/chemin/vers/gtk3dialog-public ./tests/verifie-verite.sh
#
# Codes : 0 tout concorde · 1 une affirmation ne colle plus au code ·
#         77 depot logiciel introuvable, rien n'a ete verifie.

set -u
ICI=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REF="$ICI/data/reference-xml.txt"
GUIDE="$ICI/data/guide.md"

SRC="${SERMO_SRC:-}"
[ -n "$SRC" ] || for c in "$ICI/../gtk3dialog-public" "$ICI/../sermo" "$HOME/haplo-developpement/gtk3dialog-public"; do
    [ -d "$c/gtk3sermo" ] && { SRC=$(CDPATH= cd -- "$c" && pwd); break; }
done
if [ -z "$SRC" ] || [ ! -d "$SRC/gtk3sermo" ]; then
    echo "IGNORÉ : dépôt logiciel introuvable — poser SERMO_SRC. Rien n'a été vérifié." >&2
    exit 77
fi

PORT_DIR=$(ls -d "$SRC"/gtk3sermo/gtk3sermo_*/ 2>/dev/null | grep -E '_[0-9.]+/$' | sort -V | tail -1)
[ -n "$PORT_DIR" ] || { echo "IGNORÉ : aucun gtk3sermo_<version>/ dans $SRC. Rien vérifié." >&2; exit 77; }
SAFE="$PORT_DIR/src/safe_exec.c"
LEXER="$PORT_DIR/src/gtkdialog_lexer.l"
# La reference documente LES DEUX ports : lire aussi le lexer GTK 4, sinon
# <flowbox>, <overlay>, <revealer> et <stack> ne sont jamais controles.
# Trouve le 2026-08-30 : la verification passait au vert en ignorant 4 balises.
PORT4_DIR=$(ls -d "$SRC"/gtk4sermo/gtk4sermo_*/ 2>/dev/null | grep -E '_[0-9.]+/$' | sort -V | tail -1)
LEXER4="${PORT4_DIR:-/inexistant}/src/gtkdialog_lexer.l"
VERSION=$(sed -n 's/^AC_INIT(\[gtk3sermo\], \[\([0-9.]*\)\].*/\1/p' "$PORT_DIR/configure.ac" | head -1)

echecs=0; joues=0
ko() { echecs=$((echecs+1)); printf 'ÉCHEC  %s\n' "$1"; [ $# -gt 1 ] && printf '       %s\n' "$2"; }
ok() { printf 'ok     %s\n' "$1"; }
essai() { joues=$((joues+1)); }

# ── 1. La liste blanche est-elle TOUJOURS eteinte par defaut ? ───────────────
# Si un jour le code passe en refus-par-defaut, la doc devra changer AUSSI.
essai
if grep -q 'liste absente : aucune restriction' "$SAFE"; then
    if grep -q "IL N'Y A AUCUNE LISTE BLANCHE PAR DÉFAUT" "$REF"; then
        ok "allowlist opt-in : le code et la référence concordent"
    else
        ko "le code laisse passer par défaut, la référence ne le dit plus" \
           "$SAFE dit « aucune restriction » ; $REF ne porte plus l'avertissement"
    fi
else
    ko "le défaut de safe_system a CHANGÉ dans le code" \
       "« liste absente : aucune restriction » a disparu de $SAFE — relire la section SÉCURITÉ"
fi

# ── 2. L'ancienne affirmation fausse ne doit jamais revenir telle quelle ─────
essai
if grep -q 'impose une liste blanche de commandes autorisées.  Les' "$REF" \
   || grep -q 'rejetées avec un message' "$REF"; then
    ko "la vieille affirmation fausse est revenue dans la référence"
else
    ok "l'affirmation « impose une liste blanche » n'est plus enseignée"
fi

# ── 3. Les deux verrous documentes existent-ils dans le code ? ──────────────
for v in HAPLO_ALLOWED_CMDS HAPLO_NO_SHELL_FALLBACK; do
    essai
    if grep -q "$v" "$SAFE"; then
        grep -q "$v" "$REF" && ok "$v : dans le code et dans la référence" \
            || ko "$v existe dans le code mais la référence ne le documente pas"
    else
        grep -q "$v" "$REF" \
            && ko "la référence documente $v, ABSENT du code" "cherché dans $SAFE" \
            || ok "$v : absent des deux, cohérent"
    fi
done

# ── 4. La version annoncee par la reference suit-elle le logiciel ? ─────────
essai
if [ -z "$VERSION" ]; then
    ko "version illisible dans configure.ac"
elif tail -3 "$REF" | grep -q "haplo-dialog $VERSION"; then
    ok "la référence est datée de la version courante ($VERSION)"
else
    ko "la référence n'est plus à la version du logiciel ($VERSION)" \
       "pied de page : $(tail -1 "$REF" | cut -c1-60)"
fi

# ── 5. Chaque balise du lexer est-elle decrite ? ────────────────────────────
# Les sous-elements et attributs sont documentes ailleurs : on les exclut par
# une liste EXPLICITE, pour qu'une nouvelle balise oubliee soit signalee.
essai
HORS='action default height input item label output radio sensitive separator variable visible width'
manquantes=""
for t in $(cat "$LEXER" "$LEXER4" 2>/dev/null | grep -oE '^\\<[a-z0-9]+\\>' | sed 's/\\<//;s/\\>//' | sort -u); do
    case " $HORS " in *" $t "*) continue ;; esac
    grep -qE "^     <$t>" "$REF" || manquantes="$manquantes $t"
done
if [ -z "$manquantes" ]; then
    ok "toutes les balises des DEUX lexers sont décrites ($(cat "$LEXER" "$LEXER4" 2>/dev/null | grep -cE '^\\<[a-z0-9]+\\>') entrées lues)"
else
    ko "balise(s) du lexer absente(s) de la « RÉFÉRENCE COMPLÈTE » :$manquantes"
fi

# ── 6. Le guide ne doit pas re-affirmer ce qui a ete mesure faux ────────────
essai
if grep -q 'ne fonctionne PAS' "$GUIDE" && grep -q 'haplo-dialog-xml' "$GUIDE"; then
    ko "le guide redit que la page de manuel n'est pas installée" \
       "elle l'est : gtk3sermo.install liste usr/share/man/man5/haplo-dialog-xml.5"
else
    ok "le guide ne dissuade plus d'utiliser man 5 haplo-dialog-xml"
fi

echo
printf '%s vérification(s), %s échec(s). Source : %s\n' "$joues" "$echecs" "$PORT_DIR"
[ "$joues" -gt 0 ] || { echo "ÉCHEC : rien n'a été vérifié." >&2; exit 1; }
[ "$echecs" -eq 0 ] || exit 1
echo "La documentation servie concorde avec le code."
