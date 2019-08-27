pipeline {

    agent {
      label 'master'
    }

    environment {
        /* Per app configured variables... */
        dockerRegistry = 'docker_registry.aws.hotwire.com'
        gitRepo = 'https://github.com/stutirastogi/java-devops.git'
        dockerRepo = 'java-devops'
    }

    options {
        timestamps()
        ansiColor(colorMapName: 'xterm')
    }

    stages {

        stage('Build') {
            steps {
                lock(resource: env.JOB_NAME + "-Build", inversePrecedence: true) {
                    sh 'mvn -B -U clean install -f pom.xml'
                    junit allowEmptyResults: true, testResults: '**/target/**/TEST*.xml'
                    script {
                        gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        try {
                        sh "sudo docker build --rm -t ${dockerRepo} ."
                        } catch (ex) {
                           error "Error when building docker image"
                        }
                    }
                }
            }
        }

        stage('Analysis') {
            steps {
                lock(resource: env.JOB_NAME + "-Analysis", inversePrecedence: true) {
                    echo 'Starting Sonar Analysis'
                    sh 'mvn cobertura:cobertura -Dcobertura.report.format=xml -f pom.xml'
                    sh 'mvn sonar:sonar -f pom.xml'
                }
            }
        }

        stage('Publish') {
            steps {
                lock(resource: env.JOB_NAME + "-docker-publish", inversePrecedence: true) {
                    sh "sudo docker tag -f ${dockerRepo} ${dockerRegistry}/${dockerRepo}:${gitCommit}"
                    sh "sudo docker push ${dockerRegistry}/${dockerRepo}:${gitCommit}"
                }
            milestone(1)
            }
        }

        stage('Deploy') {
            steps {
                lock(resource: env.JOB_NAME + "-acceptance-deploy", inversePrecedence: true) {
                    script {
                        try {
                        /* Cloudformation template parameters */
                            sh """
                                docker run -it -d -p 8080:8080 --restart=unless-stopped ${dockerRegistry}/${dockerRepo}:${gitCommit}
                            """
                        } catch (ex) {
                            echo "Unable to Start Docker Container"
                        }
            }
            }
            milestone(10)
            }
        }

        stage('Deploy-Sanity') {
        steps {
                    echo 'Starting Smoke Test'
                    sh "mvn clean verify"
                    publishHTML (target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: 'target/cucumber-reports/.',
                    reportFiles: 'feature-overview.html',
                    reportName: "Functional Test Report"
                ]) 
            }
        }
    }
}
    post {
      /* Steps to run after the pipeline is complete */
      success {
          emailext(
              to: 'stutirastogi92@gmail.com',
              subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
              attachmentsPattern: 'reports/fortify_results.pdf',
          body: '<p>Check console output at <a href=${BLUE_OCEAN_URL}>${JOB_NAME} [${BUILD_NUMBER}]</a></p>'
        )
        }
      failure {
          emailext(
              to: 'stutirastogi92@gmail.com',
              subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
          attachmentsPattern: 'reports/fortify_results.pdf',
              body: '<p>Check console output at <a href=${BLUE_OCEAN_URL}>${JOB_NAME} [${BUILD_NUMBER}]</a></p>'
          )
      }
    }

