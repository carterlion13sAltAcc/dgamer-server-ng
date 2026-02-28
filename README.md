![DGamer Logo](dgamer-logo.png)

This project builds a Docker image that replaces the web servers for Nintendo Wifi and DGamer:

- home.disney.go.com (HTTPS/443)

### Docker

Build:
```
docker build --rm --tag dgamer .
```

Run (production):
```
docker run -d --name dgamer \
	-p 80:80 \
	-p 443:443 \
	-v "$(pwd)/configs/apache/:/usr/local/apache/conf/" \
	-v "$(pwd)/sites/:/var/www" \
	dgamer
```

Run (for testing):
```
docker run --name dgamer \
	--rm -it \
	-p 80:80 \
	-p 443:443 \
	-v "$(pwd)/configs/apache/:/usr/local/apache/conf/" \
	-v "$(pwd)/sites/:/var/www" \
	dgamer
```

Start:
```
docker start dgamer
```

Stop:
```
docker stop dgamer
```

