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
        stage('Provisioning') {
            when {
                branch 'dev'
            }
            steps {
                input message: 'Manual approval required to apply changes. Proceed?'
                sh "terraform apply -var-file=${env.BRANCH_NAME}.tfvars -auto-approve"
                script {
                    env.INSTANCE_IP = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                    env.INSTANCE_ID = sh(script: 'terraform output -raw instance_id', returnStdout: true).trim()
                }
                sh """
                echo '[splunk]' > dynamic_inventory.ini
                echo '${env.INSTANCE_IP}' >> dynamic_inventory.ini
                """
            }
        }
        stage('AWS Health Check') {
            steps {
                sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID}"
            }
        }
        stage('Splunk Installation') {
            steps {
                ansiblePlaybook playbook: 'playbooks/splunk.yml', inventory: 'dynamic_inventory.ini', credentialsId: 'privatekey'
            }
        }
        stage('Splunk Testing') {
            steps {
                ansiblePlaybook playbook: 'playbooks/test-splunk.yml', inventory: 'dynamic_inventory.ini', credentialsId: 'privatekey'
            }
        }
        stage('Destroy') {
            when {
                branch 'dev'
            }
            steps {
                input message: 'Confirm destroy?'
                sh "terraform destroy -var-file=${env.BRANCH_NAME}.tfvars -auto-approve"
            }
        }
    }
    post {
        always {
            sh 'rm -f dynamic_inventory.ini'
        }
        failure {
            sh "terraform destroy -var-file=${env.BRANCH_NAME}.tfvars -auto-approve"
        }
        aborted {
            sh "terraform destroy -var-file=${env.BRANCH_NAME}.tfvars -auto-approve"
        }
    }
}