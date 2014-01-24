citysdk file importer
=====================

Command line interface for citysdk file importer.

This will import all the file types that the citysdk gem can import.

Currently this is

- CSV
- JSON
- Zipped Shape files

Use this script in conjunction with another that downloads the data from a
third party source.

## Setup

Copy the config in `template/config.json`.

Enter the necessary details in that file.

## Usage

    $ ./scripts/run.zsh --config path/to/config.json --input example.json


