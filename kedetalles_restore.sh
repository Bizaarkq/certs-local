#!/bin/sh

helpFunction()
{
    echo ""
    echo "Uso: $0 --restore-global --site-restore --especific-site-restore --db-restore --especific-db-restore --db-password --ssl-restore --especific-ssl-restore"
    echo $"\t-rg | --restore-global Restaurar ultimo backup de todo el sistema"
    echo $"\t-sr | --site-restore Restaurar ultimo backup del sitio"
    echo $"\t-es | --especific-site-restore Restaurar backup especifico del sitio"
    echo $"\t-dr | --db-restore Restaurar ultimo backup de la base de datos"
    echo $"\t-ed | --especific-db-restore Restaurar backup especifico de la base de datos"
    echo $"\t-dbp | --db-password contraseña de la base de datos"
    echo $"\t-ssl | --ssl-restore Restaurar ultimo backup de los certificados"
    echo $"\t-essl | --especific-ssl-restore Restaurar backup especifico de los certificados"
    echo $"\t-h | --help muestra la ayuda"
    exit 1 # Salida del script luego de mostrar el uso
}

while [ $# -gt 0 ] ; do
    case $1 in
        -rg | --restore-global) RESTORE_GLOBAL=true ;;
        -sr | --site-restore) SITE_RESTORE=true ;;
        -es | --especific-site-restore) ESPECIFIC_SITE_RESTORE="$2" ;;
        -dr | --db-restore) DB_RESTORE=true ;;
        -ed | --especific-db-restore) ESPECIFIC_DB_RESTORE="$2" ;;
        -dbp | --db-password) DB_PASSWORD="$2" ;;
        -ssl | --ssl-restore) SSL_RESTORE=true ;;
        -essl | --especific-ssl-restore) ESPECIFIC_SSL_RESTORE="$2" ;;
        -h | --help) helpFunction ;; # Imprime helpFunction
        ? ) helpFunction ;; # Imprime helpFunction en caso de que un parametro no exista
    esac
    shift
done

if [ -z $RESTORE_GLOBAL ] && [ -z $SITE_RESTORE ] && [ -z $ESPECIFIC_SITE_RESTORE ] && [ -z $DB_RESTORE ] && [ -z $ESPECIFIC_DB_RESTORE ] && [ -z $SSL_RESTORE ] && [ -z $ESPECIFIC_SSL_RESTORE ]; then
    echo "No se ha seleccionado ninguna opcion de restauracion"
    helpFunction
fi

if [ "$RESTORE_GLOBAL" = true ] ; then
    SITE_RESTORE=true
    DB_RESTORE=true
    SSL_RESTORE=true
fi

if [ "$SITE_RESTORE" = true ] ; then
    echo "Restaurando sitio"
    rm -r $(pwd)/site/
    tar -xpvf $(pwd)/backup/site/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') -C $(pwd)
fi

if [ "$DB_RESTORE" = true ] ; then
    echo "Restaurando base de datos"
    cat $(pwd)/backup/db/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') | docker exec -i kedetalles-db-1 /usr/bin/mysql -u root --password=02Hb@8M!lDja prestashop
fi

if [ "$SSL_RESTORE" = true ] ; then
    echo "Restaurando certificados"
    rm -r $(pwd)/ssl/*
    tar -xpvf $(pwd)/backup/ssl/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') -C $(pwd)
fi

if [ ! -z $ESPECIFIC_SITE_RESTORE ] ; then
    echo "Restaurando sitio especifico"
    rm -r $(pwd)/site/*
    tar -xpvf $ESPECIFIC_SITE_RESTORE -C $(pwd)
fi

if [ ! -z $ESPECIFIC_DB_RESTORE ] && [ ! -z $DB_PASSWORD ] ; then
    echo "Restaurando base de datos especifica"
    cat $ESPECIFIC_DB_RESTORE | docker exec -i kedetalles-db-1 /usr/bin/mysql -u root --password=$DB_PASSWORD prestashop
fi

if [ ! -z $ESPECIFIC_SSL_RESTORE ] ; then
    echo "Restaurando certificados especificos"
    rm -r $(pwd)/ssl/*
    tar -xpvf $ESPECIFIC_SSL_RESTORE -C $(pwd)
fi

