// Jenkinsfile
pipeline {
  agent any
  environment {
    AWS_CREDENTIALS = credentials('aws-creds')  // set in Jenkins
    AWS_REGION = 'us-east-1'
    AWS_ACCOUNT_ID = '<AWS_ACCOUNT_ID>'        // replace in Jenkins job or use env var
    ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/devops-task"
    IMAGE_TAG = "${env.BUILD_ID}-${env.GIT_COMMIT.take(7)}"
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Build & Test') {
      steps {
        dir('app') {
          sh 'npm ci'
          sh 'npm test'
        }
      }
    }
    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
      }
    }
    stage('Push to ECR') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
            aws configure set region ${AWS_REGION}
            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
            aws ecr create-repository --repository-name devops-task || true
            docker push ${ECR_REPO}:${IMAGE_TAG}
          '''
        }
      }
    }
    stage('Deploy to ECS') {
      steps {
        // Use AWS CLI to update ECS service with new image (assumes task definition uses image placeholder)
        sh '''
          sed -e "s|IMAGE_PLACEHOLDER|${ECR_REPO}:${IMAGE_TAG}|g" terraform/ecs-task-template.json > taskdef.json
          TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://taskdef.json --query 'taskDefinition.taskDefinitionArn' --output text)
          echo "Registered taskDef: $TASK_DEF_ARN"
          aws ecs update-service --cluster devops-cluster --service devops-service --force-new-deployment
        '''
      }
    }
  }
  post {
    always {
      echo "Build ${currentBuild.fullDisplayName} finished with status ${currentBuild.currentResult}"
    }
    failure {
      mail to: 'you@example.com', subject: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "See Jenkins"
    }
  }
}
