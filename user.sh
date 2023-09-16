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

#once the user is created, if you run this script 2nd time
# this command will defnitely fail
# IMPROVEMENT: first check the user already exist or not, if not exist then create
useradd roboshop &>>$LOGFILE

#write a condition to check directory already exist or not
mkdir /app &>>$LOGFILE

curl -o /tmp/user.zip https://roboshop-builds.s3.amazonaws.com/user.zip &>>$LOGFILE

VALIDATE $? "downloading user artifact"

cd /app &>>$LOGFILE

VALIDATE $? "Moving into app directory"

unzip /tmp/user.zip &>>$LOGFILE

VALIDATE $? "unzipping user"

npm install &>>$LOGFILE

VALIDATE $? "Installing dependencies"

rm -fr /etc/systemd/system/user.service
echo "[Unit]" >> /etc/systemd/system/user.service
echo "Description = User Service" >> /etc/systemd/system/user.service
echo "[Service]" >> /etc/systemd/system/user.service
echo "User=roboshop" >> /etc/systemd/system/user.service
echo "Environment=MONGO=true" >> /etc/systemd/system/user.service
echo "Environment=REDIS_HOST=redis.joindevops.online" >> /etc/systemd/system/user.service
echo "Environment=MONGO_URL=\"mongodb://mongodb.joindevops.online:27017/users\"" >> /etc/systemd/system/user.service
echo "ExecStart=/bin/node /app/server.js" >> /etc/systemd/system/user.service

echo "SyslogIdentifier=user" >> /etc/systemd/system/user.service
echo "[Install]" >> /etc/systemd/system/user.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/user.service

VALIDATE $? "copying user.service"

systemctl daemon-reload &>>$LOGFILE

VALIDATE $? "daemon reload"

systemctl enable user &>>$LOGFILE

VALIDATE $? "Enabling user"

systemctl start user &>>$LOGFILE

VALIDATE $? "Starting user"

rm -fr /etc/yum.repos.d/mongo.repo
echo "[mongodb-org-4.2]" >> /etc/yum.repos.d/mongo.repo
echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongo.repo
echo "baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/" >> /etc/yum.repos.d/mongo.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/mongo.repo
echo "enabled=1" >> /etc/yum.repos.d/mongo.repo

VALIDATE $? "Copying mongo repo"

yum install mongodb-org-shell -y &>>$LOGFILE

VALIDATE $? "Installing mongo client"

mongo --host mongodb.joindevops.online </app/schema/user.js &>>$LOGFILE

VALIDATE $? "loading user data into mongodb"





