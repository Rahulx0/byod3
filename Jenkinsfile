pipeline {
    agent any
    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        SSH_CRED_ID = credentials('SSH_CRED_ID')
    }
    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
                sh 'echo "--- ${env.BRANCH_NAME}.tfvars contents ---"'
                sh 'cat ${env.BRANCH_NAME}.tfvars || echo "No tfvars file for branch ${env.BRANCH_NAME}"'
            }
        }
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -var-file=${env.BRANCH_NAME}.tfvars'
            }
        }
        stage('Validate Apply') {
            when {
                branch 'dev'
            }
            steps {
                input message: 'Manual approval required to apply changes. Proceed?'
                sh 'terraform apply -var-file=${env.BRANCH_NAME}.tfvars -auto-approve'
            }
        }
    }
}