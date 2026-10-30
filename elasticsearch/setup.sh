#!/usr/bin/env bash

set -e

# ============================================================
# Elasticsearch / Kibana configuration
# ============================================================

STACK_VERSION=9.2.2

ELASTIC_PASSWORD=ChangeMe123!

KIBANA_PASSWORD=KibanaSystem123!

ES_PORT=9200

KIBANA_PORT=5601

CLUSTER_NAME=elastic-cluster

NODE_NAME=es01

MEM_LIMIT=2147483648


# ============================================================
# Server IP
# ============================================================
#
# اگر فقط localhost استفاده می‌کنی:
#
# ES_IP=127.0.0.1
#
# اگر کلاینت‌ها با IP سرور وصل می‌شوند:
#
# ES_IP=192.168.10.20
#
# ============================================================

ES_IP=192.168.101.111

KIBANA_IP=192.168.101.111


# ============================================================
# Export variables
# ============================================================

export STACK_VERSION

export ELASTIC_PASSWORD

export KIBANA_PASSWORD

export ES_PORT

export KIBANA_PORT

export CLUSTER_NAME

export NODE_NAME

export MEM_LIMIT

export ES_IP

export KIBANA_IP


# ============================================================
# Check Docker
# ============================================================

if ! command -v docker >/dev/null 2>&1; then

    echo "ERROR: Docker is not installed."

    exit 1

fi


if ! command -v docker-compose >/dev/null 2>&1; then

    echo "ERROR: docker-compose is not installed."

    exit 1

fi


# ============================================================
# vm.max_map_count
# ============================================================

CURRENT_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)

if [ "$CURRENT_MAP_COUNT" -lt 262144 ]; then

    echo "Setting vm.max_map_count=262144"

    sudo sysctl -w vm.max_map_count=262144

    if grep -q "^vm.max_map_count" /etc/sysctl.conf; then

        sudo sed -i \
            's/^vm.max_map_count=.*/vm.max_map_count=262144/' \
            /etc/sysctl.conf

    else

        echo "vm.max_map_count=262144" \
            | sudo tee -a /etc/sysctl.conf >/dev/null

    fi

fi


# ============================================================
# Show configuration
# ============================================================

echo

echo "======================================"

echo " Elasticsearch + Kibana"

echo "======================================"

echo

echo "Version       : ${STACK_VERSION}"

echo "Cluster       : ${CLUSTER_NAME}"

echo "Node          : ${NODE_NAME}"

echo "ES IP         : ${ES_IP}"

echo "Kibana IP     : ${KIBANA_IP}"

echo "ES Port       : ${ES_PORT}"

echo "Kibana Port   : ${KIBANA_PORT}"

echo


# ============================================================
# Start
# ============================================================

echo "Starting Elasticsearch + Kibana..."

echo

docker-compose -f docker-compose.yml up -d


# ============================================================
# Result
# ============================================================

echo

echo "======================================"

echo " Stack started"

echo "======================================"

echo

echo "Elasticsearch:"

echo "  https://localhost:${ES_PORT}"

echo

echo "Kibana:"

echo "  https://localhost:${KIBANA_PORT}"

echo

echo "Elasticsearch username:"

echo "  elastic"

echo

echo "Elasticsearch password:"

echo "  ${ELASTIC_PASSWORD}"

echo
