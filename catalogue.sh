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
curl -sL https://rpm.nodesource.com/setup_lts.x | bash &>> $LOGFILE
VALIDATE $? "curl -sL https://rpm.nodesource.com/setup_lts.x | bash"
yum install nodejs -y &>> $LOGFILE
VALIDATE $? "yum install nodejs"
useradd roboshop &>> $LOGFILE
VALIDATE $? "useradd roboshop"
rm -fr /app
rm -fr /tmp/catalogue.zip

mkdir /app &>> $LOGFILE
VALIDATE $? "/app created"
curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>> $LOGFILE
VALIDATE $? "curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip"
cd /app &>> $LOGFILE
VALIDATE $? "cd /app "
unzip /tmp/catalogue.zip &>> $LOGFILE
VALIDATE $? "unzip /tmp/catalogue.zip "
cd /app &>> $LOGFILE
VALIDATE $? "cd /app "
npm install &>> $LOGFILE
VALIDATE $? "npm install  "

rm -fr /etc/systemd/system/catalogue.service
echo "[Unit]" >> /etc/systemd/system/catalogue.service
echo "Description = Catalogue Service" >> /etc/systemd/system/catalogue.service
echo "[Service]" >> /etc/systemd/system/catalogue.service
echo "User=roboshop" >> /etc/systemd/system/catalogue.service

echo "Environment=MONGO=true" >> /etc/systemd/system/catalogue.service
echo "Environment=MONGO_URL="mongodb://mongodb.ravistarfuture.online:27017/catalogue"" >> /etc/systemd/system/catalogue.service
echo "ExecStart=/bin/node /app/server.js" >> /etc/systemd/system/catalogue.service
echo "SyslogIdentifier=catalogue" >> /etc/systemd/system/catalogue.service
echo "[Install]" >> /etc/systemd/system/catalogue.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/catalogue.service

systemctl daemon-reload &>> $LOGFILE

VALIDATE $? "systemctl daemon-reload "
systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "systemctl enable catalogue "
systemctl start catalogue &>> $LOGFILE
VALIDATE $? "systemctl start catalogue "

rm -fr /etc/yum.repos.d/mongo.repo
echo "[mongodb-org-4.2]" >> /etc/yum.repos.d/mongo.repo
echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongo.repo
echo "baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/" >> /etc/yum.repos.d/mongo.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/mongo.repo
echo "enabled=1" >> /etc/yum.repos.d/mongo.repo

yum install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "yum install mongodb-org-shell" 

mongo --host mongodb.ravistarfuture.online </app/schema/catalogue.js &>> $LOGFILE

VALIDATE $? "mongo --host mongodb.ravistarfuture.online </app/schema/catalogue.js" 



