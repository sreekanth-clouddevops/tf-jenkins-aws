// Jenkinsfile - Terraform pipeline supporting plan / apply / destroy
pipeline {
  agent any

  environment {
    // Point to TF files (root by default). Use "${env.WORKSPACE}/infra" if files are in subfolder.
    TF_DIR = "${env.WORKSPACE}"
    USE_DOCKER = "true"                  // "true" to run Terraform in container, "false" to use system terraform
    TERRAFORM_IMAGE = "hashicorp/terraform:light"
    AWS_CREDS_ID = "aws-creds"           // Jenkins credential id (username = AWS_ACCESS_KEY_ID, password = AWS_SECRET_ACCESS_KEY)
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan','apply','destroy'], description: 'Choose pipeline action')
    booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'If true skip interactive confirmation (not recommended for demos)')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Init & Plan') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.AWS_CREDS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          script {
            // Init
            if (env.USE_DOCKER.toLowerCase() == 'true') {
              sh """
                docker run --rm -v ${env.WORKSPACE}:${env.WORKSPACE} -w ${env.TF_DIR} \\
                  -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \\
                  ${env.TERRAFORM_IMAGE} init -input=false
              """
            } else {
              sh """
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                cd ${env.TF_DIR}
                terraform init -input=false
              """
            }

            // Plan (normal or destroy)
            if (params.ACTION == 'destroy') {
              if (env.USE_DOCKER.toLowerCase() == 'true') {
                sh """
                  docker run --rm -v ${env.WORKSPACE}:${env.WORKSPACE} -w ${env.TF_DIR} \\
                    -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \\
                    ${env.TERRAFORM_IMAGE} plan -destroy -out=tfplan -input=false
                  docker run --rm -v ${env.WORKSPACE}:${env.WORKSPACE} -w ${env.TF_DIR} ${env.TERRAFORM_IMAGE} show -no-color tfplan > tfplan.txt || true
                """
              } else {
                sh """
                  export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                  export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                  cd ${env.TF_DIR}
                  terraform plan -destroy -out=tfplan -input=false
                  terraform show -no-color tfplan > tfplan.txt || true
                """
              }
            } else {
              // plan or apply (normal plan)
              if (env.USE_DOCKER.toLowerCase() == 'true') {
                sh """
                  docker run --rm -v ${env.WORKSPACE}:${env.WORKSPACE} -w ${env.TF_DIR} \\
                    -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \\
                    ${env.TERRAFORM_IMAGE} plan -out=tfplan -input=false
                  docker run --rm -v ${env.WORKSPACE}:${env.WORKSPACE} -w ${env.TF_DIR} ${env.TERRAFORM_IMAGE} show -no-color tfplan > tfplan.txt || true
                """
              } else {
                sh """
                  export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                  export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                  cd ${env.TF_DIR}
                  terraform plan -out=tfplan -input=false
                  terraform show -no-color tfplan > tfplan.txt || true
                """
              }
            }

            // Make sure tfplan.txt is in the workspace root so archiveArtifacts always finds it
            sh "cp -f ${env.TF_DIR}/tfplan.txt ${env.WORKSPACE}/tfplan.txt || true"

            // Archive and print a short preview
            archiveArtifacts artifacts: 'tfplan.txt', allowEmptyArchive: true
            echo "---- Plan preview (first 200 lines) ----"
            sh "sed -n '1,200p' tfplan.txt || true"
          }
        }
      }
    }

    stage('Confirm') {
      steps {
        script {
          if (params.ACTION == 'plan') {
            echo "Plan-only selected. No apply will be executed. Review archived tfplan.txt."
          } else if (!params.AUTO_APPROVE.toBoolean()) {
            def pretty = params.ACTION == 'destroy' ? "DESTROY (will DELETE resources)" : "APPLY (will CREATE/UPDATE resources)"
            input message: "Ready to ${pretty}? Click Proceed to continue", ok: "Proceed"
          } else {
            echo "AUTO_APPROVE enabled — proceeding without human confirmation"
          }
        }
      }
    }

    stage('Execute') {
      when { expression { params.ACTION != 'plan' } } // skip for plan-only
      steps {
        withCredentials([usernamePassword(credentialsId: env.AWS_CREDS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          script {
            if (env.USE_DOCKER.toLowerCase() == 'true') {
              sh """
                docker run --rm -v ${env.WORKSPACE}:${env.WORKSPACE} -w ${env.TF_DIR} \\
                  -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \\
                  ${env.TERRAFORM_IMAGE} apply -input=false -auto-approve tfplan
              """
            } else {
              sh """
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                cd ${env.TF_DIR}
                terraform apply -input=false -auto-approve tfplan
              """
            }

            // show outputs only for apply
            if (params.ACTION == 'apply') {
              if (env.USE_DOCKER.toLowerCase() == 'true') {
                sh "docker run --rm -v ${env.WORKSPACE}:${env.WORKSPACE} -w ${env.TF_DIR} ${env.TERRAFORM_IMAGE} output -no-color || true"
              } else {
                sh "cd ${env.TF_DIR} && terraform output -no-color || true"
              }
            }
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'tfplan.txt', allowEmptyArchive: true
      sh "rm -f ${env.TF_DIR}/tfplan || true"
    }
    success { echo "Pipeline finished for ACTION=${params.ACTION}" }
    failure { echo "Pipeline failed - check console logs" }
  }
}
