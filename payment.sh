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

yum install python36 gcc python3-devel -y &>>$LOGFILE

VALIDATE $? "Installing python"

rm -fr /app
rm -fr /tmp/payment.zip

useradd roboshop &>>$LOGFILE

mkdir /app  &>>$LOGFILE

curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>>$LOGFILE

VALIDATE $? "Downloading artifact"

cd /app &>>$LOGFILE

VALIDATE $? "Moving to app directory"

unzip /tmp/payment.zip &>>$LOGFILE

VALIDATE $? "unzip artifact"

pip3.6 install -r requirements.txt &>>$LOGFILE

VALIDATE $? "Installing dependencies"
rm -fr /etc/systemd/system/payment.service

echo "[Unit]" >> /etc/systemd/system/payment.service
echo "Description = Payment Service" >> /etc/systemd/system/payment.service
echo "[Service]" >> /etc/systemd/system/payment.service
echo "User=root" >> /etc/systemd/system/payment.service
echo "WorkingDirectory=/app" >> /etc/systemd/system/payment.service
echo "Environment=CART_HOST=cart.joindevops.online" >> /etc/systemd/system/payment.service
echo "Environment=CART_PORT=8080" >> /etc/systemd/system/payment.service
echo "Environment=USER_HOST=user.joindevops.online" >> /etc/systemd/system/payment.service
echo "Environment=USER_PORT=8080" >> /etc/systemd/system/payment.service
echo "Environment=AMQP_HOST=rabbitmq.joindevops.online" >> /etc/systemd/system/payment.service
echo "Environment=AMQP_USER=roboshop" >> /etc/systemd/system/payment.service
echo "Environment=AMQP_PASS=roboshop123" >> /etc/systemd/system/payment.service
echo "ExecStart=/usr/local/bin/uwsgi --ini payment.ini" >> /etc/systemd/system/payment.service
echo "ExecStop=/bin/kill -9 \$MAINPID" >> /etc/systemd/system/payment.service

echo "SyslogIdentifier=payment" >> /etc/systemd/system/payment.service
echo "[Install]" >> /etc/systemd/system/payment.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/payment.service

VALIDATE $? "copying payment service"

systemctl daemon-reload &>>$LOGFILE

VALIDATE $? "daemon-reload"

systemctl enable payment  &>>$LOGFILE

VALIDATE $? "enable payment"

systemctl start payment &>>$LOGFILE

VALIDATE $? "starting payment"