#
# Cookbook Name:: mariadb
# Recipe:: default
#
# Copyright 2015, Simone Dall Angelo
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#
# Cookbook Name:: mariadb
# Recipe:: default
#
# Copyright 2015, Simone Dall Angelo
#
# All rights reserved - Do Not Redistribute
#

# Add yum repo
file "/etc/yum.repos.d/MariaDB.repo" do
  owner 'root'
  group 'root'
  content "[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/#{node["mariadb"]["version"]}/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=0"
end

# Force remove of mariadb-libs (conflict with next packages)
package 'mariadb-libs' do
  action :remove
end

# FIX to solve a problem on server reboot (while mysql is running)
file "/etc/tmpfiles.d/mysql.conf" do
  owner 'root'
  group 'root'
  content "# systemd tmpfile settings for mysql
# See tmpfiles.d(5) for details

d #{node["mariadb"]["conf"]["pid_dir"]} 0755 mysql mysql -
"
end

# Install packages
bash 'Install MariaDB packages' do
  code <<-EOF
    yum install mariadb-server mariadb-devel -y --enablerepo 'mariadb'
  EOF
end

# Setup config /etc/my.cnf
template node["mariadb"]["conf"]["path"] do
  source "my.cnf.erb"
  owner 'root'
  group 'root'
  mode 0644
end

# Create /var/run/mariadb directory
directory node["mariadb"]["conf"]["pid_dir"] do
  action :create
  owner 'mysql'
  group 'mysql'
  mode 0755
end

# Touch mysql log file
file node["mariadb"]["conf"]["error_log"] do
  action :create_if_missing
  owner 'mysql'
  group 'mysql'
  mode 0644
end

# Touch /var/log/slow_query.log
file node["mariadb"]["conf"]["slow_query_log"] do
  action :create_if_missing
  owner 'mysql'
  group 'mysql'
end

# Enable and start (from MariaDB repo installation, the service is called 'mysql')
service "mysql" do
  action [:enable, :restart]
end

# Execute mysql_secure_installation by hand
bash 'mysql_secure_installation' do
  code <<-EOF
    mysql -e "UPDATE mysql.user SET Password = PASSWORD('#{node["mariadb"]["users"]["root"]["password"]}') WHERE User = 'root'"
    mysql -e "DROP USER ''@'localhost'"
    mysql -e "DROP USER ''@'$(hostname)'"
    mysql -e "DROP DATABASE test"
    mysql -e "FLUSH PRIVILEGES"
  EOF
  only_if "mysql -uroot"
end

# Create application's user and db
bash "Create application's user and db" do
  code <<-EOF
    mysql -uroot -p#{node["mariadb"]["users"]["root"]["password"]} -e "CREATE DATABASE #{node["mariadb"]["application"]["db_name"]} CHARACTER SET utf8 COLLATE utf8_general_ci;"
    mysql -uroot -p#{node["mariadb"]["users"]["root"]["password"]} -e "CREATE USER '#{node["mariadb"]["application"]["db_user"]}'@'127.0.0.1' identified by '#{node["mariadb"]["application"]["db_password"]}';"
    mysql -uroot -p#{node["mariadb"]["users"]["root"]["password"]} -e "CREATE USER '#{node["mariadb"]["application"]["db_user"]}'@'localhost' identified by '#{node["mariadb"]["application"]["db_password"]}';"
    mysql -uroot -p#{node["mariadb"]["users"]["root"]["password"]} -e "GRANT ALL PRIVILEGES ON #{node["mariadb"]["application"]["db_name"]}.* to '#{node["mariadb"]["application"]["db_user"]}'@'localhost' WITH GRANT OPTION;"
    mysql -uroot -p#{node["mariadb"]["users"]["root"]["password"]} -e "GRANT ALL PRIVILEGES ON #{node["mariadb"]["application"]["db_name"]}.* to '#{node["mariadb"]["application"]["db_user"]}'@'127.0.0.1' WITH GRANT OPTION;"
  EOF
end
