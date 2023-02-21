folder('Baseimages') {
    displayName('Whanos base images')
    description('Jobs for building base images')
}

folder('Projects') {
    displayName('Projects')
    description('Jobs for building and deploying projects')
}

job('Baseimages/whanos-c') {
    steps {
        shell('echo $USER && docker build -t whanos-c -f /var/lib/jenkins/whanos_images/c/Dockerfile.base .')
    }
}

job('Baseimages/whanos-javascript') {
    steps {
        shell('docker build -t whanos-javascript -f /var/lib/jenkins/whanos_images/javascript/Dockerfile.base .')
    }
}

job('Baseimages/whanos-java') {
    steps {
        shell('docker build -t whanos-java -f /var/lib/jenkins/whanos_images/java/Dockerfile.base .')
    }
}

job('Baseimages/whanos-python') {
    steps {
        shell('docker build -t whanos-python  -f /var/lib/jenkins/whanos_images/python/Dockerfile.base .')
    }
}

job('Baseimages/whanos-befunge') {
    steps {
        shell('docker build -t whanos-javascript -f /var/lib/jenkins/whanos_images/befunge/Dockerfile.base .')
    }
}


job('Baseimages/Build all base images') {
    steps {
        shell('docker build -t whanos-c -f /var/lib/jenkins/whanos_images/c/Dockerfile.base .')
        shell('docker build -t whanos-javascript -f /var/lib/jenkins/whanos_images/javascript/Dockerfile.base .')
        shell('docker build -t whanos-java -f /var/lib/jenkins/whanos_images/java/Dockerfile.base .')
        shell('docker build -t whanos-python -f /var/lib/jenkins/whanos_images/python/Dockerfile.base .')
        shell('docker build -t whanos-befunge -f /var/lib/jenkins/whanos_images/befunge/Dockerfile.base .')
    }
}

job ('link-project') {
    parameters {
        stringParam('GITHUB_OWNER', '', 'GitHub repository owner')
        stringParam('GITHUB_REPO', '', 'GitHub repository repository name')
        stringParam('GITHUB_CREDENTIALS', '', 'Github Token for private repo. Leave empty if public')
        stringParam('BRANCH', 'main', 'Branch to pull. Defaults to "main"')
    }
    steps {
        dsl {
            text ('''
                    folder("Projects/$GITHUB_OWNER") {}
                    folder("Projects/$GITHUB_OWNER/$GITHUB_REPO") {}
                    job("Projects/$GITHUB_OWNER/$GITHUB_REPO/$BRANCH") {
                        scm {
                            git {
                                remote {
                                    github("$GITHUB_OWNER/$GITHUB_REPO")
                                    credentials("$GITHUB_CREDENTIALS")
                                    branch("$BRANCH")
                                }
                            }
                        }
                        triggers {
                            pollSCM {
                                scmpoll_spec('* * * * *')
                            }
                        }
                        steps {
                            shell("build_and_deploy $GITHUB_OWNER $GITHUB_REPO")
                        }
                    }
            '''.stripIndent())
        }
    }
}