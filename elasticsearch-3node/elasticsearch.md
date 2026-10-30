```bash
cd /home/tplan/dc/elasticsearch

cat > instances.yml <<'EOF'
instances:

  - name: node-security-1
    dns:
      - node-security-1
      - es01
    ip:
      - 192.168.101.112

  - name: node-security-2
    dns:
      - node-security-2
      - es02
    ip:
      - 192.168.101.111

  - name: node-security-3
    dns:
      - node-security-3
      - es03
    ip:
      - 192.168.101.113

  - name: kibana
    dns:
      - kibana
      - localhost
    ip:
      - 192.168.101.111
EOF
```



```bash
3. ساخت CA با docker run
docker run --rm \
  -u 0 \
  -v /home/tplan/dc/elasticsearch/certs:/certs \
  docker.lib2.tiddev.com/elasticsearch/elasticsearch:9.2.2 \
  bash -c '
    set -e

    mkdir -p /certs

    bin/elasticsearch-certutil ca \
      --silent \
      --pem \
      --out /certs/ca.zip

    unzip -o /certs/ca.zip -d /certs

    rm -f /certs/ca.zip

    chmod -R 755 /certs

    echo
    echo "CA generated:"
    find /certs -type f
  '
  بعد باید داشته باشی:

certs/
└── ca/
    ├── ca.crt
    └── ca.key
    
    
```

```bash
docker run --rm \
  -u 0 \
  -v /home/tplan/dc/elasticsearch/certs:/certs \
  -v /home/tplan/dc/elasticsearch/instances.yml:/instances.yml:ro \
  docker.lib2.tiddev.com/elasticsearch/elasticsearch:9.2.2 \
  bash -c '
    set -e

    bin/elasticsearch-certutil cert \
      --silent \
      --pem \
      --out /certs/certs.zip \
      --in /instances.yml \
      --ca-cert /certs/ca/ca.crt \
      --ca-key /certs/ca/ca.key

    unzip -o /certs/certs.zip -d /certs

    rm -f /certs/certs.zip

    chmod -R 755 /certs

    echo
    echo "Certificates generated:"
    find /certs -type f | sort
  '
  
  باید خروجی چیزی شبیه این باشد:

certs/
├── ca/
│   ├── ca.crt
│   └── ca.key
│
├── node-security-1/
│   ├── node-security-1.crt
│   └── node-security-1.key
│
├── node-security-2/
│   ├── node-security-2.crt
│   └── node-security-2.key
│
├── node-security-3/
│   ├── node-security-3.crt
│   └── node-security-3.key
│
└── kibana/
    ├── kibana.crt
    └── kibana.key
    
    5. چک certificateها
find /home/tplan/dc/elasticsearch/certs -type f | sort

openssl x509 \
  -in /home/tplan/dc/elasticsearch/certs/node-security-1/node-security-1.crt \
  -noout \
  -subject \
  -issuer \
  -ext subjectAltName
  
باید SAN شامل این باشد:

IP Address:192.168.101.112

6. حالا certs را منتقل کنیم

از ماشینی که certificateها را ساختی:

node 1 — .112
scp -r \
  /home/tplan/dc/elasticsearch/certs/ca \
  /home/tplan/dc/elasticsearch/certs/node-security-1 \
  tplan@192.168.101.112:/home/tplan/dc/elasticsearch/certs/
node 2 — .111
scp -r \
  /home/tplan/dc/elasticsearch/certs/ca \
  /home/tplan/dc/elasticsearch/certs/node-security-2 \
  tplan@192.168.101.111:/home/tplan/dc/elasticsearch/certs/
node 3 — .113
scp -r \
  /home/tplan/dc/elasticsearch/certs/ca \
  /home/tplan/dc/elasticsearch/certs/node-security-3 \
  tplan@192.168.101.113:/home/tplan/dc/elasticsearch/certs/
  
  و چون Kibana قرار است روی .111 باشد:

scp -r \
  /home/tplan/dc/elasticsearch/certs/kibana \
  tplan@192.168.101.111:/home/tplan/dc/elasticsearch/certs/
  
  در نهایت

روی 192.168.101.112:

/home/tplan/dc/elasticsearch/certs/
├── ca/
└── node-security-1/

روی 192.168.101.111:

/home/tplan/dc/elasticsearch/certs/
├── ca/
├── node-security-2/
└── kibana/

روی 192.168.101.113:

/home/tplan/dc/elasticsearch/certs/
├── ca/
└── node-security-3/
```





```bas
1. روی هر سه سرور

مسیر:

cd /home/tplan/dc/elasticsearch
.env روی 192.168.101.112
STACK_VERSION=9.2.2

NODE_NAME=node-security-1
NODE_IP=192.168.101.112

CLUSTER_NAME=elastic-cluster

ES_PORT=9200

ELASTIC_PASSWORD=ChangeMe123!
.env روی 192.168.101.111
STACK_VERSION=9.2.2

NODE_NAME=node-security-2
NODE_IP=192.168.101.111

CLUSTER_NAME=elastic-cluster

ES_PORT=9200

ELASTIC_PASSWORD=ChangeMe123!
.env روی 192.168.101.113
STACK_VERSION=9.2.2

NODE_NAME=node-security-3
NODE_IP=192.168.101.113

CLUSTER_NAME=elastic-cluster

ES_PORT=9200

ELASTIC_PASSWORD=ChangeMe123!


```

این فایل را عیناً روی هر سه سرور قرار بده:

version: "3.8"

services:
  elasticsearch:
    image: docker.lib2.tiddev.com/elasticsearch/elasticsearch:${STACK_VERSION}
    container_name: ${NODE_NAME}
    restart: unless-stopped
    network_mode: host
    environment:
      node.name: ${NODE_NAME}
      node.roles: master,data,ingest,transform
      cluster.name: ${CLUSTER_NAME}
      discovery.seed_hosts: >-
        192.168.101.111,
        192.168.101.112,
        192.168.101.113

      cluster.initial_master_nodes: >-
        node-security-1,
        node-security-2,
        node-security-3
    
      network.host: ${NODE_IP}
    
      http.port: 9200
      transport.port: 9300
    
      xpack.security.enabled: "true"
    
      xpack.security.http.ssl.enabled: "true"
      xpack.security.http.ssl.certificate: >-
        /usr/share/elasticsearch/config/certs/${NODE_NAME}/${NODE_NAME}.crt
      xpack.security.http.ssl.key: >-
        /usr/share/elasticsearch/config/certs/${NODE_NAME}/${NODE_NAME}.key
      xpack.security.http.ssl.certificate_authorities: >-
        /usr/share/elasticsearch/config/certs/ca/ca.crt
    
      xpack.security.transport.ssl.enabled: "true"
    
      xpack.security.transport.ssl.verification_mode: certificate
    
      xpack.security.transport.ssl.certificate: >-
        /usr/share/elasticsearch/config/certs/${NODE_NAME}/${NODE_NAME}.crt
    
      xpack.security.transport.ssl.key: >-
        /usr/share/elasticsearch/config/certs/${NODE_NAME}/${NODE_NAME}.key
    
      xpack.security.transport.ssl.certificate_authorities: >-
        /usr/share/elasticsearch/config/certs/ca/ca.crt
    
      ELASTIC_PASSWORD: ${ELASTIC_PASSWORD}
      ES_JAVA_OPTS: "-Xms1g -Xmx1g"
    mem_limit: 2g
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata:/usr/share/elasticsearch/data
      - ./certs:/usr/share/elasticsearch/config/certs:ro
    
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl --fail --silent --show-error --cacert /usr/share/elasticsearch/config/certs/ca/ca.crt -u elastic:$${ELASTIC_PASSWORD} https://localhost:9200/_cluster/health > /dev/null"
        ]
      interval: 10s
      timeout: 10s
      retries: 30
      start_period: 90s


volumes:

  esdata:
    name: elasticsearch_esdata

```dockerfile

```

```bash
5. قبل از بالا آوردن Elasticsearch

خیلی مهم: روی هر سه سرور:

sudo sysctl -w vm.max_map_count=262144

برای دائمی شدن:

echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system

docker compose up -d

curl \
  --cacert /home/tplan/dc/elasticsearch/certs/ca/ca.crt \
  -u 'elastic:ChangeMe123!' \
  https://192.168.101.111:9200
  
```

# Kibana

```bash
STACK_VERSION=9.2.2

NODE_NAME=node-security-2
NODE_IP=192.168.101.111

CLUSTER_NAME=elastic-cluster

ELASTIC_PASSWORD=ChangeMe123!

KIBANA_SYSTEM_PASSWORD=KibanaSystem123!

ENCRYPTED_SAVED_OBJECTS_KEY=9f6c8e2b1a7d4c5e9f6a8b3c2d1e7f4a9b6c3d8e1f5a2c7b9d4e6f8a1c3e5b7
SECURITY_ENCRYPTION_KEY=4e8a2c6f1b9d3e7a5c8f2b6d9e1a4c7f3b8d5e2a6c9f1b4d7e8a3c5f6b9d
REPORTING_ENCRYPTION_KEY=7b3e9f1c5a8d2e6f4b9c1a7d3e5f8b2c6d9a4e1f7b3c5d8e2a6f9b1c4d7e


ولی یک نکته مهم درباره kibana_system

پسورد kibana_system را نباید صرفاً با KIBANA_SYSTEM_PASSWORD در environment Elasticsearch انتظار داشته باشیم که ساخته شود.

باید بعد از بالا آمدن اولین Elasticsearch، پسورد kibana_system را با API تنظیم کنیم:

curl \
  --cacert certs/ca/ca.crt \
  -u "elastic:ChangeMe123!" \
  -X POST \
  "https://192.168.101.111:9200/_security/user/kibana_system/_password" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "KibanaSystem123!"
  }'
  
  certs/
├── ca/
│   └── ca.crt
│
└── kibana/
    ├── kibana.crt
    └── kibana.key
    

```

```dockerfile
services:

  kibana:
    image: docker.lib2.tiddev.com/kibana/kibana:${STACK_VERSION}

    container_name: kibana

    restart: unless-stopped

    network_mode: host

    environment:

      # ======================================================
      # Kibana Server
      # ======================================================

      SERVER_NAME: kibana
      SERVER_HOST: 192.168.101.111
      SERVER_PORT: 5601

      # ======================================================
      # Elasticsearch
      # ======================================================

      ELASTICSEARCH_HOSTS: '["https://192.168.101.111:9200","https://192.168.101.112:9200","https://192.168.101.113:9200"]'

      ELASTICSEARCH_USERNAME: kibana_system
      ELASTICSEARCH_PASSWORD: ${KIBANA_SYSTEM_PASSWORD}

      ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES: /usr/share/kibana/config/certs/ca/ca.crt

      # ======================================================
      # Kibana HTTPS
      # ======================================================

      SERVER_SSL_ENABLED: "true"

      SERVER_SSL_CERTIFICATE: /usr/share/kibana/config/certs/kibana/kibana.crt

      SERVER_SSL_KEY: /usr/share/kibana/config/certs/kibana/kibana.key

      # ======================================================
      # Encryption Keys
      # ======================================================

      XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY: ${ENCRYPTED_SAVED_OBJECTS_KEY}

      XPACK_SECURITY_ENCRYPTIONKEY: ${SECURITY_ENCRYPTION_KEY}

      XPACK_REPORTING_ENCRYPTIONKEY: ${REPORTING_ENCRYPTION_KEY}
      MONITORING_UI_CCS_ENABLED: "false"
    volumes:

      - ./certs:/usr/share/kibana/config/certs:ro

```

