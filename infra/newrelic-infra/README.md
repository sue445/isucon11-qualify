`/etc/newrelic-infra/integrations.d` にシンボリックリンクを貼って使う

# Ubuntu
```bash
sudo apt-get install -y nri-nginx nri-mysql nri-redis nri-memcached
```

# CentOS
```bash
sudo yum install -y nri-nginx nri-mysql nri-redis nri-memcached
```

# シンボリックリンクを貼る
```bash
sudo rm -rf /etc/newrelic-infra/integrations.d
sudo ln -s /home/isucon/APP_NAME/infra/newrelic-infra/integrations.d /etc/newrelic-infra/integrations.d
```

# MySQL
```sql
CREATE USER 'newrelic'@'localhost' IDENTIFIED BY 'newrelic' WITH MAX_USER_CONNECTIONS 5;
GRANT SELECT ON *.* TO 'newrelic'@'localhost';
GRANT REPLICATION CLIENT ON *.* TO 'newrelic'@'localhost' WITH MAX_USER_CONNECTIONS 5;
GRANT SELECT ON *.* TO 'newrelic'@'localhost' WITH MAX_USER_CONNECTIONS 5;
```
