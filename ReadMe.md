# bunyan-azure [![Build Status](https://secure.travis-ci.org/kmees/node-bunyan-azure.png?branch=master)](https://travis-ci.org/kmees/node-bunyan-azure)
> Bunyan stream for azure table storage

## Getting started

```javascript
var bunyanAzure = require('bunyan-azure');

var logger = bunyan.createLogger({
  name: LOGGER_NAME,
  streams: [{
    level: 'error',
    stream: new bunyanAzure.AzureStream({
      account: 'STORAGE_ACCOUNT_NAME',
      access_key: 'STORAGE_ACCESS_KEY',
      table: 'TABLE_NAME'
    })
  }]
});
