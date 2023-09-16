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

yum install nginx -y &>>$LOGFILE

VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOGFILE

VALIDATE $? "Enabling Nginx"

systemctl start nginx &>>$LOGFILE

VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE

VALIDATE $? "Removing default index html files"

rm -fr /tmp/web.zip

curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip &>>$LOGFILE

VALIDATE $? "Downloading web artifact"

cd /usr/share/nginx/html &>>$LOGFILE

VALIDATE $? "Moving to default HTML directory"

unzip /tmp/web.zip &>>$LOGFILE

VALIDATE $? "unzipping web artifact"

rm -fr /etc/nginx/default.d/roboshop.conf

echo "proxy_http_version 1.1;" >> /etc/nginx/default.d/roboshop.conf
echo "location /images/ {" >> /etc/nginx/default.d/roboshop.conf
echo "   expires 5s;" >> /etc/nginx/default.d/roboshop.conf
echo "   root   /usr/share/nginx/html;" >> /etc/nginx/default.d/roboshop.conf
echo "   try_files $uri /images/placeholder.jpg;" >> /etc/nginx/default.d/roboshop.conf
echo "}" >> /etc/nginx/default.d/roboshop.conf
echo "location /api/catalogue/ { proxy_pass http://catalogue.ravistarfuture.online:8080/; }" >> /etc/nginx/default.d/roboshop.conf
echo "location /api/user/ { proxy_pass http://user.ravistarfuture.online:8080/; }" >> /etc/nginx/default.d/roboshop.conf
echo "location /api/cart/ { proxy_pass http://cart.ravistarfuture.online:8080/; }" >> /etc/nginx/default.d/roboshop.conf
echo "location /api/shipping/ { proxy_pass http://shipping.ravistarfuture.online:8080/; }" >> /etc/nginx/default.d/roboshop.conf

echo "location /api/payment/ { proxy_pass http://payment.ravistarfuture.online:8080/; }" >> /etc/nginx/default.d/roboshop.conf
echo "location /health {" >> /etc/nginx/default.d/roboshop.conf
echo "stub_status on;" >> /etc/nginx/default.d/roboshop.conf
echo "access_log off;" >> /etc/nginx/default.d/roboshop.conf
echo "}" >> /etc/nginx/default.d/roboshop.conf


VALIDATE $? "copying roboshop config"

systemctl restart nginx  &>>$LOGFILE

VALIDATE $? "Restarting Nginx"