pipeline {
    agent any
    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        TF_CLI_CONFIG_FILE = credentials('badf87b5-c81c-440d-87b5-1698b311dcdd')
        SSH_CRED_ID = credentials('privatekey')
        AWS_DEFAULT_REGION = 'us-east-1'
        LANG = 'en_US.UTF-8'
    }
    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
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
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        input message: 'Manual approval required to apply changes. Proceed?'
                    }
                }
                sh "terraform apply -var-file=${env.BRANCH_NAME}.tfvars -auto-approve"
                script {
                    def ip = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                    def id = sh(script: 'terraform output -raw instance_id', returnStdout: true).trim()
                    if (!ip || !id) {
                        error("Failed to capture Terraform outputs . Check Terraform apply logs.")
                    }
                    env.INSTANCE_IP = ip
                    env.INSTANCE_ID = id
                }
                sh """
                echo '[splunk]' > dynamic_inventory.ini
                echo '${env.INSTANCE_IP} ansible_user=ec2-user' >> dynamic_inventory.ini
                """
            }
        }
        // AWS Health Check stage commented out - taking too long
        // stage('AWS Health Check') {
        //     steps {
        //         sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID}"
        //     }
        // }
        stage('Splunk Installation ') {
            steps {
                     ansiblePlaybook playbook: 'playbooks/splunk.yml', inventory: 'inventory/aws_ec2.yml', become: true, credentialsId: 'privatekey', hostKeyChecking: false
            }
        }
        stage('Splunk Testing') {
            steps {
                ansiblePlaybook playbook: 'playbooks/test-splunk.yml', inventory: 'dynamic_inventory.ini', credentialsId: 'privatekey', hostKeyChecking: false
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
            script {
                if (env.BRANCH_NAME == 'dev') {
                    input message: 'Confirm destroy after failure?'
                }
            }
            sh "terraform destroy -var-file=${env.BRANCH_NAME}.tfvars -auto-approve"
        }
        aborted {
            script {
                if (env.BRANCH_NAME == 'dev') {
                    input message: 'Confirm destroy after abort?'
                }
            }
            sh "terraform destroy -var-file=${env.BRANCH_NAME}.tfvars -auto-approve"
        }
    }
}