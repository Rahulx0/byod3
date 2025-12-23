pipeline {
    agent any
    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        TF_CLI_CONFIG_FILE = credentials('badf87b5-c81c-440d-87b5-1698b311dcdd')
        SSH_CRED_ID = credentials('privatekey')
    }
    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init --upgrade'
                sh "echo '--- ${env.BRANCH_NAME}.tfvars contents ---'"
                sh "cat ${env.BRANCH_NAME}.tfvars || echo 'No tfvars file for branch ${env.BRANCH_NAME}'"
            }
        }
        stage('Terraform Plan') {
            steps {
                sh "terraform plan -var-file=${env.BRANCH_NAME}.tfvars"
            }
        }
        stage('Validate Apply') {
            when {
                branch 'dev'
            }
            steps {
                input message: 'Manual approval required to apply changes. Proceed?'
                sh "terraform apply -var-file=${env.BRANCH_NAME}.tfvars -auto-approve"
            }
        }
    }
}