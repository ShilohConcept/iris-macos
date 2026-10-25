# IRIS pour macOS (Intel et Apple Silicon)

*English version below.*

## En français

Ce dépôt est tenu par **Shiloh Concept**, une entreprise **française**. Il publie une seule chose : **IRIS 1.1.0,
l'outil d'Electronic Arts qui détecte dans une vidéo les flashs et les motifs dangereux pour les personnes
photosensibles**, construit pour **macOS** à partir du code source officiel d'Electronic Arts.

### Pourquoi ce dépôt

Electronic Arts publie IRIS pour Windows et pour Linux (x86_64), mais pas pour macOS. Notre logiciel d'audit
d'accessibilité, **Audit PRO**, s'en sert pour le critère 13.7 du RGAA (WCAG 2.3.1 : pas plus de trois flashs par
seconde). Pour que nos utilisateurs sur Mac aient la même mesure que sur Windows et Linux, nous construisons IRIS
pour macOS et publions ici le résultat, avec tout ce qu'il faut pour le vérifier et le reconstruire soi-même.

Ce dépôt n'est **ni affilié à Electronic Arts, ni approuvé par Electronic Arts**.

### Ce qui est publié

Dans les « Releases » du dépôt :

| Archive | Pour | État |
|---|---|---|
| `iris-1.1.0-macos-x86_64.tar.gz` | Mac à processeur Intel | éprouvée sur un Mac Intel (macOS 13.7) |
| `iris-1.1.0-macos-arm64.tar.gz` | Mac à puce Apple (M1, M2…) | construite, pas encore éprouvée sur une puce Apple |

Chaque archive contient l'application `IrisApp`, ses réglages (`appsettings.json`), la licence d'Electronic Arts
(`LICENSE.txt`) et la description de notre seule modification (`CORRECTIF-SHILOH.txt`).

### Notre seule modification

Une ligne, dans `src/TransitionTracker.h` :

    virtual ~TransitionTracker() = default;

Sans elle, IRIS rend le bon résultat puis s'arrête sur macOS (« Illegal instruction ») : une classe de base sans
destructeur virtuel, que le compilateur de macOS traite comme une erreur. Windows et Linux ne sont pas concernés.
Le résultat des analyses n'en dépend pas.

### Vérifier une archive

Les empreintes SHA-256 sont dans `SHA256SUMS.txt`. Sur le Mac :

    shasum -a 256 iris-1.1.0-macos-x86_64.tar.gz

Audit PRO vérifie lui-même cette empreinte avant d'installer, et refuse toute archive qui en diffère.

### Reconstruire soi-même

`construire-iris-macos.sh` refait tout sur un Mac : IRIS à son commit officiel
(`fd3e09e4e6fce30a5141ad6eca94a4ff61096e05`, étiquette 1.1.0), ses bibliothèques par vcpkg (étiquette 2026.10.16),
puis la correction ci-dessus. Les instructions sont en tête du script.

### Licence

IRIS est © 2023 Electronic Arts Inc., sous licence BSD à 3 clauses (`LICENSE.txt`), que nous respectons : la licence
et l'avis de copyright accompagnent chaque archive, et le nom d'Electronic Arts n'est pas utilisé pour promouvoir
ce travail. Code source d'origine : https://github.com/electronicarts/IRIS

### Contact

Shiloh Concept, France : https://www.shiloh-concept.fr

---

## In English

This repository is maintained by **Shiloh Concept**, a **French** company. It publishes one thing only:
**IRIS 1.1.0, Electronic Arts' tool that detects flashes and patterns harmful to photosensitive people in videos**,
built for **macOS** from Electronic Arts' official source code.

### Why this repository

Electronic Arts publishes IRIS for Windows and Linux (x86_64), but not for macOS. Our accessibility audit software,
**Audit PRO**, uses it for RGAA criterion 13.7 (WCAG 2.3.1: no more than three flashes per second). So that our
users on a Mac get the same measurement as on Windows and Linux, we build IRIS for macOS and publish the result
here, with everything needed to check it and rebuild it yourself.

This repository is **neither affiliated with nor endorsed by Electronic Arts**.

### What is published

In the repository's "Releases":

| Archive | For | Status |
|---|---|---|
| `iris-1.1.0-macos-x86_64.tar.gz` | Intel Macs | tested on an Intel Mac (macOS 13.7) |
| `iris-1.1.0-macos-arm64.tar.gz` | Apple silicon Macs (M1, M2…) | built, not yet tested on Apple silicon |

Each archive contains the `IrisApp` application, its settings (`appsettings.json`), Electronic Arts' license
(`LICENSE.txt`) and the description of our only change (`CORRECTIF-SHILOH.txt`, in French).

### Our only change

One line, in `src/TransitionTracker.h`:

    virtual ~TransitionTracker() = default;

Without it, IRIS returns the correct result and then stops on macOS ("Illegal instruction"): a base class without
a virtual destructor, which the macOS compiler treats as an error. Windows and Linux are not affected. Analysis
results do not depend on it.

### Verify an archive

SHA-256 checksums are in `SHA256SUMS.txt`. On a Mac:

    shasum -a 256 iris-1.1.0-macos-x86_64.tar.gz

Audit PRO checks this checksum itself before installing, and refuses any archive that differs.

### Rebuild it yourself

`construire-iris-macos.sh` redoes everything on a Mac: IRIS at its official commit
(`fd3e09e4e6fce30a5141ad6eca94a4ff61096e05`, tag 1.1.0), its libraries through vcpkg (tag 2026.10.16), then the
fix above. Instructions (in French) are at the top of the script.

### License

IRIS is © 2023 Electronic Arts Inc., under the 3-clause BSD license (`LICENSE.txt`), which we comply with: the
license and copyright notice ship with every archive, and Electronic Arts' name is not used to promote this work.
Original source code: https://github.com/electronicarts/IRIS

### Contact

Shiloh Concept, France: https://www.shiloh-concept.fr
