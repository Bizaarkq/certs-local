#!/bin/sh
# dominio
DOMINIO="kedetalles.shop"
CORREO="bq18002@ues.edu.sv"
DB_PASSWORD="02Hb@8M!lDja"
FILE_DEFAULT_CONF="./conf/default.conf"
FILE_DOCKER_COMPOSE="./docker-compose.yml"
FILE_DOCKER_COMPOSE_BACKUP="./docker-compose-bk.yml"

helpFunction()
{
    echo ""
    echo "Uso: $0 \n--from-repo \n--site-backup /path/to/site/backup.tgz \n--db-backup /path/to/db/backup.sql \n--app-image-backup /path/to/app/image/backup.tar \n--db-image-backup /path/to/db/image/backup.tar \n--web-image-backup /path/to/web/image/backup.tar \n--ssl-backup /path/to/ssl/backup.tgz \n --domain domain.com --email email@email.com \n--db-password password"
    echo "\t-fr   | --from-repo: Instala desde el repositorio"
    echo $"\t-sb  | --site-backup Ruta donde se encuentra el backup del sitio"
    echo $"\t-db  | --db-backup Ruta donde se encuentra el backup de la base de datos"
    echo $"\t-dbp | --db-password Contraseña de la base de datos"
    echo $"\t-aib | --app-image-backup Ruta donde se encuentra el backup de la imagen de la app"
    echo $"\t-dib | --db-image-backup Ruta donde se encuentra el backup de la imagen de la base de datos"
    echo $"\t-wib | --web-image-backup Ruta donde se encuentra el backup de la imagen del servidor web"
    echo $"\t-ssl | --ssl-backup Ruta donde se encuentra el backup de los certificados"
    echo $"\t-d   | --domain Dominio del sitio"
    echo $"\t-e   | --email Correo electronico para notificaciones"
    echo $"\t-h   | --help muestra la ayuda"
    exit 1 # Salida del script luego de mostrar el uso
}

while [ $# -gt 0 ] ; do
    case $1 in
        -fr | --from-repo) FROM_REPO=true;;
        -sb | --site-backup) SITE_BACKUP="$2" ;;
        -db | --db-backup) DB_BACKUP="$2" ;;
        -aib | --app-image-backup) APP_CONTAINER_BACKUP="$2" ;;
        -dib | --db-image-backup) DB_CONTAINER_BACKUP="$2" ;;
        -wib | --web-image-backup) WEB_CONTAINER_BACKUP="$2" ;;
        -ssl | --ssl-backup) SSL_BACKUP="$2" ;;
        -d | --domain) DOMINIO="$2" ;;
        -e | --email) CORREO="$2" ;;
        -dbp | --db-password) DB_PASSWORD="$2" ;;
        -h | --help) helpFunction ;; # Imprime helpFunction
        ? ) helpFunction ;; # Imprime helpFunction en caso de que un parametro no exista
    esac
    shift
done

#instalando git y descargando repo con las configuraciones
echo $"\n\nInstalando git y descargando repo\n\n"
apt-get update
apt install -y git unzip apt-transport-https ca-certificates curl gnupg2 software-properties-common openssl
systemctl stop apache2.service

if [ "$FROM_REPO" = true ] ; then
    git clone https://github.com/Bizaarkq/certs-local.git kedetalles
fi

cd kedetalles/
mkdir -p db backup

#instalando docker
echo $"\n\n###########   Instalando docker  ############\n\n"
wget -O - https://download.docker.com/linux/debian/gpg | gpg --dearmor > /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg ] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt install -y docker-ce docker-compose-plugin
usermod -aG docker ${USER}

#creando proyecto prestashop
echo $"\n\n########### Creando proyecto prestashop ############\n\n"
mkdir -p site
if [ "$SITE_BACKUP" != "" ] ; then
    echo "cargando backup"
    tar -xpvf $SITE_BACKUP -C $(pwd)
else
    echo "descomprimiendo prestashop"
    unzip ./prestashop_1.7.8.7.zip -d ./site/
fi

#reemplazando dominio de la configuracion
if [ "$DOMINIO" != "" ] ; then
    sed -i "s/kedetalles.shop/$DOMINIO/g" $FILE_DEFAULT_CONF
fi

#reemplazando password db de la configuracion
if [ "$DB_PASSWORD" != "" ] ; then
    sed -i "s/02Hb@8M!lDja/$DB_PASSWORD/g" $FILE_DOCKER_COMPOSE
    sed -i "s/02Hb@8M!lDja/$DB_PASSWORD/g" $FILE_DOCKER_COMPOSE_BACKUP
fi

#certificados
echo $"\n\n###########   Generando certificados   ############\n\n"
mkdir -p ssl
if [ "$SSL_BACKUP" != "" ] ; then   
    tar -xpvf $SSL_BACKUP -C $(pwd)
else 
    openssl dhparam -out $(pwd)/ssl/dh_tx.4096.pem 4096
    docker run --rm --name certbot -p 80:80  -v $(pwd)/ssl:/etc/letsencrypt certbot/certbot certonly --standalone -d $DOMINIO --preferred-challenges http --agree-tos -n -m $CORREO --keep-until-expiring
fi

if [ "$DB_CONTAINER_BACKUP" != "" ] ; then
    echo $"\n\n########### importando backup de imagen de base de datos  ############\n\n"
    docker load -i $DB_CONTAINER_BACKUP
fi

if [ "$WEB_CONTAINER_BACKUP" != "" ] ; then
    echo $"\n\n########### importando backup de imagen de servidor ############\n\n"
    docker load -i $WEB_CONTAINER_BACKUP
fi


#levantando tienda
echo $"\n\n###########   Levantando tienda  ############\n\n"
if [ "$APP_CONTAINER_BACKUP" != "" ] ; then
    echo $"\n\n########### importando backup de imagen de app prestashop ############\n\n"
    docker load -i $APP_CONTAINER_BACKUP
    docker compose -f docker-compose-bk.yml up -d
else 
    docker compose -f docker-compose.yml up -d
fi

#dando permisos a la tienda
echo $"\n\n###########   Dando permisos a la tienda  ############\n\n"
chown www-data:www-data -R site/

if [ "$DB_BACKUP" != "" ] && [ "$DB_PASSWORD" != "" ]; then
    docker start kedetalles-db-1
    docker exec -i kedetalles-db-1 mysql -u root --password=$DB_PASSWORD prestashop < $DB_BACKUP 
fi

exit 0


