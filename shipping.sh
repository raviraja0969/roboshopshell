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

yum install maven -y &>>$LOGFILE

VALIDATE $? "Installing Maven"

rm -fr /app
rm -fr /tmp/shipping.zip

useradd roboshop &>>$LOGFILE

mkdir /app &>>$LOGFILE

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>>$LOGFILE

VALIDATE $? "Downloading shipping artifact"

cd /app &>>$LOGFILE

VALIDATE $? "Moving to app directory"
 
unzip /tmp/shipping.zip &>>$LOGFILE

VALIDATE $? "Unzipping shipping"

mvn clean package &>>$LOGFILE

VALIDATE $? "packaging shipping app"

mv target/shipping-1.0.jar shipping.jar &>>$LOGFILE

VALIDATE $? "renaming shipping jar"

rm -fr /etc/systemd/system/shipping.service

echo "[Unit]" >> /etc/systemd/system/shipping.service
echo "Description = Shipping Service" >> /etc/systemd/system/shipping.service
echo "[Service]" >> /etc/systemd/system/shipping.service
echo "User=roboshop" >> /etc/systemd/system/shipping.service
echo "Environment=CART_ENDPOINT=cart.ravistarfuture.online:8080" >> /etc/systemd/system/shipping.service
echo "Environment=DB_HOST=mysql.joindevops.online" >> /etc/systemd/system/shipping.service
echo "ExecStart=/bin/java -jar /app/shipping.jar" >> /etc/systemd/system/shipping.service
echo "SyslogIdentifier=shipping" >> /etc/systemd/system/shipping.service

echo "[Install]" >> /etc/systemd/system/shipping.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/shipping.service


VALIDATE $? "copying shipping service"

systemctl daemon-reload &>>$LOGFILE

VALIDATE $? "daemon-reload"

systemctl enable shipping  &>>$LOGFILE

VALIDATE $? "Enabling shipping"

systemctl start shipping &>>$LOGFILE

VALIDATE $? "Starting shipping"


yum install mysql -y  &>>$LOGFILE

VALIDATE $? "Installing MySQL client"

mysql -h mysql.joindevops.online -uroot -pRoboShop@1 < /app/schema/shipping.sql  &>>$LOGFILE

VALIDATE $? "Loaded countries and cities info"

systemctl restart shipping &>>$LOGFILE

VALIDATE $? "Restarting shipping"