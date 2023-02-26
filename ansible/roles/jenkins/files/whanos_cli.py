#!/usr/bin/python3
import typer

app = typer.Typer()


import os
import subprocess
from sys import stderr
import typer

from format_k8_deployment import format_k8_deployment

DETECTION_FILES = {
    "pom.xml": "java",
    "package.json": "javascript",
    "Makefile": "c",
    "requirements.txt": "python",
    "main.bf": "befunge"
}

def detect_language() -> str:
    files = os.listdir(".")
    detected_list = []
    for f in files:
        if os.path.isfile(f) and DETECTION_FILES.get(f):
            detected_list.append(f)
    if len(detected_list) > 1:
        print("More than 1 language configuration was detected.", file=stderr)
        exit(1)
    elif len(detected_list) < 1:
        print("No configuration was detected.", file=stderr)
        exit(1)
    return DETECTION_FILES.get(detected_list.pop())

def detect_docker() -> bool:
    if os.path.isfile("Dockerfile"):
        return True
    else:
        return False

def detect_kubernetes():
    if os.path.isfile("whanos.yml"):
        return True
    else:
        return False


def get_branch_name() -> str:
    branch = subprocess.check_output(["git", "name-rev",  "--name-only", "HEAD"]).decode('utf-8')
    tmp_list = branch.split("/")
    del tmp_list[0]
    del tmp_list[0]
    # return branch
    return "/".join(tmp_list).strip()

def compute_docker_tag(user: str, repo: str) -> str:
    branch = get_branch_name()
    return f"{user.lower()}.{repo.lower()}.{branch}"

def compute_image_fullname(user: str, repo: str, registry_url: str) -> str:
    language = detect_language()
    if detect_docker():
        image_name = f"whanos-{language}-custom"
    else:
        image_name = f"whanos-{language}-standalone"
    docker_tag = compute_docker_tag(user, repo)
    return f"{registry_url}/{image_name}:{docker_tag}"

@app.command()
def build(user: str, repo: str, registry_url: str):
    language = detect_language()
    if detect_docker():
        dockerfilePath = "./Dockerfile"
    else:
        dockerfilePath = f"/var/lib/jenkins/whanos_images/{language}/Dockerfile.standalone"
    docker_image_full_name = compute_image_fullname(user, repo, registry_url)
    build_command = f"docker build -t {docker_image_full_name} -f {dockerfilePath} ."
    print(f"building with command '{build_command}'", flush=True)
    os.system(build_command)

@app.command()
def push(user: str, repo: str, registry_url: str):
    docker_image_full_name = compute_image_fullname(user, repo, registry_url)
    push_command = f"docker push {docker_image_full_name}"
    print(f"Pushing with command '{push_command}'", flush=True)
    exit_code = os.system(push_command)
    if exit_code != 0:
        exit(1)

@app.command()
def maybe_deploy(user: str, repo: str, registry_url: str):
    if detect_kubernetes():
        print("Kubernetes configuration file detected. Deploying...")
        docker_image_fullname = compute_image_fullname(user, repo, registry_url)
        deployment_name = f"{user.lower().strip()}-{repo.lower().strip()}-{get_branch_name()}"
        kubeconfig_path = "/var/lib/jenkins/.kube/config"
        schema = format_k8_deployment("./whanos.yml", deployment_name, docker_image_fullname)
        deploy_command = f"kubectl --kubeconfig={kubeconfig_path} apply -f - << EOT\n{schema}\nEOT"
        print(f"Deploying with command '{deploy_command}'", flush=True)
        exit_code = os.system(deploy_command)
        exit(exit_code)
    else:
        print("No whanos.yml file detected. Skipping")

if __name__ == "__main__":
    app()