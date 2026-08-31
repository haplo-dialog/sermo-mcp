#!/bin/sh
# verifie-exemples.sh — rejoue CHAQUE bout de XML documenté dans data/ contre
# les binaires réels, et échoue si l'un d'eux ne passe pas l'analyseur.
#
# Pourquoi ce banc existe. Le 2026-08-30, cinq formes enseignées par la
# référence étaient des ERREURS DE SYNTAXE : <frame><label>, <notebook><label>,
# <expander><label>, <pixmap><filename>, <table><column-header>. L'exemple
# phare du guide ne démarrait pas. Personne ne l'avait vu parce que rien ne
# rejouait la documentation.
#
# ⛔ Ce banc REFUSE de réussir s'il n'a rien testé : un banc muet qui rend 0
#    est pire que pas de banc.

set -u
ICI=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

BINS=""
for b in gtk3sermo gtk4sermo; do
    command -v "$b" >/dev/null 2>&1 && BINS="$BINS $b"
done
if [ -z "$BINS" ]; then
    echo "IGNORÉ : ni gtk3sermo ni gtk4sermo installés — rien n'a été vérifié." >&2
    exit 77
fi

# Avec un seul port installé, le banc passait au vert en testant LA MOITIÉ du
# périmètre, sans le dire nulle part. SERMO_PORTS_REQUIS rend l'exigence
# explicite : en CI on la pose, en local on reste tolérant mais le résumé
# annonce toujours quels ports ont réellement tourné.
for exige in ${SERMO_PORTS_REQUIS:-}; do
    case " $BINS " in
        *" $exige "*) ;;
        *) echo "ÉCHEC : $exige est exigé (SERMO_PORTS_REQUIS) et introuvable." >&2
           exit 1 ;;
    esac
done
command -v xvfb-run >/dev/null 2>&1 || {
    echo "IGNORÉ : xvfb-run absent — rien n'a été vérifié." >&2; exit 77; }

# Extraction : les <window>…</window> complets, et les fragments indentés des
# entrées de la référence, qu'on enveloppe dans un <window> minimal.
python3 - "$ICI" "$TMP" <<'PYEOF'
import io, os, re, sys
racine, tmp = sys.argv[1], sys.argv[2]
n = 0

def ecrire(txt):
    global n
    io.open(os.path.join(tmp, "c%03d.xml" % n), "w", encoding="utf-8").write(txt)
    n += 1

for nom in ("data/guide.md", "data/reference-xml.txt"):
    chemin = os.path.join(racine, nom)
    if not os.path.exists(chemin):
        continue
    lignes = io.open(chemin, encoding="utf-8").read().split("\n")

    # 1) blocs <window>…</window> complets, reconstruits LIGNE A LIGNE :
    #    on n'ouvre que sur une ligne qui commence par <window, et on ferme
    #    sur </window>. Toute ligne intermediaire qui n'est pas du XML annule
    #    le bloc — sinon on avale la prose qui cite des balises.
    buf = None
    for l in lignes:
        t = l.strip()
        if buf is None:
            if t.startswith("<window"):
                buf = [t]
                if "</window>" in t:
                    ecrire(" ".join(buf)); buf = None
            continue
        if t and not t.startswith("<") and not t.startswith("/") \
           and "</" not in t and ">" not in t:
            buf = None            # de la prose : ce n'etait pas un exemple
            continue
        buf.append(t)
        if "</window>" in t:
            ecrire(" ".join(buf)); buf = None

    # 2) fragments : suites de lignes indentees dont CHACUNE est du XML
    if nom.endswith(".txt"):
        bloc = []
        for l in lignes:
            t = l.strip()
            if l.startswith("        ") and t.startswith("<"):
                bloc.append(t)
                continue
            if bloc:
                frag = " ".join(bloc)
                if not frag.startswith("<window") and re.search(r"</[a-z]+>", frag):
                    ecrire("<window>" + frag + "</window>")
                bloc = []
        if bloc:
            frag = " ".join(bloc)
            if not frag.startswith("<window") and re.search(r"</[a-z]+>", frag):
                ecrire("<window>" + frag + "</window>")
print(n)
PYEOF
CAS=$(ls "$TMP"/*.xml 2>/dev/null | wc -l)
if [ "$CAS" -eq 0 ]; then
    echo "ÉCHEC : aucun exemple extrait — l'extracteur est cassé, ou data/ est vide." >&2
    exit 1
fi

joues=0; echecs=0
for f in "$TMP"/*.xml; do
    for b in $BINS; do
        MAIN_DIALOG="$(cat "$f")" xvfb-run -a timeout 20 "$b" \
            --program=MAIN_DIALOG --print-ir >/dev/null 2>"$TMP/err"
        rc=$?
        joues=$((joues + 1))
        if [ "$rc" -ne 0 ]; then
            echecs=$((echecs + 1))
            printf 'ÉCHEC  %-10s %s\n' "$b" "$(basename "$f")"
            sed 's/^/         /' "$TMP/err" | head -3
            sed 's/^/         | /' "$f" | head -6
        fi
    done
done

printf '%s exemple(s) documenté(s), %s exécution(s), %s échec(s). Ports :%s\n' \
    "$CAS" "$joues" "$echecs" "$BINS"
[ "$joues" -gt 0 ] || { echo "ÉCHEC : rien n'a été joué." >&2; exit 1; }
[ "$echecs" -eq 0 ] || exit 1
echo "Tous les exemples de la documentation passent l'analyseur."
