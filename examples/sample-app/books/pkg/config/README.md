# MYSQL for local-dev

## Run Docker container

```
docker run \
--detach \
--name=mysql \
--env="MYSQL_ROOT_PASSWORD=root123" \
--publish 6603:3306 \
--volume=/storage/docker/mysql-data:/var/lib/mysql \
mysql
```

## connect

```
mysql -uroot  -hlocalhost -P6603 --protocol=tcp -proot123
```

