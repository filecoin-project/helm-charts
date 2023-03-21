# Lotus Bundle

If you are writing a lotus application, bundle your application with a lotus node.


## Default behaviors:

Lotus will run as a sidecar to your application. You can access lotus at 127.0.0.1:1234.
There is no authentication, and lotus will not be accessible outside of your pod.

Lotus wallets are managed by kubernetes secrets. Any lotus wallet found in the secret
provided will be imported and available for use by your application.

TODO: Configure lotus to use a wallet service.


## Options:

lite-mode:     Run lotus lite.
lite-backend:  if running in lite-mode, use this service backend. By default, api.chain.love.

See values.yaml for examples.
