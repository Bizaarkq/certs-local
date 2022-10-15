#!/bin/sh

CONFIG_FILE=$(pwd)/site/app/config/parameters.php

helpFunction()
{
    echo ""
    echo "Uso: $0 \n--new-db-user olduser newuser \n--new-password oldpassword newpassword \n--new-db-host old host newhost \n--new-db-port oldport port \n--new-dbname olddbname newdbname \n--new-db-prefix oldprefix newprefix \n--restore \n--help"
    echo "\t-nu  | --new-db-user Nuevo usuario de la base de datos"
    echo "\t-np  | --new-password Nueva contraseña de la base de datos"
    echo "\t-nh  | --new-db-host Nuevo host de la base de datos"
    echo "\t-npo | --new-db-port Nuevo puerto de la base de datos"
    echo "\t-ndb | --new-dbname Nuevo nombre de la base de datos"
    echo "\t-np  | --new-db-prefix Nuevo prefijo de la base de datos"
    echo "\t-r   | --restore Restaurar los parametros de la base de datos"
    echo "\t-h  | --help muestra la ayuda"
    exit 1 # Salida del script luego de mostrar el uso
}

while [ $# -gt 0 ] ; do
    case $1 in
        -nu | --new-db-user) NEW_DB_USER="$2" ;;
        -np | --new-password) NEW_DB_PASSWORD="$2" ;;
        -nh | --new-db-host) NEW_DB_HOST="$2" ;;
        -npo | --new-db-port) NEW_DB_PORT="$2" ;;
        -ndb | --new-dbname) NEW_DB_NAME="$2" ;;
        -np | --new-db-prefix) NEW_DB_PREFIX="$2" ;;
        -r | --restore) RESTORE=true ;;
        -h | --help) helpFunction ;; # Imprime helpFunction
        ? ) helpFunction ;; # Imprime helpFunction en caso de que un parametro no exista
    esac
    shift
done

if [ -z $NEW_DB_USER ] && [ -z $NEW_DB_PASSWORD ] && [ -z $NEW_DB_HOST ] && [ -z $NEW_DB_PORT ] && [ -z $NEW_DB_NAME ] && [ -z $NEW_DB_PREFIX ] ; then
    echo "No se ha seleccionado ninguna opcion de backup"
    helpFunction
else 
    cp $CONFIG_FILE $CONFIG_FILE.bak
fi

if [ $RESTORE ] ; then
    cp $CONFIG_FILE.bak $CONFIG_FILE
    exit 0
fi

if [ ! -z $NEW_DB_USER ] ; then
    sed -i "s/$(grep database_user $CONFIG_FILE | cut -d "'" -f 4)/$NEW_DB_USER/g" $CONFIG_FILE
    echo "Se ha cambiado el usuario de la base de datos"
fi

if [ ! -z $NEW_DB_PASSWORD ] ; then
    sed -i "s/$(grep database_password $CONFIG_FILE | cut -d "'" -f 4)/$NEW_DB_PASSWORD/g" $CONFIG_FILE
    echo "Se ha cambiado la contraseña de la base de datos"
fi

if [ ! -z $NEW_DB_HOST ] ; then
    sed -i "s/$(grep database_host $CONFIG_FILE | cut -d "'" -f 4)/$NEW_DB_HOST/g" $CONFIG_FILE
    echo "Se ha cambiado el host de la base de datos"
fi

if [ ! -z $NEW_DB_PORT ] ; then
    sed -i "s/$(grep database_port $CONFIG_FILE | cut -d "'" -f 4)/$NEW_DB_PORT/g" $CONFIG_FILE
    echo "Se ha cambiado el puerto de la base de datos"
fi

if [ ! -z $NEW_DB_NAME ] ; then
    sed -i "s/$(grep database_name $CONFIG_FILE | cut -d "'" -f 4)/$NEW_DB_NAME/g" $CONFIG_FILE
    echo "Se ha cambiado el nombre de la base de datos"
fi

if [ ! -z $NEW_DB_PREFIX ] ; then
    sed -i "s/$(grep database_prefix $CONFIG_FILE | cut -d "'" -f 4)/$NEW_DB_PREFIX/g" $CONFIG_FILE
    echo "Se ha cambiado el prefijo de la base de datos"
fi

exit 0