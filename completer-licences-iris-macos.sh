#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  IRIS pour macOS : compléter les archives publiées, SANS RIEN RECONSTRUIRE
#  25/10/2026, Shiloh Concept (idée I11).
#
#  Les archives publiées le 25/10 ne portent que la licence d'EA. Or IrisApp contient aussi, liées dedans par vcpkg,
#  des bibliothèques tierces (FFmpeg, OpenCV, libjpeg-turbo, libwebp, libtiff...) : leurs licences doivent
#  l'accompagner, et la LGPL 2.1 de FFmpeg (section 6) demande d'offrir, au même endroit que le programme, la source
#  de FFmpeg et de quoi relier le programme à une autre version (la source d'IRIS et notre correctif).
#
#  À lancer SUR LE MAC qui a construit IRIS (le dossier ~/iris-construction doit encore exister) :
#      chmod +x completer-licences-iris-macos.sh
#      ./completer-licences-iris-macos.sh
#
#  Ce que fait le script, et rien d'autre (rien n'est construit, rien n'est envoyé) :
#    · vérifie que chaque IrisApp est IDENTIQUE, octet pour octet, à celui des archives publiées le 25/10 ;
#    · ramasse le texte de licence de chaque bibliothèque construite par vcpkg (dossier TIERS de l'archive) et
#      en dresse la liste ;
#    · relève toute licence GPL ou LGPL autre que celle de FFmpeg dans A-EXAMINER.txt (à me renvoyer) ;
#    · refait les deux archives (mêmes fichiers, plus TIERS) et une archive des sources : FFmpeg tel que vcpkg l'a
#      téléchargé, le port vcpkg de FFmpeg (recette et correctifs), la source d'IRIS au commit 1.1.0, notre correctif ;
#    · range le tout dans ~/Desktop/iris-macos-2, avec les empreintes SHA-256.
# ─────────────────────────────────────────────────────────────────────────────
set -e
W="$HOME/iris-construction"
D="$HOME/Desktop/iris-macos-2"
IRIS_COMMIT="fd3e09e4e6fce30a5141ad6eca94a4ff61096e05"
[ -d "$W" ] || { echo "  [X] $W absent : rien à compléter (il faudrait reconstruire)"; exit 1; }
rm -rf "$D" && mkdir -p "$D"
: > "$D/A-EXAMINER.txt"

# Empreintes des IrisApp des archives publiées le 25/10 (relevées sur nos copies).
attendu() {
  case "$1" in
    x86_64) echo "9a40846a145b00532f652d8bfb679f5a20bbefe6062a8a57f476f1228867be57" ;;
    arm64)  echo "239fb10fe9bedce4e0034dc1a269cd6ffb0719f276feb263841dbd5ac5274f5e" ;;
  esac
}

for A in x86_64 arm64; do
  case "$A" in x86_64) T="x64-osx" ;; arm64) T="arm64-osx" ;; esac
  P="$W/paquet-$A"
  S="$W/build-$A/vcpkg_installed/$T/share"
  [ -f "$P/IrisApp" ] || { echo "  [X] $P/IrisApp absent"; exit 1; }
  [ -d "$S" ] || { echo "  [X] $S absent"; exit 1; }
  E="$(shasum -a 256 "$P/IrisApp" | cut -d' ' -f1)"
  [ "$E" = "$(attendu "$A")" ] || { echo "  [X] IrisApp $A n'est pas celui publié ($E) : arrêt"; exit 1; }
  echo "  ── $A : IrisApp identique à celui publié"
  Q="$W/paquet2-$A" && rm -rf "$Q" && mkdir -p "$Q/TIERS"
  cp "$P/IrisApp" "$P/appsettings.json" "$P/LICENSE.txt" "$P/CORRECTIF-SHILOH.txt" "$Q/"
  L="$Q/TIERS/LISTE.txt"
  {
    echo "Bibliothèques construites par vcpkg (étiquette 2026.10.16, triplet $T) pour IRIS 1.1.0 pour macOS ;"
    echo "le texte de licence de chacune est dans ce dossier, sous son nom. Libraries built by vcpkg for IRIS;"
    echo "each license text is in this folder, under its name."
    echo
  } > "$L"
  for C in "$S"/*/copyright; do
    N="$(basename "$(dirname "$C")")"
    case "$N" in vcpkg-*) continue ;; esac
    cp "$C" "$Q/TIERS/$N.txt"
    J="$(dirname "$C")/vcpkg.spdx.json"
    V=""
    LIC=""
    if [ -f "$J" ]; then
      V="$(grep -m1 '"versionInfo"' "$J" | sed 's/.*: *"\(.*\)".*/\1/')"
      LIC="$(grep -m1 '"licenseDeclared"' "$J" | sed 's/.*: *"\(.*\)".*/\1/')"
    fi
    echo "$N $V : $LIC" >> "$L"
    if [ "$N" != "ffmpeg" ] && grep -qi "GNU LESSER GENERAL PUBLIC\|GNU GENERAL PUBLIC\|GNU LIBRARY GENERAL" "$C"; then
      echo "$A $N $V ($LIC) : le texte de licence cite la GPL ou la LGPL" >> "$D/A-EXAMINER.txt"
    fi
  done
  cp "$L" "$D/LISTE-$A.txt"
  ( cd "$Q" && tar -czf "$D/iris-1.1.0-macos-$A.tar.gz" IrisApp appsettings.json LICENSE.txt CORRECTIF-SHILOH.txt TIERS )
  echo "  ── $A : $(($(ls "$Q/TIERS" | wc -l) - 1)) licence(s) de bibliothèques ajoutée(s)"
done

# Les sources offertes au titre de la LGPL de FFmpeg.
F="$W/sources-iris-macos" && rm -rf "$F" && mkdir -p "$F"
for f in "$W"/vcpkg/downloads/*; do
  [ -f "$f" ] || continue
  case "$(basename "$f" | tr 'A-Z' 'a-z')" in *ffmpeg*) cp "$f" "$F/" ;; esac
done
ls "$F" | grep -q . || { echo "  [X] source de FFmpeg introuvable dans $W/vcpkg/downloads"; exit 1; }
cp -R "$W/vcpkg/ports/ffmpeg" "$F/port-vcpkg-ffmpeg"
git -C "$W/IRIS" archive --format=tar.gz --prefix="IRIS-1.1.0/" "$IRIS_COMMIT" > "$F/IRIS-1.1.0-source.tar.gz"
git -C "$W/IRIS" diff > "$F/correctif-shiloh.diff"
cat > "$F/LISEZ-MOI.txt" <<'FIN'
Sources pour IRIS 1.1.0 pour macOS (Shiloh Concept, France)

IrisApp contient FFmpeg (LGPL 2.1 ou ultérieure), lié de façon statique par vcpkg. Comme le demande la LGPL
(section 6), voici, au même endroit que le programme :
  - la source de FFmpeg telle que vcpkg l'a téléchargée, et le port vcpkg qui l'a construite (port-vcpkg-ffmpeg :
    recette et correctifs) ;
  - la source d'IRIS au commit de l'étiquette 1.1.0 (IRIS-1.1.0-source.tar.gz) et notre seule modification
    (correctif-shiloh.diff).
Le script construire-iris-macos.sh du dépôt refait le programme (vcpkg à l'étiquette 2026.10.16) : modifiez FFmpeg,
reconstruisez, et vous obtenez IrisApp relié à votre version.

Sources for IRIS 1.1.0 for macOS (Shiloh Concept, France)

IrisApp contains FFmpeg (LGPL 2.1 or later), statically linked by vcpkg. As the LGPL requires (section 6), here are,
at the same place as the program: the FFmpeg source as downloaded by vcpkg and the vcpkg port that built it
(port-vcpkg-ffmpeg: recipe and patches); the IRIS source at the 1.1.0 tag commit (IRIS-1.1.0-source.tar.gz) and our
only change (correctif-shiloh.diff). The repository's construire-iris-macos.sh script rebuilds the program (vcpkg at
tag 2026.10.16): modify FFmpeg, rebuild, and you get IrisApp linked with your version.
FIN
( cd "$W" && tar -czf "$D/sources-iris-macos.tar.gz" "$(basename "$F")" )
( cd "$D" && shasum -a 256 iris-1.1.0-macos-x86_64.tar.gz iris-1.1.0-macos-arm64.tar.gz sources-iris-macos.tar.gz \
  | tee SHA256SUMS.txt )
echo
echo "  Contenu de la source : $(ls "$F" | tr '\n' ' ')"
if [ -s "$D/A-EXAMINER.txt" ]; then
  echo "  À EXAMINER avant de publier :"
  cat "$D/A-EXAMINER.txt"
else
  echo "  Aucune autre licence GPL ou LGPL que celle de FFmpeg."
fi
echo "  ── fini : envoyez-moi le dossier $D en entier (sauf les archives si elles sont trop lourdes : alors la liste,"
echo "     A-EXAMINER.txt et SHA256SUMS.txt suffisent)"
