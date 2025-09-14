pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "himanshu231230/devops-task"
        GITHUB_TOKEN_ID = 'github-token'
        DOCKERHUB_CRED_ID = 'dockerhub-cred'
        DOCKERFILE_PATH = "Dockerfile"  // root Dockerfile
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Prepare Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout Code') {
            steps {
                withCredentials([string(credentialsId: env.GITHUB_TOKEN_ID, variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        set -e
                        git clone --depth 1 --branch main https://$GITHUB_TOKEN@github.com/Himanshu199430/devops-task.git .
                        git remote set-url origin https://github.com/Himanshu199430/devops-task.git || true
                    '''
                }
            }
        }

        stage('Check Dockerfile') {
            steps {
                script {
                    if (!fileExists(env.DOCKERFILE_PATH)) {
                        error "❌ Dockerfile not found in root directory!"
                    } else {
                        echo "✅ Dockerfile found at root."
                    }
                }
            }
        }

        stage('Build & Test in Docker') {
            steps {
                sh """
                    docker build -f ${DOCKERFILE_PATH} -t devops-task-test .
                    docker run --rm devops-task-test npm test
                """
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -f ${DOCKERFILE_PATH} -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {
                    docker.withRegistry('', env.DOCKERHUB_CRED_ID) {
                        def img = docker.image("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                        img.push()
                        img.push("latest")
                    }
                }
            }
        }

        stage('Deploy Locally') {
            steps {
                sh """
                    docker stop devops-task || true
                    docker rm devops-task || true
                    docker run -d --name devops-task -p 3000:3000 ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    sleep 10
                    docker ps --filter "name=devops-task"
                """
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    def status = sh(script: "curl -s -o /tmp/app_resp.txt -w '%{http_code}' http://localhost:3000/", returnStdout: true).trim()
                    echo "HTTP STATUS: ${status}"
                    if (status != '200') {
                        error "❌ Smoke test failed with status ${status}"
                    }
                    sh "head -c 200 /tmp/app_resp.txt || true"
                }
            }
        }
    }

    post {
        success { echo "✅ Pipeline finished successfully." }
        failure { echo "❌ Pipeline failed. Check logs." }
    }
}
