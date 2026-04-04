#!/bin/bash
EXTENSION=exec
SEARCHPATH=/
REPO='yum.puppet.com'


DIST_VER=`cat /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -E "^NAME=" | grep -o -P '(?<=").*?(?=")'`

case $DIST_VER in


        [ "$DIST_VER" == "AlmaLinux" ] ||
        [ "$DIST_VER" == "Fedora Linux"] ||
        [ "$DIST_VER" == "Oracle Linux" ] ||
        [ "$DIST_VER" == "Rocky Linux" ] ||   
        [ "$DIST_VER" == "CentOS Linux"] ;;
  2)
    echo "You selected Two."
    ;;
  3)
    echo "You selected Three."
    ;;
  *)
    echo "Invalid selection. Please choose a number between 1 and 3."
    ;;
esac


for i in "$@"; do
  case $i in
    -e=*|--extension=*)
      EXTENSION="${i#*=}"
      shift # past argument=value
      ;;
    -s=*|--searchpath=*)
      SEARCHPATH="${i#*=}"
      shift # past argument=value
      ;;
    --default)
      DEFAULT=YES
      shift # past argument with no value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

echo "FILE EXTENSION  = ${EXTENSION}"
echo "SEARCH PATH     = ${SEARCHPATH}"
echo "DEFAULT         = ${DEFAULT}"
echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)

if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
fi
