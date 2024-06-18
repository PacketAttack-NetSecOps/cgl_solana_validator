Example of production mainnet-beta validator.sh file

exec solana-validator \
    --identity /home/sol/validator-keypair.json \
    --vote-account /home/sol/vote-account-keypair.json \
    --log /home/sol/solana-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/solana-accounts \
    --rpc-port 8899 \
    --private-rpc \
    --dynamic-port-range 8000-8020 \
    --minimal-snapshot-download-speed 52428800 \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size 250000000

    
