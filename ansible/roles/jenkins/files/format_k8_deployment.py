#!/usr/bin/env python

import yaml
import typer

from typing import TypedDict, List
from typeguard import check_type
from sys import stderr

class DeploymentDict(TypedDict):
  resources: any
  ports: List[int]
  replicas: int

class ValidWhanosYaml(TypedDict):
  deployment: DeploymentDict

ingress_template = """
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  namespace: default
spec:
  ingressClassName: nginx
"""

ingress_rule_template = """
http:
  paths:
  - path: /{app_name}
    pathType: Prefix
    backend:
      service:
        name: {app_name}-service
        port:
          number: {port}
"""

service_schema_template = """
apiVersion: v1
kind: Service
metadata:
  name: {app_name}-service
  namespace: default
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: {app_name}
"""

deployment_schema_template = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {app_name}-deployment
  namespace: default
  labels:
    app: {app_name}
spec:
  minReadySeconds: 10
  replicas: 2
  selector:
    matchLabels:
      app: {app_name}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 0
  template:
    metadata:
      labels:
        app: {app_name}
    spec:
      containers:
      - name: {app_name}
        image: {image_name}
        resources:
          limits:
            memory: 64M
        ports:
        - containerPort: 80
      imagePullSecrets:
      - name: regcred
      restartPolicy: Always
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - {app_name}
            topologyKey: "kubernetes.io/hostname"
"""


def template_service(whanos_yaml_obj: any, app_name: str) -> any:
    service_str = service_schema_template.format(app_name=app_name)
    service_obj = yaml.safe_load(service_str)
    service_obj['spec']['ports'] = []
    for value in whanos_yaml_obj['deployment']['ports']:
            service_obj['spec']['ports'].append({'port': value, 'targetPort': value})
    return service_obj

def template_deployment(whanos_yaml_obj: any, app_name: str, image_name: str) -> any:
    deployment_str = deployment_schema_template.format(app_name=app_name, image_name=image_name)
    deployment_obj = yaml.safe_load(deployment_str)
    deployment_obj['spec']['replicas'] = whanos_yaml_obj['deployment']['replicas']
    deployment_obj['spec']['template']['spec']['containers'][0]['resources'] = whanos_yaml_obj['deployment']['resources']
    deployment_obj['spec']['template']['spec']['containers'][0]['ports'] = []
    for value in whanos_yaml_obj['deployment']['ports']:
        deployment_obj['spec']['template']['spec']['containers'][0]['ports'].append({'containerPort': value})
    return deployment_obj

def template_ingress(whanos_yaml_obj: any, app_name: str) -> any:
    ingress_template_obj = yaml.safe_load(ingress_template)
    ingress_template_obj['spec']['rules'] = []
    for value in whanos_yaml_obj['deployment']['ports']:
        ingress_rule_str = ingress_rule_template.format(port=value, app_name=app_name)
        ingress_rule_obj = yaml.safe_load(ingress_rule_str)
        ingress_template_obj['spec']['rules'].append(ingress_rule_obj)
    return ingress_template_obj

def format_k8_deployment(yaml_config: str, deployment_name: str, image: str) -> str:
    with open(yaml_config) as stream:
        whanos = yaml.safe_load(stream)
        try:
            check_type("whanos", whanos, ValidWhanosYaml)
        except:
            print("Invalid whanos.yml file", file=stderr)
            exit(1)
        deployment_file = yaml.safe_dump(template_deployment(whanos, deployment_name, image))
        service_file = yaml.safe_dump(template_service(whanos, deployment_name))
        ingress_file = yaml.safe_dump(template_ingress(whanos, deployment_name))
        return "---\n".join(["", service_file, deployment_file, ingress_file, ""])

def main(yaml_config: str, deployment_name: str, image: str):
    print(format_k8_deployment(yaml_config, deployment_name, image))

if __name__ == "__main__":
    typer.run(main)
