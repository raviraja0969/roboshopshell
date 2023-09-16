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

curl -sL https://rpm.nodesource.com/setup_lts.x | bash &>>$LOGFILE

VALIDATE $? "Setting up NPM Source"

yum install nodejs -y &>>$LOGFILE

VALIDATE $? "Installing NodeJS"
rm -fr /app

rm -fr /tmp/user.zip
#once the user is created, if you run this script 2nd time
# this command will defnitely fail
# IMPROVEMENT: first check the user already exist or not, if not exist then create
useradd roboshop &>>$LOGFILE

#write a condition to check directory already exist or not
mkdir /app &>>$LOGFILE

curl -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip &>>$LOGFILE

VALIDATE $? "downloading cart artifact"

cd /app &>>$LOGFILE

VALIDATE $? "Moving into app directory"

unzip /tmp/cart.zip &>>$LOGFILE

VALIDATE $? "unzipping cart"

npm install &>>$LOGFILE

VALIDATE $? "Installing dependencies"

rm -fr /etc/systemd/system/cart.service

echo "[Unit]" >> /etc/systemd/system/cart.service
echo "Description = Cart Service" >> /etc/systemd/system/cart.service
echo "[Service]" >> /etc/systemd/system/cart.service
echo "User=roboshop" >> /etc/systemd/system/cart.service
echo "Environment=REDIS_HOST=redis.ravistarfuture.online" >> /etc/systemd/system/cart.service
echo "Environment=CATALOGUE_HOST=catalogue.ravistarfuture.online" >> /etc/systemd/system/cart.service
echo "Environment=CATALOGUE_PORT=8080" >> /etc/systemd/system/cart.service
echo "ExecStart=/bin/node /app/server.js" >> /etc/systemd/system/cart.service

echo "SyslogIdentifier=cart" >> /etc/systemd/system/cart.service
echo "[Install]" >> /etc/systemd/system/cart.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/cart.service


VALIDATE $? "copying cart.service"

systemctl daemon-reload &>>$LOGFILE

VALIDATE $? "daemon reload"

systemctl enable cart &>>$LOGFILE

VALIDATE $? "Enabling cart"

systemctl start cart &>>$LOGFILE

VALIDATE $? "Starting cart"