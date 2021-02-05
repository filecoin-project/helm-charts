# Lotus Genesis

When provided a service address for a lotus-seed chart install, this chart will download the listed miners
metadata and create a genesis.car file and serve it from an http server.

For each miner this chart will produce a `{{ .Release.Name }}-wallet-<minerid>` which will contain the wallet.
You can be provided it as the value for `secrets.wallets.secretName` in the lotus-fullnode chart and the wallet
will be imported to the node.

This chart produces two config maps:

`{{ .Release.Name }}-genesis` contains a single entry called `genesis` which value is an url where the genesis can
be downloaded from.

`{{ .Release.Name }}-metadata` contains an entry for each miner in the format of `pre-seal-<minerid>.json` which value
is the metadata file requires for initializing the miner.

This chart does not provide a way to download the sectors.
