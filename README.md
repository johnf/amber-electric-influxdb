# Amber Electric Influx Docker


Docker image which reads from the Amber Electric API and stores the data into
influxdb.

## Config

You need to ste the following variables

```bash
# Required
AE_USERNAME=user@example.com
AE_PASSWORD=my-very-secrey-password

# Optional (defaults below)
INFLUXDB_HOSTNAME=influxdb
INFLUXDB_DATABASE=amber_electric
```

## Publishing new Image

``` bash
docker build -t amber-electric-influxdb .
docker tag amber-electric-influxdb johnf/amber-electric-influxdb
docker push johnf/amber-electric-influxdb
```
