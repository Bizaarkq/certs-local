#!/bin/sh

helpFunction()
{
    echo ""
    echo "Uso: $0 --backup-global --site-backup --db-backup --containers-backup --ssl-backup"
    echo $"\t-bg | --backup-global Realiza backup de todo el sistema"
    echo $"\t-sb | --site-backup Realizar backup del sitio"
    echo $"\t-db | --db-backup Realizar backup de la base de datos"
    echo $"\t-cb | --containers-backup Realizar backup de los contenedores"
    echo $"\t-ssl | --ssl-backup Realizar backup de los certificados"
    echo $"\t-h | --help muestra la ayuda"
    exit 1 # Salida del script luego de mostrar el uso
}

while [ $# -gt 0 ] ; do
    case $1 in
        -bg | --backup-global) BACKUP_GLOBAL=true ;;
        -sb | --site-backup) SITE_BACKUP=true ;;
        -db | --db-backup) DB_BACKUP=true ;;
        -cb | --containers-backup) CONTAINERS_BACKUP=true ;;
        -ssl | --ssl-backup) SSL_BACKUP=true ;;
        -h | --help) helpFunction ;; # Imprime helpFunction
        ? ) helpFunction ;; # Imprime helpFunction en caso de que un parametro no exista
    esac
    shift
done

if [ -z $BACKUP_GLOBAL ] && [ -z $SITE_BACKUP ] && [ -z $DB_BACKUP ] && [ -z $CONTAINERS_BACKUP ] && [ -z $SSL_BACKUP ] ; then
    echo "No se ha seleccionado ningun backup"
    helpFunction
fi

if [ "$BACKUP_GLOBAL" = true ] ; then
    SITE_BACKUP=true
    DB_BACKUP=true
    CONTAINERS_BACKUP=true
    SSL_BACKUP=true
fi

if [ "$SITE_BACKUP" = true ] ; then
    #respaldando datos del sistema
    echo $"\n\n###########   Respaldando datos del sistema  ############\n\n"
    mkdir -p $(pwd)/backup/site
    tar -zcvpf $(pwd)/backup/site/site-kedetalles-$(date +%Y%m%d%H%M%S).tgz site/
fi

if [ "$DB_BACKUP" = true ] ; then
    #respaldando base de datos
    echo $"\n\n###########   Respaldando base de datos  ############\n\n"
    mkdir -p $(pwd)/backup/db
    docker exec kedetalles-db-1 /usr/bin/mysqldump -u user --password=02Hb@8M!lDja prestashop > $(pwd)/backup/db/db-kedetalles-$(date +%Y%m%d%H%M%S).sql
fi

if [ "$CONTAINERS_BACKUP" = true ] ; then
    #respaldando contenedores
    echo $"\n\n###########   Respaldando contenedores  ############\n\n"
    mkdir -p $(pwd)/backup/containers/app $(pwd)/backup/containers/db $(pwd)/backup/containers/nginx
    docker export kedetalles-app-1 > $(pwd)/backup/containers/app/app-bk-$(date +%Y%m%d%H%M%S).tar
    docker export kedetalles-db-1 > $(pwd)/backup/containers/db/db-bk-$(date +%Y%m%d%H%M%S).tar
    docker export kedetalles-nginx-1 > $(pwd)/backup/containers/nginx/nginx-bk-$(date +%Y%m%d%H%M%S).tar
fi

if [ "$SSL_BACKUP" = true ] ; then
    #respaldando certificados
    echo $"\n\n###########   Respaldando certificados  ############\n\n"
    mkdir -p $(pwd)/backup/ssl
    tar -zcvpf $(pwd)/backup/ssl/ssl-kedetalles-$(date +%Y%m%d%H%M%S).tgz ssl/
fi

