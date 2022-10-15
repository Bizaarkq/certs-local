#!/bin/sh

helpFunction()
{
    echo ""
    echo "Uso: $0 --restore-global --site-restore --db-restore --containers-restore --ssl-restore"
    echo $"\t-rg | --restore-global Restaurar ultimo backup de todo el sistema"
    echo $"\t-sr | --site-restore Restaurar ultimo backup del sitio"
    echo $"\t-dr | --db-restore Restaurar ultimo backup de la base de datos"
    echo $"\t-cr | --containers-restore Restaurar ultimo backup de los contenedores"
    echo $"\t-ssl | --ssl-restore Restaurar ultimo backup de los certificados"
    echo $"\t-h | --help muestra la ayuda"
    exit 1 # Salida del script luego de mostrar el uso
}

while [ $# -gt 0 ] ; do
    case $1 in
        -rg | --restore-global) RESTORE_GLOBAL=true ;;
        -sr | --site-restore) SITE_RESTORE=true ;;
        -dr | --db-restore) DB_RESTORE=true ;;
        -cr | --containers-restore) CONTAINERS_RESTORE=true ;;
        -ssl | --ssl-restore) SSL_RESTORE=true ;;
        -h | --help) helpFunction ;; # Imprime helpFunction
        ? ) helpFunction ;; # Imprime helpFunction en caso de que un parametro no exista
    esac
    shift
done

if [ -z $RESTORE_GLOBAL ] && [ -z $SITE_RESTORE ] && [ -z $DB_RESTORE ] && [ -z $CONTAINERS_RESTORE ] && [ -z $SSL_RESTORE ] ; then
    echo "No se ha seleccionado ningun backup"
    helpFunction
fi

if [ "$RESTORE_GLOBAL" = true ] ; then
    SITE_RESTORE=true
    DB_RESTORE=true
    CONTAINERS_RESTORE=true
    SSL_RESTORE=true
fi
backup
if [ "$SITE_RESTORE" = true ] ; then
    echo "Restaurando sitio"
    rm -r $(pwd)/site/*
    tar -xpvf $(pwd)/backup/site/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') -C $(pwd)
fi

if [ "$DB_RESTORE" = true ] ; then
    echo "Restaurando base de datos"
    cat $(pwd)/backup/db/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') | docker exec -i kedetalles-db-1 /usr/bin/mysql -u root --password=02Hb@8M!lDja prestashop
fi

if [ "$CONTAINERS_RESTORE" = true ] ; then
    echo "Restaurando contenedores"
    docker rm -f $(docker ps -a -q)
    docker rmi -f nginx:stable mysql:5.7 kedetalles-app:latest
    docker import $(pwd)/backup/containers/web/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') nginx:stable
    docker import $(pwd)/backup/containers/db/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') mysql:5.7
    docker import $(pwd)/backup/containers/app/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') kedetalles-app:latest
    docker compose -f docker-compose-bk.yml up -d
fi

if [ "$SSL_RESTORE" = true ] ; then
    echo "Restaurando certificados"
    rm -r $(pwd)/ssl/*
    tar -xpvf $(pwd)/backup/ssl/$(ls | awk -F- 'm<$3{m=$3;f=$0} END{print f}') -C $(pwd)
fi

