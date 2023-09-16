#!/bin/bash

DATE=$(date +%F)
LOGSDIR=/tmp
# /home/centos/shellscript-logs/script-name-date.log
SCRIPT_NAME=$0
LOGFILE=$LOGSDIR/$0-$DATE.log
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

if [ $USERID -ne 0 ];
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ];
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

yum module disable mysql -y &>> $LOGFILE

VALIDATE $? "Disabling the default version"

[mysql]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/7/$basearch/
enabled=1
gpgcheck=0

rm -fr /etc/yum.repos.d/mysql.repo

echo "[mysql]" >> /etc/yum.repos.d/mysql.repo
echo "name=MySQL 5.7 Community Server" >> /etc/yum.repos.d/mysql.repo
echo "baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/7/\$basearch/" >> /etc/yum.repos.d/mysql.repo
echo "enabled=1" >> /etc/yum.repos.d/mysql.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/mysql.repo

VALIDATE $? "Copying MySQL repo" 

yum install mysql-community-server -y &>> $LOGFILE

VALIDATE $? "Installing MySQL Server"

systemctl enable mysqld &>> $LOGFILE

VALIDATE $? "Enabling MySQL"

systemctl start mysqld &>> $LOGFILE

VALIDATE $? "Staring MySQL"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $LOGFILE

VALIDATE $? "setting up root password"