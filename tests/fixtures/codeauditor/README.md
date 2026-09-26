# tinyledger

A small ledger API for one household's shared budget. It keeps account
balances in cents in a local SQLite file and moves money between accounts.
It listens on 127.0.0.1 only and has no login: it is meant for one machine.

## Run

    npm install
    npm start

The database file defaults to `ledger.db`; set `LEDGER_DB` to use another path.

## Test

    npm test

## API

- `GET /accounts`: every account and its balance.
- `POST /transfers` with `{ "from": 1, "to": 2, "cents": 1500 }`: move money between accounts.
- `POST /import` with `{ "entries": [...] }`: load the lines of a bank export. Each line has a
  unique `ref`, so importing the same export twice is harmless.
