#!/usr/bin/env bash

set -e

STACK_VERSION=9.2.2

ELASTIC_PASSWORD=ChangeMe123!

ES_PORT=9200
KIBANA_PORT=5601

KIBANA_PASSWORD=KibanaSystem123!

CLUSTER_NAME=elastic-cluster
NODE_NAME=es01

MEM_LIMIT=2147483648

export STACK_VERSION
export ELASTIC_PASSWORD
export ES_PORT
export KIBANA_PORT
export KIBANA_PASSWORD
export CLUSTER_NAME
export NODE_NAME
export MEM_LIMIT

echo "Starting Elasticsearch + Kibana..."

docker compose up -d

echo
echo "Waiting for services..."

docker compose ps

echo
echo "======================================"
echo " Elasticsearch"
echo "======================================"
echo "http://localhost:${ES_PORT}"

echo
echo "======================================"
echo " Kibana"
echo "======================================"
echo "http://localhost:${KIBANA_PORT}"

echo
echo "======================================"
echo " Credentials"
echo "======================================"
echo "elastic:"
echo "  ${ELASTIC_PASSWORD}"
echo
echo "kibana_system:"
echo "  ${KIBANA_PASSWORD}"
