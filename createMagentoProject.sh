#!/bin/bash
# Requirements:
# 1. Installed php 7.* version with all modules required to work with selected Magento 2.
# 2. Installed composer.
# 3. Installed mysql required to work with selected Magento 2.
# 4. ~/.composer/auth.json file with magento repo credentials. For docker installation auth.json must be set inside the docker container.
# 
# Example of the auth.json file with Magento credentials 
# {
#     "http-basic": {
#         "repo.magento.com": {
#             "username": "<public-key>",
#             "password": "<private-key>"
#         }
#     }
# }

echo "Do you want to install Magento into a docker container? [no]";
read -e -p "Please enter [yes/no]: " docker;
docker="${docker:=no}";
wait$!

if [[ $docker == 'yes' ]];
then
    while [[ $dockerName == '' ]]
    do
        echo "Please enter php docker container name.";
        read -e -p "Docker container name: " dockerName;
    done;
    wait$!
fi;

if [[ $docker == 'yes' ]];
then
    docker exec -it $dockerName bash -c "nano ~/.composer/auth.json";
    docker exec -it $dockerName bash -c "exit";
else
    nano ~/.composer/auth.json;
fi

echo "Please select a Magento type CE/EE [CE]";
read -e -p "Type [CE or EE]: " selectedType;
wait$!

echo "Please enter a Magento version e.g 2.*.* [newest]";
read -e -p "Version: " version;
wait$!

while [[ $projectRoot == '' ]]
do
    echo "Please enter a project root folder name or path to a project root";
    read -e -p "Project root: " projectRoot;
done
wait$!

if [[ -d $projectRoot ]]; 
then
    if [[ "$(ls -A $projectRoot)" ]];
    then
        echo "Selected root directory is not empty. Do you want to remove it?";
        while [[ $removeDir == '' ]]
        do
            read -e -p "Please enter 'yes' or 'no': " removeDir;
        done
        if [[ $removeDir == 'yes' ]];
        then
            rm -rf $projectRoot;
        fi
        if [[ $removeDir == 'no' ]];
        then
            echo "Please remove the project root directory $projectRoot or select another one and run script one more time.";
            exit 1;
        fi
    fi
fi
wait$!

if [[ ${selectedType,,} == "ce" || ${selectedType,,} == '' ]]; 
then
    magentoType="project-community-edition";
fi
wait$!

if [[ ${selectedType,,} == "ee" ]]; 
then
    magentoType="project-enterprise-edition";
fi
wait$!

echo "Please enter a Magento admin user's firstname [Developer]";
read -e -p "Firstname: " adminFirstname;
adminFirstname="${adminFirstname:=Developer}";
wait$!

echo "Please enter a Magento admin user's lastname [Admin]";
read -e -p "Lastname: " adminLastname;
adminLastname="${adminLastname:=Admin}";
wait$!

echo "Please enter a Magento admin user's email [developer@admin.com]";
read -e -p "Email: " email;
email="${email:=admin@admin.com}";
wait$!

echo "Please enter a Magento admin user's username [developer]";
read -e -p "Username: " adminUser;
adminUser="${adminUser:=developer}";
wait$!

echo "Please enter a Magento admin user's password [password1]";
read -sp "Password: " adminPassword;
adminPassword="${adminPassword:=password1}";
echo "";
wait$!

while [[ $url == '' ]]
do
    echo "Please enter Magento's base URL (ex. example.com)";
    read -p "Base URL: " url;
done;
wait$!

echo "Please enter Magento's use secure value [0]";
read -e -p "Use Secure URLs [1 or 0]: " useSecure;
useSecure="${useSecure:=0}";
wait$!

echo "Please enter a Magento backend frontname [admin]";
read -e -p "Backend Frontname: " backendFrontname;
backendFrontname="${backendFrontname:=admin}";
wait$!

if [[ $docker == 'no' ]];
then
    echo "Please enter Magento's DB host [0.0.0.0]";
    read -e -p "DB Host: " dbHost;
    dbHost="${dbHost:=0.0.0.0}";
    wait$!
else
    echo "Please enter Magento's DB host [mysql]";
    read -e -p "DB Host: " dbHost;
    dbHost="${dbHost:=mysql}";
    wait$!
fi

while [[ $dbName == '' ]]
do
    echo "Please enter Magento's DB name";
    read -e -p "DB Name: " dbName;
done;
wait$!

echo "Please enter Magento's DB user [admin]";
read -e -p "DB User: " dbUser;
dbUser="${dbUser:=admin}";
wait$!

echo "Please enter Magento's DB password [admin]";
read -sp "DB Password: " dbPassword;
dbPassword="${dbPassword:=admin}";
wait$!

echo "Do you want to create new DB? [no]. NOTE: If DB exists this won't be created but Magento tries to clear DB before install!!!";
read -e -p "Please enter [yes/no]: " createDb;
wait$!

if [[ $createDb == 'yes' ]];
then
    if [[ $docker == 'yes' ]];
    then
        docker exec -i $dockerName bash -c "mysql -h$dbHost -u$dbUser -p$dbPassword -e 'create database if not exists $dbName'";
    else
        mysql -h$dbHost -u$dbUser -p$dbPassword -e "create database if not exists $dbName";
    fi
fi
wait$!

echo "Please enter Magento's default language [en_US]";
read -e -p "Language: " language;
language="${language:=en_US}";
wait$!

echo "Please enter Magento's default currency [USD]";
read -e -p "Currency: " currency;
currency="${currency:=USD}";
wait$!

echo "Please enter Magento's default timezone [Europe/Kiev]";
read -e -p "Currency: " timezone;
timezone="${timezone:=Europe/Kiev}";
wait$!

echo "Do you need to deploy sample data? [no]";
read -e -p "Please enter [yes/no]: " sampleData;
sampleData="${sampleData:='no'}";
wait$!

if [[ $useSecure == 1 ]];
then
    baseUrl="https://$url/"
else
    baseUrl="http://$url/"
fi
wait$!

#Select place to install Magento.
if [[ $docker == 'yes' ]];
then
    docker exec -i $dockerName bash -c "composer create-project --repository-url=https://repo.magento.com/ magento/$magentoType=$version $projectRoot";
    docker exec -i $dockerName bash -c "cd $projectRoot && composer install";
    wait$!

    #install project
    docker exec -i $dockerName bash -c "
        cd $projectRoot && bin/magento setup:install  \
        --admin-firstname="$adminFirstname" \
        --admin-lastname="$adminLastname" \
        --admin-email="$email" \
        --admin-user="$adminUser" \
        --admin-password="$adminPassword" \
        --base-url="$baseUrl" \
        --backend-frontname="$backendFrontname" \
        --db-host="$dbHost" \
        --db-name="$dbName" \
        --db-user="$dbUser" \
        --db-password="$dbPassword" \
        --language="$language" \
        --currency="$currency" \
        --timezone="$timezone" \
        --use-rewrites=1 \
        --use-secure="$useSecure" \
        --cleanup-database
    ";

    #prepare project to work
    docker exec -i $dockerName bash -c "cd $projectRoot && bin/magento deploy:mode:set developer";
    docker exec -i $dockerName bash -c "cd $projectRoot && bin/magento setup:upgrade && bin/magento cache:flush";
    wait$!

    #deploy sample data
    if [[ $sampleData == 'yes' ]];
    then
        docker exec -i $dockerName bash -c "cp ~/.composer/auth.json $projectRoot/auth.json"
        docker exec -i $dockerName bash -c "cd $projectRoot && bin/magento sampledata:deploy && bin/magento setup:upgrade && bin/magento cache:flush";
    fi
    wait$!
else
    composer create-project --repository-url=https://repo.magento.com/ magento/$magentoType=$version $projectRoot;
    cd $projectRoot;
    composer install;
    wait$!

    #install project
    bin/magento setup:install  \
    --admin-firstname="$adminFirstname" \
    --admin-lastname="$adminLastname" \
    --admin-email="$email" \
    --admin-user="$adminUser" \
    --admin-password="$adminPassword" \
    --base-url="$baseUrl" \
    --backend-frontname="$backendFrontname" \
    --db-host="$dbHost" \
    --db-name="$dbName" \
    --db-user="$dbUser" \
    --db-password="$dbPassword" \
    --language="$language" \
    --currency="$currency" \
    --timezone="$timezone" \
    --use-rewrites=1 \
    --use-secure="$useSecure" \
    --cleanup-database

    #prepare project to work
    bin/magento deploy:mode:set developer;
    bin/magento setup:upgrade && bin/magento cache:flush;
    wait$!

    #deploy sample data
    if [[ $sampleData == 'yes' ]];
    then
        cp ~/.composer/auth.json $projectRoot/auth.json
        bin/magento sampledata:deploy && bin/magento setup:upgrade && bin/magento cache:flush
    fi
    wait$!
fi
wait$!

#add host
if !(cat /etc/hosts | grep -q "$url")
then
    echo "127.0.0.1 $url"  >> /etc/hosts
fi
wait$!

echo '-------------------------------------------------';

echo "Magento successfully installed to the projectRoot: $projectRoot";
echo "Magento is available by the url: $baseUrl";
echo "Magento's backoffice is available by the url: $baseUrl$backendFrontname";
echo "Magento's backoffice credentials: $adminUser/$adminPassword";

echo '-------------------------------------------------';
