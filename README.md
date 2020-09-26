# Amber Electric Influx Docker


Docker image which reads from the Amber Electric API and stores the data into
influxdb.

## Config

You need to set the following variables

```bash
# Required
AE_USERNAME=user@example.com
AE_PASSWORD=my-very-secrey-password

# Optional (defaults below)
INFLUXDB_HOSTNAME=influxdb
INFLUXDB_DATABASE=amber_electric
```

## Development

``` bash
# Build
docker build -t amber-electric-influxdb .

# Configure a direnv .envrc with all the variables

# Test
docker run -it \
  -e AE_USERNAME="$AE_USERNAME" \
  -e AE_PASSWORD="$AE_PASSWORD" \
  -e INFLUXDB_HOSTNAME="$INFLUXDB_HOSTNAME" \
  -e INFLUXDB_DATABASE="$INFLUXDB_HOSTNAME" \
  -e ONCE=true \
  amber-electric-influxdb

```

## Release

``` bash
# Update the change log
vi CHANGELOG.md

# Create a release
hub release create --browse v1.0.0

# Import the changelog
:r CHANGELOG.md

# Check Github Actions
```
