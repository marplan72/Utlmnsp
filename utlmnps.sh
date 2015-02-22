#!/usr/bin/env bash
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#
# AUTEUR..........: Martin PLANTE
# PROGRAMME.......: utlmnsp.sh
# VERSION.........: 6.7.1
# DATE DE CREATION: 2001-04-05
# DATE DE CREATION: 2015-02-04
# UTILISATION.....: UTiLitaire de MaiNtenance Serveur Principal.
#
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

# HISTORIQUE DES VERSIONS:
# 4.0 - Re-ecriture complet du script
# 4.6 - Ajout de repertoire pour chaque jour de la semaine
# 4.7 - On backup le repertoire Documents and setting sur poste W2K
# 4.8 - On creer un log dans un fichier
# 4.9 - Revision complete
# 5.0 - Suite au retrait des disques scsi, le scprit est modifie
# 6.0 - Back on tracks
# 6.1 - on change le format des fonctions (retrait de Function et ajout ())
# 6.5 - Ajout des repertoires publics
# 6.6 - Ajout des fichiers de configurations
# 6.7 - On backup les usagers selon /etc/smbpasswd
# 
#
##############################################################################
#
# EXIT CODE - SIGNIFICATION
#         1 - Catchall for general errors
#         2 - Misuse of shell builtins (according to Bash documentation)
#       126 - Command invoked cannot execute
#       127 - "command not found"
#       128 - Invalid argument to exit
#     128+n - Fatal error signal "n"
#       130 - Script terminated by Control-C
#      255* - Exit status out of range

E_VARS_NOT_SET=160
E_COMMAND_LINE=162
E_NO_SOURCE_DIR=164
E_NO_DEST_DIR=166
E_DIR_NOT_FOUND=168
E_MOUNT_FAIL=170
E_UNMOUNTED=172
E_BACKUP=174
E_NOT_ROOT=176
E_FILE_NOT_FOUND=178

## Source: http://kvz.io/blog/2013/11/21/bash-best-practices/

# Use set -o errexit (a.k.a. set -e) to make your script exit
# when a command fails.
set -o errexit

# Use set -o pipefail in scripts to catch mysqldump fails in e.g. 
# mysqldump |gzip. The exit status of the last command that threw a
# non-zero exit code is returned.
set -o pipefail

# Use set -o nounset (a.k.a. set -u) to exit when your script
# tries to use undeclared variables.
set -o nounset

# Use set -o xtrace (a.k.a set -x) to trace what gets executed.
# Useful for debugging.
#set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

arg1="${1:-}"

##############################################################################
#
# DECLARE/TYPESET OPTIONS
# 
# -a = Variable is an array.
#      ex.: declare -a indices
#
# -f =  Use function names only.
#      ex.: declare -f function_name
#
# -i = The variable is to be treated as an integer; arithmetic evaluation is
#      performed when the variable is assigned a value.
#      ex.: declare -i number
#
# -p = Display the attributes and values of each variable. When -p is used,
#      additional options are ignored.
#
# -r = Make variables read-only. These variables cannot then be assigned
#      values by subsequent assignment statements, nor can they be unset.
#      ex.: declare -r var1
#
# -t = Give each variable the trace attribute.
#
# -x = Mark each variable for export to subsequent commands via the environment.
#      ex.: declare -x var3
#
# -x = var=$value.. ex.: declare -x var3=373
#

##############################################################################
#
# DEFINITION DES COULEURS
# Color	Foreground	Background
# black		30	40
# red		31	41
# green		32	42
# yellow	33	43
# blue		34	44
# magenta	35	45
# cyan		36	46
# white		37	47

# ...sur background courant.
black='\e[30m'; 		hblack='\e[1;30m'
red='\e[31m'; 			hred='\e[1;31m'
green='\e[32m'; 		hgreen='\e[1;32m'
yellow='\e[33m'; 		hyellow='\e[1;33m'
blue='\e[34m'; 			hblue='\e[1;34m'
magenta='\e[35m'; 		hmagenta='\e[1;35m'
cyan='\e[36m'; 			hcyan='\e[1;36m'
white='\e[37m'; 		hwhite='\e[1;37m'

# ...sur background noir
bkackonblack='\e[30;40m';	hblackonblack='\e[1;30;40m'
redonblack='\e[31;40m';		hredonblack='\e[1;31;40m'
greenonblack='\e[32;40m';	hgreenonblack='\e[1;32;40m'
yellowonblack='\e[33;40m';	hyellowonblack='\e[1;33;40m'
blueonblack='\e[34;40m';	hblueonblack='\e[1;34;40m'
magentaonblack='\e[35;40m';	hmagentaonblack='\e[1;35;40m'
cyanonblack='\e[36;40m';	hcyanonblack='\e[1;36;40m'
whiteonblack='\e[37;40m';	hwhiteonblack='\e[1;37;40m'

# ...sur background rouge
blackonred='\e[30;41m';		hblackonred='\e[1;30;41m'
redonred='\e[31;41m';		hredonred='\e[1;31;41m'
greenonred='\e[32;41m';		hgreenonred='\e[1;32;41m'
yellowonred='\e[33;41m';	hyellowonred='\e[1;33;41m'
blueonred='\e[34;41m';		hblueonred='\e[1;34;41m'
magentaonred='\e[35;41m';	hmagentaonred='\e[1;35;41m'
cyanonred='\e[36;41m';		hcyanonred='\e[1;36;41m'
whiteonred='\e[37;41m';		hwhiteonred='\e[1;37;41m'

# ...sur background vert
blackongreen='\e[30;42m';	hblackongreen='\e[1;30;42m'
redongreen='\e[31;42m';		hredongreen='\e[1;31;42m'
greenongreen='\e[32;42m';	hgreenongreen='\e[1;32;42m'
yellowongreen='\e[33;42m';	hyellowongreen='\e[1;33;42m'
blueongreen='\e[34;42m';	hblueongreen='\e[1;34;42m'
magentaongreen='\e[35;42m';	hmagentaongreen='\e[1;35;42m'
cyanongreen='\e[36;42m';	hcyanongreen='\e[1;36;42m'
whiteongreen='\e[37;42m';	hwhiteongreen='\e[1;37;42m'

# ...sur background jaune
blackonwellow='\e[30;43m';	hblackonyellow='\e[1;30;43m'
redonwellow='\e[31;43m';	hredonyellow='\e[1;31;43m'
greenonwellow='\e[32;43m';	hgreenonwellow='\e[1;32;43m'
yellowonwellow='\e[33;43m';	hyellowonwellow='\e[1;33;43m'
blueonwellow='\e[34;43m';	hblueonwellow='\e[1;34;43m'
magentaonwellow='\e[35;43m';	hmagentaonwellow='\e[1;35;43m'
cyanonwellow='\e[36;43m';	hcyanonwellow='\e[1;36;43m'
whiteonwellow='\e[37;43m';	hwhiteonwellow='\e[1;37;43m'

# ...sur background bleu
blackkonblue='\e[30;44m';	hblackonblue='\e[1;30;44m'
redonblue='\e[31;44m';		hredonblue='\e[1;31;44m'
greenonblue='\e[32;44m';	hgreenonblue='\e[1;32;44m'
yellowonblue='\e[33;44m';	hyellowonblue='\e[1;33;44m'
blueonblue='\e[34;44m';		hblueonblue='\e[1;34;44m'
magentaonblue='\e[35;44m';	hmagentaonblue='\e[1;35;44m'
cyanonblue='\e[36;44m';		hcyanonblue='\e[1;36;44m'
whiteonblue='\e[37;44m';	hwhiteonblue='\e[1;37;44m'

# ...sur background magenta
blackonmagenta='\e[30;45m';	hblackonmagenta='\e[1;30;45m'
redonmagenta='\e[31;45m';	hredonmagenta='\e[1;31;45m'
greenonmagenta='\e[32;45m';	hgreenonmagenta='\e[1;32;45m'
yellowonmagenta='\e[33;45m';	hyellowonmagenta='\e[1;33;45m'
blueonmagenta='\e[34;45m';	hblueonmagenta='\e[1;34;45m'
magentaonmagenta='\e[35;45m';	hmagentaonmagenta='\e[1;35;45m'
cyanonmagenta='\e[36;45m';	hcyanonmagenta='\e[1;36;45m'
whiteonmagenta='\e[37;45m';	hwhiteonmagenta='\e[1;37;45m'

# ...sur background cyan
blackoncyan='\e[30;46m';	hblackoncyan='\e[1;30;46m'
redoncyan='\e[31;46m';		hredoncyan='\e[1;31;46m'
greenoncyan='\e[32;46m';	hgreenoncyan='\e[1;32;46m'
yellowoncyan='\e[33;46m';	hyellowoncyan='\e[1;33;46m'
blueoncyan='\e[34;46m';		hblueoncyan='\e[1;34;46m'
magentaoncyan='\e[35;46m';	hmagentaoncyan='\e[1;35;46m'
cyanoncyan='\e[36;46m';		hcyanoncyan='\e[1;36;46m'
whiteoncyan='\e[37;46m';	hwhiteoncyan='\e[1;37;46m'

# ...sur background blanc
blackonwhite='\e[30;47m';	hblackonwhite='\e[1;30;47m'
redonwhite='\e[31;47m';		hredonwhite='\e[1;31;47m'
greenonwhite='\e[32;47m';	hgreenonwhite='\e[1;32;47m'
yellowonwhite='\e[33;47m';	hyellowonwhite='\e[1;33;47m'
blueonwhite='\e[34;47m';	hblueonwhite='\e[1;34;47m'
magentaonwhite='\e[35;47m';	hmagentaonwhite='\e[1;35;47m'
cyanonwhite='\e[36;47m';	hcyanonwhite='\e[1;36;47m'
whiteonwhite='\e[37;47m';	hwhiteonwhite='\e[1;37;47m'

##############################################################################
#
# FONCTION...: cecho
# ENTREE.....: $1 = Ligne a ecrire; $2 = couleur.
# SORTIE.....: Aucun.
# DESCRIPTION: Ecrit la ligne $1 avec la couleur $2.
#
##############################################################################
function cecho ()
{
 local default_msg="No message passed."

 message=${1:-$default_msg}  # Defaults to default message.
 color=${2:-$white}          # Defaults to white, if not specified.

 echo -e $color$message; echo -ne '\e[0m'

 return
}

##############################################################################
#
# FONCTION...: wlog
# ENTREE.....: $1 = Ligne a ecrire.
# SORTIE.....: Aucun.
# DESCRIPTION: Ecrit date & heure ligne $1 dans le log et a l'ecran.
#
##############################################################################
function wlog ()
{
 # Affiche a l'ecran,
 echo `date "+%-F %-T"` "-" $1

 # Verification de la presence du fichier de log
 if [ ! -e $Log ]; then
    CreerEnteteLog
 fi

 # Ecriture dans le fichier.
 echo `date "+%-F %-T"` "-" $1 >> $Log
}

###############################################################################
#
# FONCTION...: CreerEnteteLog
# ENTREE.....: 0$ nom du fichier courant.
# SORTIE.....: Aucun.
# DESCRIPTION: Creation de l'entete du log.
#
###############################################################################
function CreerEnteteLog ()
{
 # Retrait de "./" dans le parametre $0
 local cStr='./'
 local cFicLog=${0#$cStr}.log

 # On definit les caracteres et la longueur des lignes dans le journal.
 local cCar="#"
 local cLigne="##"
 local iFois=${#cFicLog}
 for ((i=1 ; i <= iFois ; i++))
 do
    cLigne=$cLigne$cCar
 done

 echo `date "+%-F %-T"` $cLigne > $Log
 echo `date "+%-F %-T"` " "  >>$Log
 echo `date "+%-F %-T"` " $cFicLog" >>$Log
 echo `date "+%-F %-T"` " "  >>$Log
 echo `date "+%-F %-T"` $cLigne >> $Log
 echo `date "+%-F %-T"` " " >>$Log
}

##############################################################################
#
# FONCTION...: FctnModele
# ENTREE.....:
# SORTIE.....:
# DESCRIPTION: Fonction modele.
#
##############################################################################
function FctnModele ()
{
 echo "Hello world!"
}

###############################################################################
#
# DECLARATION VARIABLES
#
declare -r StrDir=`pwd`
Log="/var/log/$HOSTNAME/utlmnsp."`date "+%-F"`".log"
TimSta=$(date +"%s")
JouMoi=`date "+%d"`            # Jour du mois courant
JouSem=`date "+%-A"`           # Jour de la semaine courante (lundi, etc.)
MODE="N"                       # Mode (N)ormal ou (d)ry run
COULEUR=1                      # 0=vrai, 1=faux
JOURANNEE=`date +%j`
# Ou seront deposes les fichiers doit commencer par un / et finir avec un /
BckDir="/mnt/zbackup/"
# Repertoire public a archiver
PubDir="/mnt/"
PubDirNam="prtg"

# Parametres pour la recherche
_l="/etc/login.defs"
_p="/etc/passwd"
l=$(grep "^UID_MIN" $_l)
l1=$(grep "^UID_MAX" $_l)

###############################################################################
#
# FONCTION...: FinTraitement
# ENTREE.....: Aucun.
# SORTIE.....: Aucun.
# DESCRIPTION: Calcul du temps d'execution et l'ajoute au log.
#
###############################################################################
FinTraitement ()
{
 TimSto=$(date +"%s")
 TimExe=$(($TimSto-$TimSta))
 Sec=$(($TimExe%60))
 TimExe=$((TimExe/60))
 Min=$(($TimExe%60))
 TimExe=$((TimExe/60))
 Heu=$((TimExe%24))
 wlog "Duree: $Heu heure(s) $Min minute(s) $Sec seconde(s)"
 wlog "..--==[ FIN DE L'EXECUTION ]==--.."
}

###############################################################################
#
# FONCTION...: Menage
# ENTREE.....: Plusieurs parametres
# SORTIE.....: Aucun.
# DESCRIPTION: Effacer le(s) fichier(s) dans le repertoire du jour.
#
###############################################################################
Menage ()
{
 wlog "...Menage pour usager $USAGER.tar.gz"
 if [ $JouMoi = 01 \
    -o $JouMoi = 08 \
    -o $JouMoi = 16 \
    -o $JouMoi = 24 ]; then
       if [ -e $BckDir$JouMoi/$USAGER.tar.gz ]; then
          rm -f $BckDir$JouMoi/$USAGER.tar.gz >/dev/null
          wlog "...Supression $USAGER.tar.gz dans $BckDir$JouMoi. RC=$?"
       fi
 fi
 if [ -e $BckDir$JouSem/$USAGER.tar.gz ]; then
    rm -f $BckDir$JouSem/$USAGER.tar.gz >/dev/null
    wlog "...Supression $USAGER.tar.gz dans $BckDir$JouSem. RC=$?"
 fi
}

###############################################################################
#
# FONCTION...: ArcHome
# ENTREE.....: Plusieurs parametres.
# SORTIE.....: Aucun.
# DESCRIPTION: Si mode = (N)ormal, on archive le repertoire recu en parametre
#
###############################################################################
ArcHome ()
{
 wlog "Traitement pour usager $USAGER:"
 Menage
 wlog "...Debut de l'archivage pour usager $USAGER"
 cd /home
 if [ -d $USAGER ]; then                       # Si l'usager recu a un home.
    wlog "...Execution commande tar pour /home/$USAGER"
    if [ $MODE == "N" ]; then                # Si en mode normal ou dry run.       
       tar -czf $USAGER.tar.gz $USAGER/
    else
       touch $USAGER.tar.gz $USAGER/ >/dev/null   
    fi
    wlog "...Fin execution commande tar. RC=$?"
    chown $USAGER $USAGER.tar.gz
    wlog "...Attribution du droit d'acces proprio sur $USAGER.tar.gz. RC=$?"
    chgrp $USAGER $USAGER.tar.gz
    wlog "...Attribution du doit d'acces groupe sur $USAGER.tar.gz. RC=$?"
    wlog "...Fin de l'archivage pour usager $USAGER."
    CopFic
 else
    wlog "ATTENTION: Le reptertoire /home/$USAGER n'existe pas."
 fi
}

###############################################################################
#
# FONCTION...: CopFic
# ENTREE.....: Plusieurs parametres.
# SORTIE.....: Aucun.
# DESCRIPTION: Copie du fichier [usager].tar.gz
#
###############################################################################
CopFic ()
{
   if [ $JouMoi = 01 \
      -o $JouMoi = 08 \
      -o $JouMoi = 16 \
      -o $JouMoi = 24 ]; then
      wlog "...Nous sommes le $JouMoi du mois. Copie hebdomadaire."
      # cp -f pour force, -p pour preserver les attributs du fichier
      cp -fp /home/$USAGER.tar.gz $BckDir$JouMoi >/dev/null
      wlog "...Copie hebdomadaire placee dans $BckDir$JouMoi. RC=$?"
   fi
   mv -f /home/$USAGER.tar.gz $BckDir$JouSem >/dev/null
   wlog "...Copie de $USAGER.tar.gz dans $BckDir$JouSem. RC=$?"
}

###############################################################################
#
# FONCTION...: VerifierRepertoires
# ENTREE.....: Plusieurs parametres.
# SORTIE.....: Aucun.
# DESCRIPTION: Verification des repertoires de backup
#
###############################################################################
VerifierRepertoires ()
{
 if [ ! -d "/var/log/$HOSTNAME" ]; then
    mkdir "/var/log/$HOSTNAME"
 fi

 wlog "Verification des repertoires de backup"
 if [ -d $BckDir ]; then
    cd $BckDir
    for Jou in "01" "08" "16" "24" "dimanche" "lundi" "mardi" "mercredi" "jeudi" "vendredi" "samedi"
    do
       if [ ! -d "$Jou" ] ; then
          mkdir $Jou
          wlog "Creation du repertoire $Jou. RC=$?"
          chmod 666 $Jou
          wlog "Modification du droit d'acces pour repertoire $Jou. RC=$?"
       fi
    done
 else
    wlog "ERREUR FATALE: $BckDir n'existe pas."
    exit 555
 fi
}

###############################################################################
#
# FONCTION...: Validation
# ENTREE.....: Aucun.
# SORTIE.....: Aucun.
# DESCRIPTION: Valide si $USER est bien root.
#
###############################################################################
Validation ()
{
 # Execution avec root seulement.
 if [ "$EUID" -ne 0 ]; then
    wlog "ERREUR FATALE: Seul root peut executer ce script."
    exit $E_NOTROOT
 fi
 VerifierRepertoires
}

###############################################################################
#
# FONCTION...: ArcPub
# ENTREE.....: Plusieurs parametres.
# SORTIE.....: Aucun.
# DESCRIPTION: Archive des repertoires publiques.
#
###############################################################################
ArcPub ()
{
 wlog "Archive des repertoires publiques."
 if [ -d $PubDir ]; then
    if [ -e $BckDir$JouSem/$PubDirNam.tar.gz ]; then
       rm -f $BckDir$JouSem/$PubDirNam.tar.gz
       wlog "Supression de $BckDir$JouSem/$PubDirNam.tar.gz. RC=$?"
    fi
    wlog "Archivage de $BckDir$JouSem/$PubDirNam.tar.gz."
    cd $PubDir
    if [ $MODE == "N" ]; then                # Si en mode normal ou dry run.       
        tar -czf $BckDir$JouSem/$PubDirNam.tar.gz $PubDirNam/
    else
        touch $BckDir$JouSem/$PubDirNam.tar.gz
    fi
    wlog "Archivage $BckDir$JouSem/$PubDirNam.tar.gz complete. RC=$?"
 else
    wlog "ATTENTION: le repertoire $PubDir n'existe pas."
 fi
}

###############################################################################
#
# FONCTION...: ServerInfo
# DESCRIPTION: Information du serveur
# ENTREE.....: Aucun.
# SORTIE.....: Aucun.
# Pour l'utilitaire de temp. disque: apt-get install hddtemp
# Pour l'utilitaire de temp. serveur: apt-get install lm-sensors ensuite,
# faire un sensors-detect pour identifier le type de CPU.
#
###############################################################################
ServerInfo ()
{
 # Extraction temperature
 SdaTem=`hddtemp -nuc /dev/sda1`
 LigBru=`sensors | grep °C | tr -d '+'`
 #Affichera «temp1:        36.0°C  (crit = 100.0°C)»
 SenTem=${LigBru:13:7}

 # Calcul du uptime
 upt=`/usr/bin/cut -d. -f1 /proc/uptime`
 days=$((upt/60/60/24))
 hours=$((upt/60/60%24))
 mins=$((upt/60%60))
 secs=$((upt%60))
 # Process
 ProAct=`ps -A h | wc -l`

 # Affichage des resultats
 wlog "En fonction depuis......: $days jour(s) $hours H $mins M"
 wlog "Process ID..............: $$"
 wlog "Nombre de process actifs: $ProAct"
 wlog "Temperature disque(s)...: $SdaTem°C"
 wlog "Temperature serveur.....: $SenTem"
}

###############################################################################
#
# FONCTION...: AddCfgFil
# ENTREE.....: Aucun.
# SORTIE.....: Aucun.
# DESCRIPTION: Achive les fichiers de configuration.
#
###############################################################################
BackupConfigFiles ()
{
 wlog "Backup des fichiers de configuration."
 if [ ! -d /tmp/$JOURANNEE ]; then
    mkdir /tmp/$JOURANNEE
 fi
 AddCfgFil /etc/ntp.conf
 AddCfgFil /etc/samba/smb.conf
 AddCfgFil /etc/exports
 AddCfgFil /etc/ssmtp/ssmtp.conf
 AddCfgFil /etc/vim/vimrc.local
 AddCfgFil /etc/network/interfaces
 AddCfgFil /etc/profile.d/welcome.sh

 cd /tmp/$JOURANNEE
 tar -czf cfgfiles.tar.gz * > /dev/null
 cp /tmp/$JOURANNEE/cfgfiles.tar.gz $BckDir$JouSem

 rm -rf *
 cd ..
 rmdir $JOURANNEE

}
###############################################################################
#
# FONCTION...: AddCfgFil
# ENTREE.....: $1 fichier a copier
# SORTIE.....: Aucun.
# DESCRIPTION: Achive les fichiers de configuration.
#
###############################################################################
AddCfgFil ()
{
 if [ -e "$1" ]; then
    cp $1 /tmp/$JOURANNEE
    wlog "Fichier de configuration $1 present et copie."
 else
    wlog "Fichier de configuration $1 introuvable."
 fi
}

###############################################################################
#
#      +---+---+---+---+---+---+---+---+---+---+---+
#      | M | A | I | N |   | S | C | R | I | P | T |
#      +---+---+---+---+---+---+---+---+---+---+---+
#
###############################################################################
# Verification si on execute en mode 'dry run'
Validation
if [ $# -gt 0 ]; then
   if [ "$1" == "-d" ]; then
       MODE="d"
       wlog "EXECUTION EN MODE DRY RUN."
   fi
fi
wlog "..--==[ DEBUT DE L'EXECUTION ]==--.."
ServerInfo
Validation
for USAGER in $(awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $1 }' "$_p" )
do
   ArcHome $USAGER
done
ArcPub
BackupConfigFiles
ServerInfo
FinTraitement
cd $StrDir
exit 0
