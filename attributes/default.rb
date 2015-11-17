default["mariadb"]["full_version"] = "5.5.44-1.el7"
default["mariadb"]["version"] = "5.5.44"
default["mariadb"]["conf"]["path"] = "/etc/my.cnf"
default["mariadb"]["conf"]["pid_dir"] = "/var/run/mariadb"
default["mariadb"]["conf"]["pid_file"] = "/var/run/mariadb/mariadb.pid"
default["mariadb"]["conf"]["socket"] = "/var/lib/mysql/mysql.sock"
default["mariadb"]["conf"]["error_log"] = "/var/log/mysqld.log"
default["mariadb"]["conf"]["slow_query_log"] = "/var/log/slow_query.log"

# Application's data
default["mariadb"]["application"]["db_name"] = node["application"]["mariadb"]["db_name"] || nil
default["mariadb"]["application"]["db_user"] = node["application"]["mariadb"]["db_user"] || nil
default["mariadb"]["application"]["db_password"] = node["application"]["mariadb"]["db_password"] || nil
