#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  IRIS 1.1.0 (Electronic Arts) pour macOS, construit depuis sa SOURCE OFFICIELLE
#  23/10/2026, Shiloh Concept (idée I11) : EA ne publie IRIS que pour Windows et Linux x86_64.
#
#  À lancer SUR UN MAC (Terminal) :
#      chmod +x construire-iris-macos.sh
#      ./construire-iris-macos.sh                 la puce de ce Mac
#      ./construire-iris-macos.sh "x86_64 arm64"  les deux (Intel et puce Apple)
#
#  Prérequis, une seule fois :
#      xcode-select --install
#      brew install cmake ninja pkg-config autoconf autoconf-archive automake libtool nasm
#
#  Ce que fait le script, et rien d'autre :
#    · prend IRIS chez electronicarts/IRIS, au commit de l'étiquette 1.1.0 (vérifié) ;
#    · prend vcpkg (Microsoft) à l'étiquette 2026.10.16 : il construit les bibliothèques d'IRIS (OpenCV avec
#      FFmpeg, spdlog, giflib…) depuis leurs sources, en statique ;
#    · construit l'application d'exemple d'EA (IrisApp), avec le préréglage macOS d'EA passé en Release ;
#    · range IrisApp, ses réglages (appsettings.json) et la licence BSD-3 d'EA dans
#      ~/Desktop/iris-1.1.0-macos-<puce>.tar.gz, avec son empreinte SHA-256.
#  La première construction est longue (une heure environ : OpenCV et FFmpeg). Rien n'est envoyé nulle part.
# ─────────────────────────────────────────────────────────────────────────────
set -e
ARCHS="${1:-$(uname -m)}"
IRIS_COMMIT="fd3e09e4e6fce30a5141ad6eca94a4ff61096e05"
VCPKG_TAG="2026.10.16"
W="$HOME/iris-construction"

manque=""
xcode-select -p > /dev/null 2>&1 || manque="$manque xcode-select"
for p in git cmake ninja pkg-config autoconf automake libtool nasm; do
  command -v "$p" > /dev/null 2>&1 || manque="$manque $p"
done
if [ -n "$manque" ]; then
  echo "  [X] Il manque :$manque"
  echo "      xcode-select --install"
  echo "      brew install cmake ninja pkg-config autoconf autoconf-archive automake libtool nasm"
  exit 1
fi

mkdir -p "$W" && cd "$W"
[ -d vcpkg ] || git clone https://github.com/microsoft/vcpkg.git
( cd vcpkg && git fetch --tags --quiet && git checkout --quiet "$VCPKG_TAG" && ./bootstrap-vcpkg.sh -disableMetrics )
[ -d IRIS ] || git clone https://github.com/electronicarts/IRIS.git
( cd IRIS && git fetch --tags --quiet && git checkout --quiet "$IRIS_COMMIT" )
[ "$(cd IRIS && git rev-parse HEAD)" = "$IRIS_COMMIT" ] || { echo "  [X] IRIS : commit inattendu"; exit 1; }

# ⚠ UN CORRECTIF D'UNE LIGNE DANS LA SOURCE D'EA, 25/10/2026. L'IrisApp pour Mac rendait le bon résultat puis tombait en
#   « Illegal instruction » dans ~FlashDetection (rapports d'arrêt de macOS). TransitionTracker est une classe de base
#   abstraite SANS destructeur virtuel, et FlashDetection détruit par elle un objet dérivé : c'est un comportement
#   indéfini du C++, que le compilateur du Mac remplace par un arrêt (le réglage -fno-sized-deallocation, essayé avant,
#   n'y changeait rien). Windows et Linux le tolèrent. Le correctif donne à TransitionTracker le destructeur virtuel
#   qui lui manque ; il est écrit dans CORRECTIF-SHILOH.txt, livré dans l'archive avec la licence d'EA.
TT="IRIS/src/TransitionTracker.h"
if ! grep -q "virtual ~TransitionTracker()" "$TT"; then
  perl -0pi -e 's/(class TransitionTracker\s*\{\s*public:)/$1\n\t\tvirtual ~TransitionTracker() = default; \/\/ correctif Shiloh Concept, 25\/10\/2026/' "$TT"
fi
grep -q "virtual ~TransitionTracker() = default;" "$TT" || { echo "  [X] correctif non posé dans $TT"; exit 1; }
cat > "$W/CORRECTIF-SHILOH.txt" << 'FIN'
IRIS 1.1.0 (Electronic Arts, commit fd3e09e4e6fce30a5141ad6eca94a4ff61096e05), construit pour macOS par Shiloh Concept.
Une seule modification de la source d'EA, dans src/TransitionTracker.h :

    virtual ~TransitionTracker() = default;

TransitionTracker est une classe de base abstraite sans destructeur virtuel ; FlashDetection détruit par elle un objet
dérivé (comportement indéfini du C++). Le compilateur de macOS en fait un arrêt du programme (« Illegal instruction »)
à la fin de chaque analyse ; Windows et Linux le tolèrent. Le résultat de l'analyse n'en dépend pas.
FIN

# 25/10/2026 : sur un Mac Intel, Homebrew range jpeg-turbo sous /usr/local (jpeglib.h, version 80), que le compilateur
#   lit avant celui de vcpkg (version 62) : OpenCV pour puce Apple appelait alors jpeg_default_qtables, absent de la
#   libjpeg de vcpkg (« Undefined symbols », diagnostic du 25/10). Le temps de la construction pour puce Apple, ce lien
#   de Homebrew est retiré, puis REMIS en sortie quoi qu'il arrive ; et vcpkg reconstruit sans son cache, qui garde
#   l'OpenCV fautif.
RELIER=""
remettre() { [ -n "$RELIER" ] && brew link "$RELIER" > /dev/null 2>&1 && echo "  Homebrew : $RELIER relié de nouveau"; }
trap remettre EXIT

for A in $ARCHS; do
  case "$A" in
    x86_64) T="x64-osx" ;;
    arm64)  T="arm64-osx" ;;
    *) echo "  [X] puce inconnue : $A"; exit 1 ;;
  esac
  B="$W/build-$A"
  # Une construction déjà RÉUSSIE (IrisApp présent) a des bibliothèques saines : seul IRIS se recompile.
  if [ "$A" = arm64 ] && [ "$(uname -m)" = x86_64 ] && [ -e /usr/local/include/jpeglib.h ] \
     && [ -z "$(find "$B" -type f -name IrisApp 2>/dev/null | head -1)" ]; then
    if brew list jpeg-turbo > /dev/null 2>&1; then
      brew unlink jpeg-turbo > /dev/null && RELIER="jpeg-turbo" && echo "  Homebrew : jpeg-turbo délié le temps de la construction"
    fi
    [ -e /usr/local/include/jpeglib.h ] && { echo "  [X] /usr/local/include/jpeglib.h est encore là : construction arrêtée"; exit 1; }
    rm -rf "$B"
    export VCPKG_BINARY_SOURCES="clear"
  fi
  echo "  ── IRIS pour macOS $A ($T), début $(date +%H:%M)"
  cmake -S IRIS -B "$B" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$W/vcpkg/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_TARGET_TRIPLET="$T" -DCMAKE_OSX_ARCHITECTURES="$A" \
    -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLE_APP=ON -DBUILD_TESTS=OFF -DCMAKE_CXX_FLAGS=""
  cmake --build "$B" --target IrisApp
  APP="$(find "$B" -type f -name IrisApp -perm -u+x | head -1)"
  [ -n "$APP" ] || { echo "  [X] IrisApp introuvable après la construction"; exit 1; }
  echo "  Puce du programme : $(lipo -archs "$APP")"
  echo "  Bibliothèques chargées (seules celles du système sont attendues) :"
  otool -L "$APP" | tail -n +2
  P="$W/paquet-$A" && rm -rf "$P" && mkdir -p "$P"
  cp "$APP" "$P/IrisApp"
  cp IRIS/example/appsettings.json "$P/"
  cp IRIS/LICENSE.txt "$P/LICENSE.txt"
  cp "$W/CORRECTIF-SHILOH.txt" "$P/"
  # 25/10/2026 : plus de « IrisApp -h » (« Abort trap » : -h n'existe pas, l'application cherche alors un dossier
  #   TestVideos). L'épreuve est verifier-iris-macos.sh, sur une vraie vidéo.
  SORTIE="$HOME/Desktop/iris-1.1.0-macos-$A.tar.gz"
  tar -czf "$SORTIE" -C "$P" IrisApp appsettings.json LICENSE.txt CORRECTIF-SHILOH.txt
  shasum -a 256 "$SORTIE" | tee "$SORTIE.sha256"
  echo "  ── fini $(date +%H:%M) : $SORTIE"
  unset VCPKG_BINARY_SOURCES
done
