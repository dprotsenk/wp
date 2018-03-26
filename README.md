Go to Services -> EC2 -> Lunch Instance -> Select ami-1b791862 (Ubuntu Server 16.04 LTS) -> t2.micro -> Review and Launch -> Launch -> Launch Instance -> View Instances | jump_host
Go to Services -> IAM -> Users -> Add user (Access type: Programmatic access) -> Next -> Set permissions (Administrator) -> Next -> Create User
Go to Services -> IAM -> Users -> user name -> Security credentials -> Create Access Key -> Copy ACCESS_KEY and SECRET_KEY to start.sh

1) SSH to jump_host
2) git init
3) git pull https://github.com/dprotsenk/testtest.git
4) chmod +x start.sh
5) change variables in start.sh
6) change variables in wordpress-config.sh
7) sudo ./start.sh
8) Open your browser and connect to the new server via port 80
