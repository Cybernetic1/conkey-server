To test:
    mocha -R spec --compilers coffee:coffee-script
To run server on development mode:
    coffee index.coffee
To run server on production mode with forever:
    sudo npm install -g forever
    NODE_ENV=production sudo forever start -c coffee index.coffee
