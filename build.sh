#!/bin/sh
# 
###############################################################################################
# Jenkins-Buildscript zu erstellung der Images
# 
# Dieses Script wird nach jedem Push auf dem Freifunk Buildserver ausgfhrt 
# und erstelt die Images komplett neu.
# 
# Durch den Jenkins-Server werden folgende Systemvariablem gesetzt:
# $WORKSPACE - Arbeitsverzeichnis, hierhin wurde dieses repo geclont 
# $JENKINS_HOME - TBD 
# $BUILD_NUMBER - Nummer des aktuellen Buildvorganges (wird in der site.conf verwendet)
# 
###############################################################################################
# Globale Einstellungen
#NUM_PROCS=x # Anzahl der Prozessoren
GLUON_RELEASE="v2017.1.1" # Release welches gebaut werden soll
GLUON_URL=https://github.com/freifunk-gluon/gluon.git
# Prfen ob wir uns auf Jenkins befinden
jenkins=false
[ -n "$JENKINS_HOME" ] && jenkins=true
# Setze workspace und wechsel zu diesem
WORKSPACE=${WORKSPACE:-$(dirname $(readlink -f $0))}
cd $WORKSPACE
# Setze die Anzahl der Prozessoren
NUM_PROCS=${NUM_PROCS:-$(nproc)}
# Falls die Jenkins Build-Nummer nicht gesetzt ist setze sie auf experimentell
BUILD_NUMBER=${BUILD_NUMBER:-"exp~$(date +%Y%m%d%H%M%S)"}
# Setze GLUON_RELEASE auf Version + Build-Nummer
GLUON_RELEASE="$GLUON_RELEASE+$BUILD_NUMBER"
# Optionszeile fr make erzeugen
make_options="GLUON_RELEASE=$GLUON_RELEASE"
# Setze GLUON_BRANCH auf stable, wenn auf Jenkins gebaut wird
# Andernfalls wird der GLUON_BRANCH nicht gesetzt, um den Autoupdater von Gluon standardmig zu deaktivieren
[ $jenkins = true ] && make_options="$make_options GLUON_BRANCH=$BUILD_BRANCH"
# Gebe Warnung vor dem Bau aus
echo "Die folgenden Einstellungen werden fuer den Bau verwendet:"
echo -e "WORKSPACE:\t$WORKSPACE"
echo -e "JENKINS_HOME:\t$JENKINS_HOME"
echo -e "NUM_PROCS:\t$NUM_PROCS"
echo -e "BUILD_NUMBER:\t$BUILD_NUMBER"
echo -e "GLUON_RELEASE:\t$GLUON_RELEASE"
echo -e "BUILD_BRANCH:\t$BUILD_BRANCH"
echo -e "GLUON_URL:\t$GLUON_URL"
echo -e "make_options:\t$make_options"
echo -e "jenkins:\t$jenkins\n"
if [ $jenkins = false ]
then
	wait_secs=5
	echo -n "Beginne in "
	while [ $wait_secs -gt 0 ]
	do
		echo -n "$wait_secs "
		wait_secs=$(expr $wait_secs - 1)
		sleep 1
	done
fi
echo -e "\n"
# Beende Script falls ein Fehler auftritt
set -e
# Verzeichnis fr Gluon-Repo erstellen und initialisieren
if [ ! -d "$WORKSPACE/gluon" ]
then
  git clone $GLUON_URL $WORKSPACE/gluon
fi
# Gluon Repo aktualisieren
cd $WORKSPACE/gluon
git fetch
git reset --hard $GLUON_COMMIT
git checkout $GLUON_COMMIT

# Site-Config in das Gluon-Repo symlinken
ln -nsf $WORKSPACE/site $WORKSPACE/gluon/site
# Gluon-Verzeichnis updaten
make update
# Verfgbare Targets aus Gluon targets.mk auslesen, und bauen
targets=$(sed '/^if/,/^end/{//!d}' targets/targets.mk | grep "GluonTarget" | awk -F',' '{printf "%s-%s", $2, $3}' | tr ')' ' ')
for target in $targets
do
	bash -c "make clean $make_options GLUON_TARGET=$target V=s"
	bash -c "make -j $NUM_PROCS $make_options GLUON_TARGET=$target V=s"
done
# Git-Tag erstellen und hochladen
if [ -n "$PUSH_TAGS" ]
then
	cd $WORKSPACE
	git tag $GLUON_RELEASE
	git push origin $GLUON_RELEASE
fi
