# Deps

    - mysql-client
    - jq

## How to use

1. Dump data into rawdump.json using the following command:

    mysql <cse-mysql-connection-info> -N -L < dump_reqdesc.sql > rawdump.json

2. Run the two scripts below:

    ./proc_rawdump.sh
    ./edge2csv.sh

3. To view the visualization locally:

    python -m http.server 8000

This runs a local http server on localhost:8000.

