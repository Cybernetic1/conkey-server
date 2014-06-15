module.exports = (->

  config =

    development:
      api:
          limit: 10
      app:
        port: 3000
      mongodb:
        connect: 'mongodb://localhost/conkey_dev'
        port: 5000
        secret: 'WeAReDeVELoPeR'

    test:
      api:
          limit: 10
      app:
        port: 3000
      mongodb:
        connect: 'mongodb://localhost/conkey_test'
        port: 5000
        secret: 'TEst'

    production:
      api:
          limit: 10
      app:
        port: 3000
      mongodb:
        connect: 'mongodb://localhost/conkey'
        port: 5000
        secret: 'hEHehAHa'

  switch process.env.NODE_ENV
    when 'production'
      return config.production

    when 'development'
      return config.development

    else
      return config.development


)()