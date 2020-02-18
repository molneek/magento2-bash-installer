# Magento 2 bash installer.

## Description
This bash script provides flexible feature to install a new Magento 2 instance into system or a docker container.

## Requirements
1. Installed php 7.* version with all modules required to work with selected Magento 2.
2. Installed composer.
3. Installed mysql required to work with selected Magento 2.
4. ~/.composer/auth.json file with magento repo credentials. For docker installation auth.json must be set inside the docker container. In other case you get error.
 
Example of the auth.json file with Magento credentials 
```
{
    "http-basic": {
        "repo.magento.com": {
            "username": "<public-key>",
            "password": "<private-key>"
        }
    }
}
```

## Using
1. Clone this repo
2. Run the bash script: 
```
bash createMagentoProject.sh
```
3. Configure Magento installation by your needs.
4. Enjoy!
